#include "StickerUtil.h"
#include <stdio.h>

StickerUtil::StickerUtil():
    _context(OF_INVALID_HANDLE),
    _effect(OF_INVALID_HANDLE)
{
    
}

StickerUtil::~StickerUtil()
{
    this->ClearEffect();
}

void StickerUtil::LoadEffect(OFHandle context, const std::string& path)
{
    this->ClearEffect();
    
    _context = context;
    
    OF_Result result = OF_CreateEffectFromPackage(_context, path.c_str(), (OFHandle*) &_effect);
    if (result != OF_Result_Success)
    {
        printf("load effect failed");
    }
}

void StickerUtil::ClearEffect()
{
    if (_effect != OF_INVALID_HANDLE)
    {
        OF_DestroyEffect(_context, _effect);
        _effect = OF_INVALID_HANDLE;
    }
    _context = OF_INVALID_HANDLE;
}
