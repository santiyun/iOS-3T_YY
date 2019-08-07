//
//  FilterTool.m
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/6.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import "FilterTool.h"

@interface FilterTool ()

@property (nonatomic) OFHandle context;
@property (nonatomic) OFHandle effect;
@property(nonatomic) OF_EffectInfo info;
@end

@implementation FilterTool

- (void)dealloc
{
    [self clearEffect];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _context = OF_INVALID_HANDLE;
        _effect = OF_INVALID_HANDLE;
    }
    return self;
}

- (void)loadEffect:(OFHandle)context path:(NSString *)path {
    [self clearEffect];
    _context = context;
    
    OF_Result result = OF_CreateEffectFromPackage(_context, path.UTF8String, (OFHandle*) &_effect);
    if (result != OF_Result_Success)
    {
        printf("load effect failed");
    }
    
    OF_GetEffectInfo(_context, _effect, &_info);
}

- (void)clearEffect {
    if (_effect != OF_INVALID_HANDLE)
    {
        OF_DestroyEffect(_context, _effect);
        _effect = OF_INVALID_HANDLE;
    }
    _context = OF_INVALID_HANDLE;
}

- (OF_Param *)getFilterParam {
    int filter = _info.filterList[0];
    OF_Param* param = OF_NULL;
    OF_GetFilterParamData(_context, filter, "Intensity", &param);
    return param;
}

- (void)setFilterIntensity:(int)value {
    OF_Param* param = [self getFilterParam];
    OF_Paramf* paramf = param->data.paramf;
    paramf->val = value / 100.0f;
    
    int filter = _info.filterList[0];
    OF_SetFilterParamData(_context, filter, param->name, param);
}

- (int)getFilterIntensity {
    OF_Param* param = [self getFilterParam];
    OF_Paramf* paramf = param->data.paramf;
    return (int) (paramf->val * 100);
}

-(OFHandle)getEffect {
    return _effect;
}
@end
