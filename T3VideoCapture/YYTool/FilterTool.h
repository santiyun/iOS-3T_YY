//
//  FilterTool.h
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/6.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <of_effect/orangefilter.h>

@interface FilterTool : NSObject

- (void)loadEffect:(OFHandle)context path:(NSString *)path;
- (void)clearEffect;
- (int)getFilterIntensity;
- (void)setFilterIntensity:(int)value;
- (OFHandle)getEffect;
@end
