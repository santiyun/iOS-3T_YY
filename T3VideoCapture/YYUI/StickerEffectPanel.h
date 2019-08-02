#import <UIKit/UIKit.h>
#include "StickerUtil.h"

@interface StickerEffectPanel : UIView <NSURLSessionDelegate>

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context;
- (void)show;
- (StickerUtil*)getStickerUtil;

@end
