#import <UIKit/UIKit.h>
#include "FilterUtil.h"

@interface FilterEffectPanel : UIView

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context;
- (void)show;
- (FilterUtil*)getFilterUtil;

@end
