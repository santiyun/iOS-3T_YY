//
//  StickerTool.m
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/7.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import "StickerTool.h"

@interface StickerTool ()
@property (nonatomic) OFHandle context;
@property (nonatomic) OFHandle effect;
@end

@implementation StickerTool

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

- (void)loadEffect:(OFHandle)context path:(NSString *)path
{
    [self clearEffect];
    
    _context = context;
    
    OF_Result result = OF_CreateEffectFromPackage(_context, path.UTF8String, (OFHandle*) &_effect);
    if (result != OF_Result_Success)
    {
        printf("load effect failed");
    }
}

- (void)clearEffect
{
    if (_effect != OF_INVALID_HANDLE)
    {
        OF_DestroyEffect(_context, _effect);
        _effect = OF_INVALID_HANDLE;
    }
    _context = OF_INVALID_HANDLE;
}


- (OFHandle)getEffect {
    return _effect;
}
@end
