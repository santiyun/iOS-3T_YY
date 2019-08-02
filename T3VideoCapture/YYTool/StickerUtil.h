#pragma once

#include "of_effect/orangefilter.h"
#include <string>

class StickerUtil
{
public:
    StickerUtil();
    ~StickerUtil();
    void LoadEffect(OFHandle context, const std::string& path);
    OFHandle GetEffect() const { return _effect; }
    void ClearEffect();
    
private:
    OFHandle _context;
    OFHandle _effect;
};
