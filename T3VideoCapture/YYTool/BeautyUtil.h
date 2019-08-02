#pragma once

#include "of_effect/orangefilter.h"
#include <string>

class BeautyUtil
{
public:
    BeautyUtil();
    ~BeautyUtil();
    void LoadEffect(OFHandle context, const std::string& path);
    void EnableEffect(bool enable) { _enable = enable; }
    bool IsEnable() const { return _enable; }
    OFHandle GetEffect() const { return _effect; }
    void ClearEffect();
    int GetBeautyOptionMinValue(int option);
    int GetBeautyOptionMaxValue(int option);
    int GetBeautyOptionDefaultValue(int option);
    int GetBeautyOptionValue(int option);
    void SetBeautyOptionValue(int option, int value);
    
private:
    int GetFilterIndex(int option);
    OF_Param* GetFilterParam(int option);
    
private:
    OFHandle _context;
    OFHandle _effect;
    OF_EffectInfo _info;
    bool _enable;
};
