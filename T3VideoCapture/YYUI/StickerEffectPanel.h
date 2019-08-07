#import <UIKit/UIKit.h>
#import "StickerTool.h"

@interface StickerEffectPanel : UIView <NSURLSessionDelegate>

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context;
- (void)show;
- (StickerTool *)getStickerUtil;

@end
