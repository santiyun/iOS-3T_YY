#include "EffectRender.h"
#include <assert.h>
#include <string.h>
#include <string>
#include <vector>

static const float MatIdentity[] = {
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
};
static const float MatFlipY[] = {
    1, 0, 0, 0,
    0, -1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1,
};

EffectRender::EffectRender(int width, int height, const char* dataPath)
{
    // screen size
    _width = width;
    _height = height;
    _inTex = 0;
    _outTex = 0;
    _dataPath = dataPath;
    _beautyUtil = nullptr;
    _filterUtil = nullptr;
    _stickerUtil = nullptr;
    
    glGenFramebuffers(1, &_fbo);
    
    this->InitQuad();
    this->InitCopyProgram();

    std::string modelPath = _dataPath + "/venus_models";
    OF_Result ret = OF_CreateContext(&_context, modelPath.c_str());
    if (ret != OF_Result_Success)
    {
        _context = OF_INVALID_HANDLE;
    }
}

EffectRender::~EffectRender()
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
}

void EffectRender::ApplyFrame(OF_Texture* inTex, OF_Texture* outTex, OF_FrameData* frameData)
{
    if (_context != OF_INVALID_HANDLE)
    {
        std::vector<OFHandle> effects;
        std::vector<OF_Result> results;
        
        if (_beautyUtil != nullptr &&
            _beautyUtil->GetEffect() != OF_INVALID_HANDLE &&
            _beautyUtil->IsEnable())
        {
            effects.push_back(_beautyUtil->GetEffect());
        }
        if (_filterUtil != nullptr &&
            _filterUtil->GetEffect() != OF_INVALID_HANDLE)
        {
            effects.push_back(_filterUtil->GetEffect());
        }
        if (_stickerUtil != nullptr &&
            _stickerUtil->GetEffect() != OF_INVALID_HANDLE)
        {
            effects.push_back(_stickerUtil->GetEffect());
        }
        
        if (effects.size() > 0) {
            results.resize(effects.size());
#pragma mark - 3333  OF_ApplyFrameBatch
            OF_ApplyFrameBatch(_context, &effects[0], (OFUInt32) effects.size(), inTex, 1, outTex, 1, frameData, &results[0], (OFUInt32) results.size());
        } else {
            // copy
            glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outTex->textureID, 0);
            glViewport(0, 0, outTex->width, outTex->height);
            
            this->DrawQuad(inTex->textureID, MatFlipY);
        }
    }
}

void EffectRender::Render(GLuint cameraTexture, int width, int height, OF_FrameData* frameData)
{
    if (_inTex == 0)
    {
        glGenTextures(1, &_inTex);
        glBindTexture(GL_TEXTURE_2D, _inTex);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, OF_NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    if (_outTex == 0)
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
    
    // flip y
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _inTex, 0);
    glViewport(0, 0, width, height);
    
    this->DrawQuad(cameraTexture, MatFlipY);
    
    // apply frame
    OF_Texture inTex;
    inTex.target = GL_TEXTURE_2D;
    inTex.width = width;
    inTex.height = height;
    inTex.format = GL_RGBA;
    inTex.textureID = _inTex;
    
    OF_Texture outTex;
    outTex.target = GL_TEXTURE_2D;
    outTex.width = width;
    outTex.height = height;
    outTex.format = GL_RGBA;
    outTex.textureID = _outTex;
    
    // clear out first
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outTex, 0);
    glViewport(0, 0, width, height);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    this->ApplyFrame(&inTex, &outTex, frameData);
    
    assert(glGetError() == 0);
    
    // output to view
    glBindFramebuffer(GL_FRAMEBUFFER, oldFbo);
    glViewport(0, 0, _width, _height);
    glClear(GL_COLOR_BUFFER_BIT);
    
    int x, y, w, h;
#if 1
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
#else
    // center
    if (_height / (float) _width > height / (float) width)
    {
        w = _width;
        h = w * height / width;
    }
    else
    {
        h = _height;
        w = h * width / height;
    }
#endif
    x = (_width - w) / 2;
    y = (_height - h) / 2;
    
    glViewport(x, y, w, h);
    
    this->DrawQuad(_outTex, MatIdentity);
    
    assert(glGetError() == 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _outTex, 0);
    if (_outBuffer == nullptr || _outBufferSize < width * height * 4) {
        _outBuffer = (uint8_t*) realloc(_outBuffer, width * height * 4);
    }
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, _outBuffer);
    if (_m_CBVideo) {
        _m_CBVideo(_outBuffer, width, height);
    }
}

void EffectRender::InitQuad()
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

void EffectRender::InitCopyProgram()
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

void EffectRender::DrawQuad(GLuint tex, const float* transform)
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
