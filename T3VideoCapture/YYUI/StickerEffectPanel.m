#import "StickerEffectPanel.h"
#import "HTTPUtil.h"

@interface Effect : NSObject
@property NSString* name;
@property NSString* thumb;
@property NSString* url;
@property NSString* md5;
@property NSString* path;
@property UIImageView* iconView;
@property UIImageView* downView;
@property UIImageView* loadView;
@property UIView* loadBackView;
@end

@implementation Effect
@end

@interface EffectTab : NSObject
@property NSString* name;
@property NSString* thumb;
@property NSString* selectedThumb;
@property NSString* type;
@property NSMutableArray* effects;
@property UIView* item;
@property UIImageView* thumbView;
@property UIImageView* selectedThumbView;
@end

@implementation EffectTab
@end

@interface StickerEffectPanel () {
    CGRect _frame;
    float _edgeBottom;
    OFHandle _context;
    NSArray* _effectData;
    UIScrollView* _tabScroll;
    NSMutableArray* _effectTabs;
    int _selectTab;
    UIScrollView* _effectScroll;
    int _selectEffect;
    int _selectEffectTab;
    UIImageView* _selectBorder;
    StickerTool* _stickerUtil;
}

@end

@implementation StickerEffectPanel

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context {
    self = [super initWithFrame:frame];
    _frame = frame;
    _context = context;
    _selectTab = -1;
    _selectEffect = -1;
    _selectEffectTab = -1;
    _stickerUtil = [[StickerTool alloc] init];

    if (@available(iOS 11.0, *)) {
        UIEdgeInsets edge = UIApplication.sharedApplication.delegate.window.safeAreaInsets;
        _edgeBottom = edge.bottom;
    } else {
        _edgeBottom = 0;
    }
    
    [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f]];
    
    self.userInteractionEnabled = TRUE;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickPanel)];
    [self addGestureRecognizer:tap];
    
    [self initTab];
    [self initScroll];
    
    [self requestEffectsInfo];
    
    return self;
}

- (void)initTab {
    const float stickerTabH = 50;
    const float stickerLineH = 1;
    
    UIView* tab = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _frame.size.width, stickerTabH)];
    [self addSubview:tab];
    
    // unselect
    UIImage* img = [UIImage imageNamed:@"close"];
    
    const float imageH = 30;
    const float imageX = 5;
    float imageY = (stickerTabH - imageH) / 2;
    UIImageView* image = [[UIImageView alloc] initWithFrame:CGRectMake(imageX, imageY, imageH, imageH)];
    image.image = img;
    image.userInteractionEnabled = TRUE;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelEffect)];
    [image addGestureRecognizer:tap];
    [tab addSubview:image];
    
    // separate
    const float separateW = 1;
    const float separateH = 40;
    float separateX = imageX + imageH + imageX;
    float separateY = (stickerTabH - separateH) / 2;
    UIView* separate = [[UIView alloc] initWithFrame:CGRectMake(separateX, separateY, separateW, separateH)];
    [separate setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5f]];
    [self addSubview:separate];
    
    // scroll
    float scrollX = separateX + separateW;
    float scrollW = _frame.size.width - scrollX;
    _tabScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(scrollX, 0, scrollW, stickerTabH)];
    _tabScroll.showsHorizontalScrollIndicator = FALSE;
    _tabScroll.bounces = FALSE;
    [self addSubview:_tabScroll];
    
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, stickerTabH, _frame.size.width, stickerLineH)];
    [line setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5f]];
    [self addSubview:line];
}

- (void)initScroll {
    const float scrollH = 250;
    float scrollY = _frame.size.height - scrollH;
    _effectScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollY, _frame.size.width, scrollH)];
    _effectScroll.showsHorizontalScrollIndicator = FALSE;
    _effectScroll.bounces = FALSE;
    [self addSubview:_effectScroll];
}

- (void)clickPanel {
    // empty
}

