#include "BeautyUtil.h"
#include <stdio.h>

#define FILTER_COUNT 4

#define FILTER_INDEX_WHITE 0
#define FILTER_INDEX_BEAUTY 1
#define FILTER_INDEX_LEVELS 2
#define FILTER_INDEX_FACELIFTING 3
#define FILTER_COUNT 4

enum class BeautyOption
{
    BEAUTY_OPTION_SKIN = 0,
    BEAUTY_OPTION_WHITE = 1,
    BEAUTY_OPTION_THIN_FACE = 2,
    BEAUTY_OPTION_SMALL_FACE = 3,
    BEAUTY_OPTION_SQUASH_FACE = 4,
    BEAUTY_OPTION_FOREHEAD_LIFTING = 5,
    BEAUTY_OPTION_WIDE_FOREHEAD = 6,
    BEAUTY_OPTION_BIG_EYE = 7,
    BEAUTY_OPTION_EYE_DISTANCE = 8,
    BEAUTY_OPTION_EYE_ROTATE = 9,
    BEAUTY_OPTION_THIN_NOSE = 10,
    BEAUTY_OPTION_LONG_NOSE = 11,
    BEAUTY_OPTION_THIN_NOSE_BRIDGE = 12,
    BEAUTY_OPTION_THIN_MOUTH = 13,
    BEAUTY_OPTION_MOVE_MOUTH = 14,
    BEAUTY_OPTION_CHIN_LIFTING = 15,
};

static const char* BEAUTY_OPTION_NAMES[] = {
    "Opacity",
    "Intensity",
    "ThinfaceIntensity",
    "SmallfaceIntensity",
    "SquashedFaceIntensity",
    "ForeheadLiftingIntensity",
    "WideForeheadIntensity",
    "BigSmallEyeIntensity",
    "EyesOffset",
    "EyesRotationIntensity",
    "ThinNoseIntensity",
    "LongNoseIntensity",
    "ThinNoseBridgeIntensity",
    "ThinmouthIntensity",
    "MovemouthIntensity",
    "ChinLiftingIntensity",
};

BeautyUtil::BeautyUtil():
    _context(OF_INVALID_HANDLE),
    _effect(OF_INVALID_HANDLE),
    _enable(true)
{
    
}

BeautyUtil::~BeautyUtil()
{
    this->ClearEffect();
}

void BeautyUtil::LoadEffect(OFHandle context, const std::string& path)
{
    _context = context;
    
    OF_Result result = OF_CreateEffectFromPackage(_context, path.c_str(), (OFHandle*) &_effect);
    if (result != OF_Result_Success)
    {
        printf("load effect failed");
    }
    
    OF_GetEffectInfo(_context, _effect, &_info);
    
    if (_info.filterCount != FILTER_COUNT)
    {
        printf("effect info error with filter count: %d", _info.filterCount);
    }
}

void BeautyUtil::ClearEffect()
{
    if (_effect != OF_INVALID_HANDLE)
    {
        OF_DestroyEffect(_context, _effect);
        _effect = OF_INVALID_HANDLE;
    }
    _context = OF_INVALID_HANDLE;
}

int BeautyUtil::GetFilterIndex(int option)
{
    if (option == (int) BeautyOption::BEAUTY_OPTION_WHITE)
    {
        return FILTER_INDEX_WHITE;
    }
    else if (option == (int) BeautyOption::BEAUTY_OPTION_SKIN)
    {
        return FILTER_INDEX_BEAUTY;
    }
    else
    {
        return FILTER_INDEX_FACELIFTING;
    }
}

OF_Param* BeautyUtil::GetFilterParam(int option)
{
    int filter = _info.filterList[this->GetFilterIndex(option)];
    const char* name = BEAUTY_OPTION_NAMES[option];
    OF_Param* param = OF_NULL;
    OF_GetFilterParamData(_context, filter, name, &param);
    return param;
}

int BeautyUtil::GetBeautyOptionMinValue(int option)
{
    OF_Paramf* param = this->GetFilterParam(option)->data.paramf;
    return (int) (param->minVal / (param->maxVal - param->minVal) * 100);
}

int BeautyUtil::GetBeautyOptionMaxValue(int option)
{
    OF_Paramf* param = this->GetFilterParam(option)->data.paramf;
    return (int) (param->maxVal / (param->maxVal - param->minVal) * 100);
}

int BeautyUtil::GetBeautyOptionDefaultValue(int option)
{
    OF_Paramf* param = this->GetFilterParam(option)->data.paramf;
    return (int) (param->defVal / (param->maxVal - param->minVal) * 100);
}

int BeautyUtil::GetBeautyOptionValue(int option)
{
    OF_Paramf* param = this->GetFilterParam(option)->data.paramf;
    return (int) (param->val / (param->maxVal - param->minVal) * 100);
}

void BeautyUtil::SetBeautyOptionValue(int option, int value)
{
    OF_Param* param = this->GetFilterParam(option);
    OF_Paramf* paramf = param->data.paramf;
    paramf->val = value / 100.0f * (paramf->maxVal - paramf->minVal);
    
    int filter = _info.filterList[this->GetFilterIndex(option)];
    OF_SetFilterParamData(_context, filter, param->name, param);
}
