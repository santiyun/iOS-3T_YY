#import <UIKit/UIKit.h>
#import "FilterTool.h"

@class FilterTool;
@interface FilterEffectPanel : UIView

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context;
- (void)show;
- (FilterTool *)getFilterUtil;

@end