- (void)URLSession:(NSURLSession*)session didReceiveChallenge:(NSURLAuthenticationChallenge*)challenge completionHandler:(void(^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential* credential))completionHandler {
    if(![challenge.protectionSpace.authenticationMethod isEqualToString:@"NSURLAuthenticationMethodServerTrust"]) {
        return;
    }
    NSURLCredential* credential = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
    //NSURLCredential 授权信息
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

- (void)requestEffectsInfo {
    const char* channel = "9c4fc48365";
    const char* version = "1.0.0";
    const int os = 1;

    [HTTPUtil request:[NSString stringWithFormat:@"http://ovotest.yy.com/asset/common?channel=%s&version=%s&os=%d", channel, version, os] sessionDelegate:self callbackJson:^(NSDictionary* json, NSError* error) {
        if (json != nil) {
            NSNumber* code = [json objectForKey:@"code"];
            if (code.intValue == 0) {
                _effectData = [json objectForKey:@"data"];
                if (_effectData != nil) {
                    _effectTabs = [NSMutableArray new];
                    
                    for (int i = 0; i < _effectData.count; ++i) {
                        NSDictionary* dic = _effectData[i];
                        
                        EffectTab* tab = [EffectTab new];
                        tab.name = [dic objectForKey:@"name"];
                        tab.thumb = [dic objectForKey:@"thumb"];
                        tab.selectedThumb = [dic objectForKey:@"selectedThumb"];
                        NSString* groupExpandJson = [dic objectForKey:@"groupExpandJson"];
                        if (groupExpandJson.length > 0) {
                            NSDictionary* ext = [NSJSONSerialization JSONObjectWithData:[groupExpandJson dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
                            tab.type = [ext objectForKey:@"type"];
                        }
                        NSArray* icons = [dic objectForKey:@"icons"];
                        
                        tab.effects = [NSMutableArray new];
                        
                        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                        NSString* cachesDir = [paths objectAtIndex:0];
                        
                        for (int j = 0; j < icons.count; ++j) {
                            NSDictionary* dic = icons[j];
                            
                            Effect* effect = [Effect new];
                            effect.name = [dic objectForKey:@"name"];
                            effect.thumb = [dic objectForKey:@"thumb"];
                            effect.url = [dic objectForKey:@"url"];
                            effect.md5 = [dic objectForKey:@"md5"];
                            effect.path = [NSString stringWithFormat:@"%@/%@.zip", cachesDir, effect.md5];
                            
                            [tab.effects addObject:effect];
                        }
                        
                        if ([tab.type isEqualToString:@"Sticker"]) {
                            [_effectTabs addObject:tab];
                        }
                    }
                    
                    [self updateTab];
                }
            } else {
                NSString* message = [json objectForKey:@"message"];
                NSLog(@"%@", message);
            }
        } else {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }
    }];
}

- (void)updateTab {
    UIView* content = nil;
    
    if ([_tabScroll subviews].count == 1) {
        content = [_tabScroll subviews][0];
        [content removeFromSuperview];
        content = nil;
    }
    
    const float itemW = 50;
    int itemCount = (int) _effectTabs.count;
    float contentW = itemW * itemCount;
    float contentH = _tabScroll.frame.size.height;
    content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, contentH)];
    [_tabScroll addSubview:content];
    _tabScroll.contentSize = content.frame.size;
    
    for (int i = 0; i < itemCount; ++i) {
        EffectTab* tab = _effectTabs[i];
        
        tab.item = [[UIView alloc] initWithFrame:CGRectMake(itemW * i, 0, itemW, contentH)];
        tab.item.tag = i;
        tab.item.userInteractionEnabled = TRUE;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTabItem:)];
        [tab.item addGestureRecognizer:tap];
        [content addSubview:tab.item];
        
        tab.thumbView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 40, 40)];
        tab.selectedThumbView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 40, 40)];
        
        if (_selectTab == i) {
            [tab.item addSubview:tab.selectedThumbView];
        } else {
            [tab.item addSubview:tab.thumbView];
        }
        
        if (tab.thumb.length > 0) {
            [HTTPUtil loadImage:tab.thumb sessionDelegate:self to:tab.thumbView];
        } else {
            UIImage* img = [UIImage imageNamed:@"thumb"];
        }
        if (tab.selectedThumb.length > 0) {
            [HTTPUtil loadImage:tab.selectedThumb sessionDelegate:self to:tab.selectedThumbView];
        } else {
            tab.selectedThumbView.image = [UIImage imageNamed:@"thumb"];
        }
    }
}

- (void)clickTabItem:(UITapGestureRecognizer*)tap {
    int index = (int) tap.view.tag;
    
    if (index != _selectTab) {
        [self selectTab:index];
    }
}

- (void)selectTab:(int)index {
    _selectTab = index;
    
    if (_effectTabs == nil) {
        return;
    }
    
    for (int i = 0; i < _effectTabs.count; ++i) {
        EffectTab* tab = _effectTabs[i];
        [tab.thumbView removeFromSuperview];
        [tab.selectedThumbView removeFromSuperview];
        
        if (_selectTab == i) {
            [tab.item addSubview:tab.selectedThumbView];
        } else {
            [tab.item addSubview:tab.thumbView];
        }
    }
    
    [self updateEffectScroll];
    
    if (_selectEffect >= 0 && _selectEffectTab == _selectTab) {
        [self selectEffect:_selectEffect];
    }
}

