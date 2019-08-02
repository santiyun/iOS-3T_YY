#include "FilterUtil.h"
#include <stdio.h>

FilterUtil::FilterUtil():
    _context(OF_INVALID_HANDLE),
    _effect(OF_INVALID_HANDLE)
{
    
}

FilterUtil::~FilterUtil()
{
    this->ClearEffect();
}

void FilterUtil::LoadEffect(OFHandle context, const std::string& path)
{
    this->ClearEffect();
    
    _context = context;
    
    OF_Result result = OF_CreateEffectFromPackage(_context, path.c_str(), (OFHandle*) &_effect);
    if (result != OF_Result_Success)
    {
        printf("load effect failed");
    }
    
    OF_GetEffectInfo(_context, _effect, &_info);
}

void FilterUtil::ClearEffect()
{
    if (_effect != OF_INVALID_HANDLE)
    {
        OF_DestroyEffect(_context, _effect);
        _effect = OF_INVALID_HANDLE;
    }
    _context = OF_INVALID_HANDLE;
}

OF_Param* FilterUtil::GetFilterParam() const
{
    int filter = _info.filterList[0];
    OF_Param* param = OF_NULL;
    OF_GetFilterParamData(_context, filter, "Intensity", &param);
    return param;
}

void FilterUtil::SetFilterIntensity(int value)
{
    OF_Param* param = this->GetFilterParam();
    OF_Paramf* paramf = param->data.paramf;
    paramf->val = value / 100.0f;
    
    int filter = _info.filterList[0];
    OF_SetFilterParamData(_context, filter, param->name, param);
}

int FilterUtil::GetFilterIntensity() const
{
    OF_Param* param = this->GetFilterParam();
    OF_Paramf* paramf = param->data.paramf;
    return (int) (paramf->val * 100);
}
