//
//  EffectTool.h
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/7.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <AVFoundation/AVFoundation.h>
#import <of_effect/orangefilter.h>
#import "FilterTool.h"
#import "BeautyTool.h"
#import "StickerTool.h"

@interface EffectTool : NSObject

@property (nonatomic) OFHandle context;

- (instancetype)initWithContext:(EAGLContext *)context width:(int)width height:(int)height path:(NSString *)path;
- (void)setTool:(FilterTool *)filterTool beautyTool:(BeautyTool *)beautyTool stickerTool:(StickerTool *)stickerTool;

- (CVPixelBufferRef)render:(CVPixelBufferRef)inPixelBuffer;

@end