- (void)updateEffectScroll {
    UIView* content = nil;
    
    if ([_effectScroll subviews].count == 1) {
        content = [_effectScroll subviews][0];
        [content removeFromSuperview];
        content = nil;
    }
    
    EffectTab* tab = _effectTabs[_selectTab];
    
    const int effectCountPerRow = 5;
    float itemW = _frame.size.width / effectCountPerRow;
    int itemCount = (int) tab.effects.count;
    int rowCount = itemCount / effectCountPerRow;
    if (itemCount % effectCountPerRow != 0) {
        rowCount += 1;
    }
    float contentW = _frame.size.width;
    float contentH = itemW * rowCount;
    content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, contentH)];
    [_effectScroll addSubview:content];
    _effectScroll.contentSize = content.frame.size;
    
    for (int i = 0; i < itemCount; ++i) {
        Effect* effect = tab.effects[i];
        
        int x = i % effectCountPerRow;
        int y = i / effectCountPerRow;
        UIView* item = [[UIView alloc] initWithFrame:CGRectMake(itemW * x, itemW * y, itemW, itemW)];
        item.tag = i;
        item.userInteractionEnabled = TRUE;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickEffectItem:)];
        [item addGestureRecognizer:tap];
        [content addSubview:item];
        
        const float imageX = 10;
        float imageW = itemW - imageX * 2;
        UIImageView* image = [[UIImageView alloc] initWithFrame:CGRectMake(imageX, imageX, imageW, imageW)];
        [item addSubview:image];
        
        if (effect.thumb.length > 0 && [effect.thumb hasSuffix:@".png"]) {
            [HTTPUtil loadImage:effect.thumb sessionDelegate:self to:image];
        } else {
            image.image = [UIImage imageNamed:@"thumb"];
        }
        
        effect.iconView = image;
        
        // download icon
        if (effect.loadView == nil) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:effect.path]) {
                UIImage* img = [UIImage imageNamed:@"download"];
                
                const float iconMargin = 5;
                float iconSize = imageW / 3;
                float iconX = imageW - iconMargin - iconSize;
                float iconY = iconMargin;
                effect.downView = [[UIImageView alloc] initWithFrame:CGRectMake(iconX, iconY, iconSize, iconSize)];
                effect.downView.image = img;
                [image addSubview:effect.downView];
            }
        } else {
            [effect.iconView addSubview:effect.loadBackView];
            [effect.iconView addSubview:effect.loadView];
            
            [self rotationAnimation:effect.loadView];
        }
    }
}

- (void)clickEffectItem:(UITapGestureRecognizer*)tap {
    int index = (int) tap.view.tag;
    
    [self selectEffect:index];
}

- (void)rotationAnimation:(UIView*)view {
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = [NSNumber numberWithFloat:0];
    animation.toValue = [NSNumber numberWithFloat:M_PI];
    animation.duration = 0.5;
    animation.cumulative = YES;
    animation.repeatCount = MAXFLOAT;
    [view.layer addAnimation:animation forKey:nil];
}

- (void)selectEffect:(int)index {
    _selectEffect = index;
    _selectEffectTab = _selectTab;
    
    EffectTab* tab = _effectTabs[_selectEffectTab];
    Effect* effect = tab.effects[_selectEffect];
    
    if (_selectBorder == nil) {
        UIImage* img = [UIImage imageNamed:@"border"];
        
        _selectBorder = [[UIImageView alloc] initWithFrame:effect.iconView.frame];
        _selectBorder.image = img;
    }
    [_selectBorder removeFromSuperview];
    
    [[effect.iconView superview] addSubview:_selectBorder];
    
    if (effect.downView != nil) {
        if (effect.loadView == nil) {
            [effect.downView removeFromSuperview];
            effect.downView = nil;
            
            float size = effect.iconView.frame.size.width;
            effect.loadBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
            effect.loadBackView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
            [effect.iconView addSubview:effect.loadBackView];
            
            UIImage* img = [UIImage imageNamed:@"loading"];
            
            effect.loadView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
            effect.loadView.image = img;
            [effect.iconView addSubview:effect.loadView];

            [self rotationAnimation:effect.loadView];
            
            // download
            [HTTPUtil request:effect.url sessionDelegate:self file:effect.path callbackFile:^(NSString* file, NSError* error) {
                if (file != nil) {
                    [effect.loadBackView removeFromSuperview];
                    effect.loadBackView = nil;
                    [effect.loadView removeFromSuperview];
                    effect.loadView = nil;
                    
                    if (_selectEffect >= 0) {
                        EffectTab* theTab = _effectTabs[_selectEffectTab];
                        if (theTab.effects[_selectEffect] == effect) {
                            [self loadEffect:file];
                        }
                    }
                } else {
                    if (error != nil) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                }
            }];
        }
    } else if (effect.loadView == nil) {
        [self loadEffect:effect.path];
    }
}

- (void)cancelEffect {
    _selectEffect = -1;
    _selectEffectTab = -1;
    
    if (_selectBorder != nil) {
        [_selectBorder removeFromSuperview];
    }
    
    [self unloadEffect];
}

- (void)loadEffect:(NSString*)path {
    [_stickerUtil clearEffect];
    [_stickerUtil loadEffect:_context path:path];
}

- (void)unloadEffect {
    [_stickerUtil clearEffect];
}

- (void)show {
    if (_effectData == nil) {
        [self requestEffectsInfo];
    }
    
    if (_selectTab == -1) {
        [self selectTab:0];
    }
}

- (StickerTool *)getStickerUtil {
    return _stickerUtil;
}

@end
