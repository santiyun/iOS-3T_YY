#import "BeautyEffectPanel.h"

@interface BeautyOption : NSObject
@property NSString* name;
@property UIView* item;
@property CGRect imageFrame;
@property int min;
@property int max;
@property int percent;
@end

@implementation BeautyOption
@end

@interface BeautyEffectPanel () {
    UIView* _top;
    UIView* _bottom;
    CGRect _frame;
    float _edgeBottom;
    int _select;
    UIImageView* _selectBorder;
    UISlider* _seek;
    UILabel* _seekName;
    UILabel* _seekValue;
    NSMutableArray* _beautyOptions;
    BeautyTool* _beautyUtil;
}

@end

@implementation BeautyEffectPanel

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context {
    self = [super initWithFrame:frame];
    _frame = frame;
    _select = -1;
    _selectBorder = nil;
    _beautyUtil = [[BeautyTool alloc] init];
    
    NSString *effectPath = [NSBundle.mainBundle pathForResource:@"beauty.zip" ofType:nil];
    [_beautyUtil loadEffect:context path:effectPath];
    
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
    
    float h = (_frame.size.height - _edgeBottom) / 2;
    _top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _frame.size.width, h)];
    _bottom = [[UIView alloc] initWithFrame:CGRectMake(0, h, _frame.size.width, h)];
    
    [self addSubview:_top];
    [self addSubview:_bottom];
    
    [self initScroll];
    [self initSlider];

    return self;
}

- (void)clickPanel {}

- (void)initScroll {
    float scrollH = (_frame.size.height - _edgeBottom) / 2;
    UIScrollView* scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _frame.size.width, scrollH)];
    scroll.showsHorizontalScrollIndicator = FALSE;
    scroll.bounces = FALSE;
    [_bottom addSubview:scroll];
    
    NSArray* titles = [NSArray arrayWithObjects:
                       @"原图",
                       @"美肤",   // beautyfilter Opacity
                       @"美白",   // lookuptable Intensity
                       @"窄脸",   // ThinfaceIntensity
                       @"小脸",   // SmallfaceIntensity
                       @"瘦颧骨", // SquashedFaceIntensity
                       @"额高",   // ForeheadLiftingIntensity
                       @"额宽",   // WideForeheadIntensity
                       @"大眼",   // BigSmallEyeIntensity
                       @"眼距",   // EyesOffset
                       @"眼角",   // EyesRotationIntensity
                       @"瘦鼻",   // ThinNoseIntensity
                       @"长鼻",   // LongNoseIntensity
                       @"窄鼻梁", // ThinNoseBridgeIntensity
                       @"小嘴",   // ThinmouthIntensity
                       @"嘴位",   // MovemouthIntensity
                       @"下巴",   // ChinLiftingIntensity
                       nil];
    NSArray* icons = [NSArray arrayWithObjects:
                      @"beauty_original.png",
                      @"beauty_1.png",
                      @"beauty_0.png",
                      @"beauty_2.png",
                      @"beauty_3.png",
                      @"beauty_4.png",
                      @"beauty_5.png",
                      @"beauty_6.png",
                      @"beauty_7.png",
                      @"beauty_8.png",
                      @"beauty_9.png",
                      @"beauty_10.png",
                      @"beauty_11.png",
                      @"beauty_12.png",
                      @"beauty_13.png",
                      @"beauty_14.png",
                      @"beauty_15.png",
                      nil];
    
    const float itemW = 80;
    float contentW = itemW * titles.count;
    UIView* content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentW, scrollH)];
    [scroll addSubview:content];
    scroll.contentSize = CGSizeMake(contentW, scrollH);
    
    _beautyOptions = [NSMutableArray new];
    for (int i = 0; i < titles.count; ++i) {
        UIView* item = [[UIView alloc] initWithFrame:CGRectMake(itemW * i, 0, itemW, scrollH)];
        [content addSubview:item];
        
        const float nameH = 38.67f;
        UILabel* name = [[UILabel alloc] initWithFrame:CGRectMake(0, scrollH - nameH, itemW, nameH)];
        name.font = [UIFont systemFontOfSize:14];
        name.textColor = [UIColor whiteColor];
        name.textAlignment = NSTextAlignmentCenter;
        name.text = titles[i];
        [item addSubview:name];
        UIImage *img = [UIImage imageNamed:icons[i]];
        
        const float imageH = 60;
        float imageW = imageH * img.size.width / img.size.height;
        float imageX = (itemW - imageW) / 2;
        float imageY = scrollH - nameH - imageH;
        UIImageView* image = [[UIImageView alloc] initWithFrame:CGRectMake(imageX, imageY, imageW, imageH)];
        image.image = img;
        [item addSubview:image];
        
        item.userInteractionEnabled = TRUE;
        item.tag = i;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickOption:)];
        [item addGestureRecognizer:tap];
        
        BeautyOption* opt = [BeautyOption new];
        opt.name = name.text;
        opt.item = item;
        opt.imageFrame = image.frame;
        if (i >= 1) {
            opt.min = [_beautyUtil getBeautyOptionMinValue:i-1];
            opt.max = [_beautyUtil getBeautyOptionMaxValue:i-1];
            opt.percent = ([_beautyUtil getBeautyOptionValue:i-1] - opt.min) * 100 / (opt.max - opt.min);
        } else {
            opt.min = 0;
            opt.max = 100;
            opt.percent = 50;
        }
        
        [_beautyOptions addObject:opt];
    }
}

