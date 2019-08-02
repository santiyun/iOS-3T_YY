#pragma once

#include "of_effect/orangefilter.h"
#include <string>

class FilterUtil
{
public:
    FilterUtil();
    ~FilterUtil();
    void LoadEffect(OFHandle context, const std::string& path);
    OFHandle GetEffect() const { return _effect; }
    void ClearEffect();
    void SetFilterIntensity(int value);
    int GetFilterIntensity() const;
    
private:
    OF_Param* GetFilterParam() const;
    
private:
    OFHandle _context;
    OFHandle _effect;
    OF_EffectInfo _info;
};
