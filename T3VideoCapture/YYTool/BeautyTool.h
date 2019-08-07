//
//  BeautyTool.h
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/7.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <of_effect/orangefilter.h>

@interface BeautyTool : NSObject
@property (nonatomic) BOOL enable;

- (void)loadEffect:(OFHandle)context path:(NSString *)path;
- (void)clearEffect;
- (int)getFilterIndex:(int)option;
- (OFHandle)getEffect;

- (int)getBeautyOptionMinValue:(int)option;
- (int)getBeautyOptionMaxValue:(int)option;
- (int)getBeautyOptionDefaultValue:(int)option;
- (int)getBeautyOptionValue:(int)option;
- (void)setBeautyOptionValue:(int)option value:(int)value;
@end
