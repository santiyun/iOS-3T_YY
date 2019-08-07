//
//  EffectTool.m
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/7.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import "EffectTool.h"
#import <OpenGLES/ES3/glext.h>
#include <vector>

@interface EffectTool ()
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int inputImageDataSize;
@property (nonatomic) int outputImageDataSize;
@property (nonatomic, copy) NSString *dataPath;

@end

@implementation EffectTool {
    CVOpenGLESTextureCacheRef _textureCache;
    uint8_t* _inputImageData;
    uint8_t* _outputImageData;
    
    GLuint _quadVbo;
    GLuint _quadIbo;
    GLuint _copyProgram;
    GLuint _inTex;
    GLuint _outTex;
    GLuint _fbo;
//    OFHandle _context;
    BeautyTool* _beautyUtil;
    FilterTool* _filterUtil;
    StickerTool* _stickerUtil;
}

- (void)dealloc
{
    if (_context != OF_INVALID_HANDLE)
    {
        OF_DestroyContext(_context);
    }
    
    if (_inTex != 0)
    {
        glDeleteTextures(1, &_inTex);
    }
    if (_outTex != 0)
    {
        glDeleteTextures(1, &_outTex);
    }
    
    glDeleteProgram(_copyProgram);
    glDeleteBuffers(1, &_quadVbo);
    glDeleteBuffers(1, &_quadIbo);
    glDeleteFramebuffers(1, &_fbo);
    
    if (_inputImageData)
    {
        free(_inputImageData);
    }
    CFRelease(_textureCache);
}

- (instancetype)initWithContext:(EAGLContext *)context width:(int)width height:(int)height path:(NSString *)path {
    if (self = [super init]) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (CVEAGLContext)context, NULL, &_textureCache);
        if (err != noErr) {
            NSLog(@"3TLog------%d",err);
        }
        _inputImageDataSize = 0;
        _inputImageData = nil;
        _outputImageDataSize = 0;
        _outputImageData = nil;
        
        _width = width;
        _height = height;
        _inTex = 0;
        _outTex = 0;
        _dataPath = path;
        
        glGenFramebuffers(1, &_fbo);
        
        [self initQuad];
        [self initCopyProgram];
        
        //猜测...内部限制路径必须有face路径, SB用法, 只能用引用方式使用venus_models
        NSString *modelPath = [path stringByAppendingString:@"/venus_models"];
//        std::string  = _dataPath + "/venus_models";
        OF_Result ret = OF_CreateContext(&_context, modelPath.UTF8String);
        if (ret != OF_Result_Success)
        {
            _context = OF_INVALID_HANDLE;
        }
    }
    return self;
}

-(void)setTool:(FilterTool *)filterTool beautyTool:(BeautyTool *)beautyTool stickerTool:(StickerTool *)stickerTool {
    _filterUtil = filterTool;
    _beautyUtil = beautyTool;
    _stickerUtil = stickerTool;
}

- (void)applyFrame:(OF_Texture *)inTex outTex:(OF_Texture *)outTex frameData:(OF_FrameData *)frameData
{
    if (_context == OF_INVALID_HANDLE) { return; }
    std::vector<OFHandle> effects;
    std::vector<OF_Result> results;
    
    if (_beautyUtil != nullptr &&
        [_beautyUtil getEffect] != OF_INVALID_HANDLE &&
        _beautyUtil.enable)
    {
        effects.push_back([_beautyUtil getEffect]);
    }
    if (_filterUtil != nullptr &&
        [_filterUtil getEffect] != OF_INVALID_HANDLE)
    {
        effects.push_back(_filterUtil.getEffect);
    }
    if (_stickerUtil != nullptr &&
        _stickerUtil.getEffect  != OF_INVALID_HANDLE)
    {
        effects.push_back(_stickerUtil.getEffect);
    }
    
    if (effects.size() > 0)
    {
        results.resize(effects.size());
        OF_ApplyFrameBatch(_context, &effects[0], (OFUInt32) effects.size(), inTex, 1, outTex, 1, frameData, &results[0], (OFUInt32) results.size());
    } else {
        // copy
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outTex->textureID, 0);
        glViewport(0, 0, outTex->width, outTex->height);
        
        static const float MatFlipY[] = {
            1, 0, 0, 0,
            0, -1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        
        [self drawQuad:inTex->textureID transform:MatFlipY];
    }
}

