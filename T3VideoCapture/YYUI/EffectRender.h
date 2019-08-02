#pragma once

#include "of_effect/orangefilter.h"
#include "BeautyUtil.h"
#include "FilterUtil.h"
#include "StickerUtil.h"
#include <OpenGLES/ES3/gl.h>
#include <string>

typedef int (*VideoCallBack) (uint8_t* data, int width, int height);

class EffectRender
{
public:
    EffectRender(int width, int height, const char* dataPath);
    ~EffectRender();
    void Render(GLuint cameraTexture, int width, int height, OF_FrameData* frameData);
    OFHandle GetContext() const { return _context; }
    void SetBeautyUtil(BeautyUtil* beautyUtil) { _beautyUtil = beautyUtil; }
    void SetFilterUtil(FilterUtil* filterUtil) { _filterUtil = filterUtil; }
    void SetStickerUtil(StickerUtil* stickerUtil) { _stickerUtil = stickerUtil; }
    void video_init(VideoCallBack videocb) { _m_CBVideo = videocb; };
private:
    void InitQuad();
    void InitCopyProgram();
    void DrawQuad(GLuint tex, const float* transform);
    void ApplyFrame(OF_Texture* inTex, OF_Texture* outTex, OF_FrameData* frameData);

private:
    int _width;
    int _height;
    GLuint _quadVbo;
    GLuint _quadIbo;
    GLuint _copyProgram;
    GLuint _inTex;
    GLuint _outTex;
    GLuint _fbo;
    OFHandle _context;
    std::string _dataPath;
    BeautyUtil* _beautyUtil;
    FilterUtil* _filterUtil;
    StickerUtil* _stickerUtil;
    
    
    uint8_t *_outBuffer;
    int _outBufferSize;
    VideoCallBack _m_CBVideo;
};