- (void)initSlider {
    const float sliderH = 30;
    const float sliderX = 60;
    float topW = _frame.size.width;
    float topH = _top.frame.size.height;
    float sliderW = topW - sliderX * 2;
    float sliderY = (topH - sliderH) / 2;
    _seek = [[UISlider alloc] initWithFrame:CGRectMake(sliderX, sliderY, sliderW, sliderH)];
    _seek.minimumValue = 0;
    _seek.maximumValue = 100;
    _seek.value = 50;
    [_seek addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [_top addSubview:_seek];
    
    _seekName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sliderX, topH)];
    _seekName.font = [UIFont systemFontOfSize:14];
    _seekName.textColor = [UIColor whiteColor];
    _seekName.textAlignment = NSTextAlignmentCenter;
    _seekName.text = @"";
    [_top addSubview:_seekName];
    
    _seekValue = [[UILabel alloc] initWithFrame:CGRectMake(topW - sliderX, 0, sliderX, topH)];
    _seekValue.font = [UIFont systemFontOfSize:14];
    _seekValue.textColor = [UIColor whiteColor];
    _seekValue.textAlignment = NSTextAlignmentCenter;
    _seekValue.text = @"50";
    [_top addSubview:_seekValue];
}

- (void)onSliderValueChange:(UISlider*)slider {
    int percent = (int) slider.value;
    BeautyOption* opt = _beautyOptions[_select];
    opt.percent = percent;
    
    int value = opt.min + (opt.max - opt.min) * opt.percent / 100;
    _seekValue.text = [NSString stringWithFormat:@"%d", value];
    
    [_beautyUtil setBeautyOptionValue:_select - 1 value:value];
}

- (void)hideTopSeek {
    float h = (_frame.size.height - _edgeBottom) / 2;
    [self setFrame:CGRectMake(_frame.origin.x, _frame.origin.y + h, _frame.size.width, _frame.size.height - h)];
    [_top setHidden:TRUE];
    [_bottom setFrame:CGRectMake(0, 0, _frame.size.width, h)];
}

- (void)showTopSeek {
    float h = (_frame.size.height - _edgeBottom) / 2;
    [self setFrame:_frame];
    [_top setHidden:FALSE];
    [_bottom setFrame:CGRectMake(0, h, _frame.size.width, h)];
}

- (void)clickOption:(UITapGestureRecognizer*)tap {
    int index = (int) tap.view.tag;
    if (_select != index) {
        [self selectOption:index];
    }
}

- (void)selectOption:(int)index {
    _select = index;
    
    BeautyOption* opt = _beautyOptions[_select];
    
    if (_selectBorder == nil) {
        UIImage* img = [UIImage imageNamed:@"border"];
        
        _selectBorder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _selectBorder.image = img;
    }
    [_selectBorder removeFromSuperview];
    
    _selectBorder.frame = opt.imageFrame;
    [opt.item addSubview:_selectBorder];
    
    if (_select == 0) {
        [self onEnableBeautyEffect:false];
        [self hideTopSeek];
    } else {
        _seekName.text = opt.name;
        _seek.value = opt.percent;
        
        [self onSliderValueChange:_seek];
        [self onEnableBeautyEffect:true];
        [self showTopSeek];
    }
}

- (void)onEnableBeautyEffect:(bool)enable {
    _beautyUtil.enable = enable;
}

- (void)show {
    if (_select == -1) {
        [self selectOption:1];
    }
}

- (BeautyTool *)getBeautyUtil {
    return _beautyUtil;
}

@end
