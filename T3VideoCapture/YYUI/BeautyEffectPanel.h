#import <UIKit/UIKit.h>
#import "BeautyTool.h"

@interface BeautyEffectPanel : UIView

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context;
- (void)show;
- (BeautyTool *)getBeautyUtil;

@end
