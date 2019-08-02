#import "FilterEffectPanel.h"

@interface Filter : NSObject
@property NSString* name;
@property NSString* path;
@property UIView* item;
@property CGRect imageFrame;
@property int min;
@property int max;
@property int percent;
@end

@implementation Filter
@end

@interface FilterEffectPanel () {
    UIView* _top;
    UIView* _bottom;
    CGRect _frame;
    float _edgeBottom;
    int _select;
    UIImageView* _selectBorder;
    UISlider* _seek;
    UILabel* _seekName;
    UILabel* _seekValue;
    NSMutableArray* _filters;
    FilterUtil* _filterUtil;
    OFHandle _context;
}

@end

@implementation FilterEffectPanel

- (instancetype)initWithFrame:(CGRect)frame andContext:(OFHandle)context {
    self = [super initWithFrame:frame];
    _frame = frame;
    _select = -1;
    _selectBorder = nil;
    _context = context;
    _filterUtil = new FilterUtil();

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

- (void)dealloc {
    delete _filterUtil;
}

- (void)clickPanel {
    // empty
}

- (void)initScroll {
    float scrollH = (_frame.size.height - _edgeBottom) / 2;
    UIScrollView* scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _frame.size.width, scrollH)];
    scroll.showsHorizontalScrollIndicator = FALSE;
    scroll.bounces = FALSE;
    [_bottom addSubview:scroll];
    
    NSArray* titles = [NSArray arrayWithObjects:
                       @"原图",
                       @"假日",
                       @"清晰",
                       @"暖阳",
                       @"清新",
                       @"粉嫩",
                       nil];
    NSArray* icons = [NSArray arrayWithObjects:
                      @"beauty_original.png",
                      @"filter_5.png",
                      @"filter_3.png",
                      @"filter_1.png",
                      @"filter_2.png",
                      @"filter_6.png",
                      nil];
    NSArray* pathes = [NSArray arrayWithObjects:
                       @"",
                       @"slookuptable1.zip",
                       @"slookuptable2.zip",
                       @"slookuptable3.zip",
                       @"slookuptable4.zip",
                       @"slookuptable5.zip",
                       nil];
    
    const float itemW = 80;
    float panelW = itemW * titles.count;
    UIView* panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelW, scrollH)];
    [scroll addSubview:panel];
    scroll.contentSize = CGSizeMake(panelW, scrollH);
    
    _filters = [NSMutableArray new];
    
    for (int i = 0; i < titles.count; ++i) {
        UIView* item = [[UIView alloc] initWithFrame:CGRectMake(itemW * i, 0, itemW, scrollH)];
        [panel addSubview:item];
        
        const float nameH = 38.67f;
        UILabel* name = [[UILabel alloc] initWithFrame:CGRectMake(0, scrollH - nameH, itemW, nameH)];
        name.font = [UIFont systemFontOfSize:14];
        name.textColor = [UIColor whiteColor];
        name.textAlignment = NSTextAlignmentCenter;
        name.text = titles[i];
        [item addSubview:name];
        
        NSString* imagePath = [NSString stringWithFormat:@"%@/images/%@",
                               [[NSBundle mainBundle] bundlePath],
                               icons[i]];
        UIImage* img = [UIImage imageWithContentsOfFile:imagePath];
        
        const float imageH = 60;
        float imageW = imageH * img.size.width / img.size.height;
        float imageX = (itemW - imageW) / 2;
        float imageY = scrollH - nameH - imageH;
        UIImageView* image = [[UIImageView alloc] initWithFrame:CGRectMake(imageX, imageY, imageW, imageH)];
        image.image = img;
        [item addSubview:image];
        
        item.userInteractionEnabled = TRUE;
        item.tag = i;
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickFilter:)];
        [item addGestureRecognizer:tap];
        
        Filter* filter = [Filter new];
        filter.name = name.text;
        filter.path = pathes[i];
        filter.item = item;
        filter.imageFrame = image.frame;
        filter.min = 0;
        filter.max = 100;
        filter.percent = -1;
        
        [_filters addObject:filter];
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
    _seek.value = 100;
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
    _seekValue.text = @"100";
    [_top addSubview:_seekValue];
}

- (void)onSliderValueChange:(UISlider*)slider {
    int percent = (int) slider.value;
    Filter* filter = _filters[_select];
    filter.percent = percent;
    
    int value = filter.min + ( filter.max - filter.min) * filter.percent / 100;
    _seekValue.text = [NSString stringWithFormat:@"%d", value];
    
    _filterUtil->SetFilterIntensity(value);
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

- (void)clickFilter:(UITapGestureRecognizer*)tap {
    int index = (int) tap.view.tag;
    if (_select != index) {
        [self selectFilter:index];
    }
}

- (void)selectFilter:(int)index {
    _select = index;
    
    Filter* filter = _filters[_select];
    
    if (_selectBorder == nil) {
        NSString* imagePath = [NSString stringWithFormat:@"%@/images/border.png",
                               [[NSBundle mainBundle] bundlePath]];
        UIImage* img = [UIImage imageWithContentsOfFile:imagePath];
        
        _selectBorder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _selectBorder.image = img;
    }
    [_selectBorder removeFromSuperview];
    
    _selectBorder.frame = filter.imageFrame;
    [filter.item addSubview:_selectBorder];
    
    if (_select == 0) {
        _filterUtil->ClearEffect();
        
        [self hideTopSeek];
    } else {
        [self loadFilter:filter.path];
        
        if (filter.percent == -1) {
            filter.percent = _filterUtil->GetFilterIntensity();
        }
        
        int value = filter.percent;
        _seekName.text = filter.name;
        _seek.value = filter.percent;
        
        [self onSliderValueChange:_seek];
        [self showTopSeek];
    }
}

- (void)loadFilter:(NSString*)path {
    _filterUtil->ClearEffect();
    
    NSString* effectPath = [NSString stringWithFormat:@"%@/effects/%@", [[NSBundle mainBundle] bundlePath], path];
    _filterUtil->LoadEffect(_context, [effectPath UTF8String]);
}

- (void)show {
    if (_select == -1) {
        [self selectFilter:0];
    }
}

- (FilterUtil*)getFilterUtil {
    return _filterUtil;
}

@end
