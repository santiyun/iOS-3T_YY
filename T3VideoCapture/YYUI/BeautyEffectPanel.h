#import <UIKit/UIKit.h>
#include "BeautyUtil.h"
#include "EffectRender.h"

@interface BeautyEffectPanel : UIView

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context;
- (void)show;
- (BeautyUtil*)getBeautyUtil;

@end