- (CVPixelBufferRef)render:(CVPixelBufferRef)inPixelBuffer
{
    CVPixelBufferRef outPixelBuffer = nullptr;
    if(!inPixelBuffer)
    {
        return outPixelBuffer;
    }
    
    CVPixelBufferLockBaseAddress(inPixelBuffer, 0);
    CVOpenGLESTextureRef inputTexture = nullptr;
    int width  = (int) CVPixelBufferGetWidth(inPixelBuffer);
    int height = (int) CVPixelBufferGetHeight(inPixelBuffer);
    uint8_t* baseAddress = (uint8_t*) CVPixelBufferGetBaseAddress(inPixelBuffer);
    int cameraImageDataPitch = (int) CVPixelBufferGetBytesPerRow(inPixelBuffer);
    int dataSize = (int) CVPixelBufferGetDataSize(inPixelBuffer);
    if (nullptr == _inputImageData || _inputImageDataSize != dataSize)
    {
        if (_inputImageData)
        {
            free(_inputImageData);
            _inputImageData = nullptr;
        }
        _inputImageDataSize = dataSize;
        _inputImageData = (uint8_t*)malloc(_inputImageDataSize);
    }
    memcpy(_inputImageData, baseAddress, dataSize);
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, inPixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &inputTexture);
    assert(kCVReturnSuccess == err);
    GLenum target = CVOpenGLESTextureGetTarget(inputTexture);
    assert(GL_TEXTURE_2D == target);
    _inTex = CVOpenGLESTextureGetName(inputTexture);
    glBindTexture(GL_TEXTURE_2D, _inTex);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    CVPixelBufferUnlockBaseAddress(inPixelBuffer, 0);
    
    OF_FrameData frameData;
    memset(&frameData, 0, sizeof(frameData));
    frameData.width     = width;
    frameData.height    = height;
    frameData.format    = OF_PixelFormat_BGR32;
    frameData.imageData = _inputImageData;
    frameData.widthStep = cameraImageDataPitch;
    frameData.timestamp = 0;
    frameData.isUseCustomHarsLib = OF_FALSE;
    
    if (inputTexture)
    {
        if (0 == _outTex)
        {
            glGenTextures(1, &_outTex);
            glBindTexture(GL_TEXTURE_2D, _outTex);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, OF_NULL);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        assert(glGetError() == 0);
        
        GLint oldFbo;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &oldFbo);
        
        // apply frame
        OF_Texture inTex;
        inTex.target    = GL_TEXTURE_2D;
        inTex.width     = width;
        inTex.height    = height;
        inTex.format    = GL_RGBA;
        inTex.textureID = _inTex;
        
        OF_Texture outTex;
        outTex.target    = GL_TEXTURE_2D;
        outTex.width     = width;
        outTex.height    = height;
        outTex.format    = GL_RGBA;
        outTex.textureID = _outTex;
        
        // clear out first
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outTex, 0);
        glViewport(0, 0, width, height);
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        
        [self applyFrame:&inTex outTex:&outTex frameData:&frameData];
        
        assert(glGetError() == 0);
        
        // read pixels to data
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outTex, 0);
        if (nullptr == _outputImageData || _outputImageDataSize < width * height * 4)
        {
            _outputImageData = (uint8_t*)realloc(_outputImageData, width * height * 4);
        }
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, _outputImageData);
        assert(glGetError() == 0);
        
        outPixelBuffer = [self data2PiexlBuffer:_outputImageData width:width height:height];
        CFRelease(inputTexture);
        
        //
        // output to view
        //
        glBindFramebuffer(GL_FRAMEBUFFER, oldFbo);
        glViewport(0, 0, _width, _height);
        glClear(GL_COLOR_BUFFER_BIT);
        int x, y, w, h;
        // clip
        if (_height / (float) _width > height / (float) width)
        {
            h = _height;
            w = h * width / height;
        }
        else
        {
            w = _width;
            h = w * height / width;
        }

        x = 0.5 * (_width - w);
        y = 0.5 * (_height - h);
        glViewport(x, y, w, h);
        
        static const float MatIdentity[] = {
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        
        [self drawQuad:_outTex transform:MatIdentity];
        assert(glGetError() == 0);
    }
    return outPixelBuffer;
}

