//
//  StickerTool.h
//  OrangeFilterDemo
//
//  Created by Work on 2019/8/7.
//  Copyright © 2019 tangqiuhu@yy.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <of_effect/orangefilter.h>

@interface StickerTool : NSObject

- (void)loadEffect:(OFHandle)context path:(NSString *)path;
- (void)clearEffect;
- (OFHandle)getEffect;

@end
