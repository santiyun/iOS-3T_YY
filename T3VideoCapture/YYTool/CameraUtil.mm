#import "CameraUtil.h"
#import <OpenGLES/ES3/glext.h>

@interface CameraUtil () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    BOOL _frontCamera;
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _cameraTexture;
    CGSize _cameraTextureSize;
    int _cameraImageDataPitch;
    int _cameraImageDataSize;
    uint8_t* _cameraImageData;
}

@property (nonatomic) AVCaptureSession* cameraSession;
@property (nonatomic) AVCaptureDeviceDiscoverySession* deviceDiscoverySession;
@property (nonatomic) AVCaptureDevice* cameraDevice;
@property (nonatomic) AVCaptureDeviceInput* cameraInput;
@property (nonatomic) AVCaptureVideoDataOutput* cameraOutput;

@end

@implementation CameraUtil {
    dispatch_queue_t _queue;
}

- (BOOL)hasCameraTexture {
    return _cameraTexture != NULL;
}

- (int)getCameraTextureWidth {
    return (int) _cameraTextureSize.width;
}

- (int)getCameraTextureHeight {
    return (int) _cameraTextureSize.height;
}

- (GLuint)getCameraTextureId {
    return CVOpenGLESTextureGetName(_cameraTexture);
}

- (int)getCameraImageDataPitch {
    return _cameraImageDataPitch;
}

- (uint8_t*)getCameraImageData {
    return _cameraImageData;
}

- (id)initWithGLContext:(EAGLContext*)context captureSize:(AVCaptureSessionPreset)size {
    self = [super init];
    
    BOOL frontCamera = TRUE;
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (CVEAGLContext)context, NULL, &_textureCache);
    _cameraTexture = NULL;
    _cameraTextureSize = CGSizeMake(0, 0);
    _cameraImageDataPitch = 0;
    _cameraImageDataSize = 0;
    _cameraImageData = nullptr;
    
    self.cameraSession = [[AVCaptureSession alloc] init];
    self.deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position: frontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
    [self.cameraSession setSessionPreset:size];
    
    [self selectCamera:frontCamera];
    
    return self;
}

- (void)dealloc {
    if (_cameraImageData) {
        free(_cameraImageData);
    }
    if (_cameraTexture) {
        CFRelease(_cameraTexture);
    }
    CFRelease(_textureCache);
}

- (void)selectCamera:(BOOL)front {
    if ([self.cameraSession isRunning]) {
        [self.cameraSession stopRunning];
    }
    if (self.cameraInput) {
        [self.cameraSession removeInput:self.cameraInput];
    }
    if (self.cameraOutput) {
        [self.cameraSession removeOutput:self.cameraOutput];
    }
    
    [self.cameraSession beginConfiguration];
    
    NSArray<AVCaptureDevice*>* devices = self.deviceDiscoverySession.devices;
    
    for (AVCaptureDevice* device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if (device.position == front ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack) {
                self.cameraDevice = device;
                _frontCamera = front;
                break;
            }
        }
    }
    
    self.cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:nil];
    [self.cameraSession addInput:self.cameraInput];
    
    self.cameraOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.cameraSession addOutput:self.cameraOutput];
    
    AVCaptureConnection* connection = [self.cameraOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoMirrored:front];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [self.cameraOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.cameraOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    //子线程崩溃
    if (!_queue) {
        _queue = dispatch_queue_create("com.video__cap", 0);
    }
    [self.cameraOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [self.cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 24)];
    [self.cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 24)];
    
    [self.cameraSession commitConfiguration];
    [self.cameraSession startRunning];
}

- (void)focusAuto {
    NSError *error;
    if ([self.cameraDevice lockForConfiguration:&error]) {
        if ([self.cameraDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [self.cameraDevice setFocusPointOfInterest:CGPointMake(0.5, 0.5)];
            [self.cameraDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if ([self.cameraDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure ]) {
            [self.cameraDevice setExposurePointOfInterest:CGPointMake(0.5, 0.5)];
            [self.cameraDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        [self.cameraDevice unlockForConfiguration];
    }
}

- (void)focusAtPoint:(CGPoint)point {
    NSError *error;
    if ([self.cameraDevice lockForConfiguration:&error]) {
        //对焦模式和对焦点
        if ([self.cameraDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.cameraDevice setFocusPointOfInterest:point];
            [self.cameraDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //曝光模式和曝光点
        if ([self.cameraDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.cameraDevice setExposurePointOfInterest:point];
            [self.cameraDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.cameraDevice unlockForConfiguration];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    if (_cameraTexture) {
        CFRelease(_cameraTexture);
        _cameraTexture = NULL;
    }
    
    int width  = (int) CVPixelBufferGetWidth(pixelBuffer);
    int height = (int) CVPixelBufferGetHeight(pixelBuffer);
    uint8_t* baseAddress = (uint8_t*) CVPixelBufferGetBaseAddress(pixelBuffer);
    _cameraImageDataPitch = (int) CVPixelBufferGetBytesPerRow(pixelBuffer);
    int dataSize = (int) CVPixelBufferGetDataSize(pixelBuffer);
    if (_cameraImageData == nullptr || _cameraImageDataSize != dataSize) {
        if (_cameraImageData) {
            free(_cameraImageData);
            _cameraImageData = nullptr;
        }
        _cameraImageDataSize = dataSize;
        _cameraImageData = (uint8_t*) malloc(_cameraImageDataSize);
    }
    memcpy(_cameraImageData, baseAddress, dataSize);
//    _cameraImageData = baseAddress;
    
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_cameraTexture);
    _cameraTextureSize = CGSizeMake(width, height);
    
    GLenum target = CVOpenGLESTextureGetTarget(_cameraTexture);
    assert(target == GL_TEXTURE_2D);
    
    GLuint textureId = CVOpenGLESTextureGetName(_cameraTexture);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    
}

@end