#pragma mark - private
- (void)drawQuad:(GLuint)tex transform:(const float *)transform
{
    int loc;
    glUseProgram(_copyProgram);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tex);
    loc = glGetUniformLocation(_copyProgram, "uTexture");
    glUniform1i(loc, 0);
    
    loc = glGetUniformLocation(_copyProgram, "uMat");
    glUniformMatrix4fv(loc, 1, false, transform);
    
    glBindBuffer(GL_ARRAY_BUFFER, _quadVbo);
    
    loc = glGetAttribLocation(_copyProgram, "aPos");
    glEnableVertexAttribArray(loc);
    glVertexAttribPointer(loc, 2, GL_FLOAT, false, 4 * 4, 0);
    loc = glGetAttribLocation(_copyProgram, "aUV");
    glEnableVertexAttribArray(loc);
    glVertexAttribPointer(loc, 2, GL_FLOAT, false, 4 * 4, (const void*) (4 * 2));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIbo);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

- (void)initQuad
{
    float vertices[] = {
        -1, 1, 0, 0,
        -1, -1, 0, 1,
        1, -1, 1, 1,
        1, 1, 1, 0
    };
    glGenBuffers(1, &_quadVbo);
    glBindBuffer(GL_ARRAY_BUFFER, _quadVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    unsigned short indices[] = {
        0, 1, 2, 0, 2, 3
    };
    glGenBuffers(1, &_quadIbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _quadIbo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

- (void)initCopyProgram
{
    const char* v = R"(
    uniform mat4 uMat;
    attribute vec2 aPos;
    attribute vec2 aUV;
    varying vec2 vUV;
    void main()
    {
        gl_Position = uMat * vec4(aPos, 0.0, 1.0);
        vUV = aUV;
    }
    )";
    const char* f = R"(
    precision mediump float;
    uniform sampler2D uTexture;
    varying vec2 vUV;
    void main()
    {
        gl_FragColor = texture2D(uTexture, vUV);
    }
    )";
    
    GLuint vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, &v, OF_NULL);
    glCompileShader(vs);
    
    GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, &f, OF_NULL);
    glCompileShader(fs);
    
    _copyProgram = glCreateProgram();
    glAttachShader(_copyProgram, vs);
    glAttachShader(_copyProgram, fs);
    glLinkProgram(_copyProgram);
    
    glDeleteShader(vs);
    glDeleteShader(fs);
}

- (CVPixelBufferRef)data2PiexlBuffer:(uint8_t *)data width:(int)width height:(int)height
{
    CVPixelBufferRef outPixebuffer = nullptr;
    
    //
    // data to UIImage
    //
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = static_cast<size_t>(4 * width);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    // set the alpha mode RGBA
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    
    ////
    // This method is much simple and without coordinate flip
    // You can use this method either
    // but the UIGraphicsBeginImageContext() is much more modern.
    ////
    
    CGContextRef cgBitmapCtx = CGBitmapContextCreate(data,
                                                     static_cast<size_t>(width),
                                                     static_cast<size_t>(height),
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpaceRef,
                                                     bitmapInfo);
    CGImageRef cgImg = CGBitmapContextCreateImage(cgBitmapCtx);
    
    UIImage *uiImage = [UIImage imageWithCGImage:cgImg];
    CGContextRelease(cgBitmapCtx);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(cgImg);
    
    //
    // UIImage to CVPixelBufferRef
    //
    CGSize frameSize = CGSizeMake(CGImageGetWidth(uiImage.CGImage),CGImageGetHeight(uiImage.CGImage));
    NSDictionary *options =
    [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,[NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVReturn status =
    CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height,kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &outPixebuffer);
    assert(status == kCVReturnSuccess && outPixebuffer != NULL);
    CVPixelBufferLockBaseAddress(outPixebuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(outPixebuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context_img = CGBitmapContextCreate(pxdata, frameSize.width, frameSize.height,8, CVPixelBufferGetBytesPerRow(outPixebuffer),rgbColorSpace,(CGBitmapInfo)kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context_img, CGRectMake(0, 0, CGImageGetWidth(uiImage.CGImage),CGImageGetHeight(uiImage.CGImage)), uiImage.CGImage);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context_img);
    CVPixelBufferUnlockBaseAddress(outPixebuffer, 0);
    
    return outPixebuffer;
}

@end
