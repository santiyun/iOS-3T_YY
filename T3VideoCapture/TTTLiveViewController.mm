//
//  TTTLiveViewController.m
//  T3VideoCapture
//
//  Created by Work on 2019/7/4.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "TTTLiveViewController.h"
#import <of_effect/orangefilter.h>
#import <GLKit/GLKit.h>
#import "TTTRtcManager.h"
#include "CameraUtil.h"
#include "EffectRender.h"
#import "BeautyEffectPanel.h"
#import "FilterEffectPanel.h"
#import "StickerEffectPanel.h"
#import "HTTPUtil.h"
#import <CoreImage/CoreImage.h>

static int YYVideoCallBack(uint8_t* data, int width, int height) {
    NSData *videoData = [NSData dataWithBytes:data length:width * height * 4];
    [NSNotificationCenter.defaultCenter postNotificationName:@"VIDEOCABACK" object:videoData userInfo:@{@"width" : @(width), @"height" : @(height)}];
    return 0;
}

@interface TTTLiveViewController ()<TTTRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *anchorPlayer;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitBtn;
@property (nonatomic, strong) CIContext *temporaryContext;

@end

@implementation TTTLiveViewController {
    EAGLContext* _context;
    CameraUtil* _cameraUtil;
    CGSize _captureSize;
    EffectRender* _render;
    OF_FrameData _frameData;
    int _screenWidth;
    int _screenHeight;
    float _edgeBottom;
    UIView* _bottomTab;
    UIView* _beautyView;
    BeautyEffectPanel* _beautyPanel;
    UIView* _filterView;
    FilterEffectPanel* _filterPanel;
    UIView* _stickerView;
    StickerEffectPanel* _stickerPanel;
    UIImageView* _focusImage;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    TTTRtcManager.manager.rtcEngine.delegate = self;
    [self initGLContext];
    [self initRender];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(yy_videoCallback:) name:@"VIDEOCABACK" object:nil];
#warning mark - 注意当前继承自GLKViewController
}

- (void)yy_videoCallback:(NSNotification *)note {
    NSData *data = note.object;
    int width = [note.userInfo[@"width"] intValue];
    int height = [note.userInfo[@"height"] intValue];
    
    TTTRtcVideoFrame *frame = [[TTTRtcVideoFrame alloc] init];
    frame.format = TTTRtc_VideoFrameFormat_RGBA;
    frame.strideInPixels = width;
    frame.height = height;
    frame.dataBuffer = data;
    [TTTRtcManager.manager.rtcEngine pushExternalVideoFrame:frame];
}

- (void)initRender {
    // replace to your serial number
    NSString* ofSerialNumber = @"a4b6c276-a314-11e9-9b8d-525400ff498b";
    NSString* ofLicenseName = @"of_offline_license.license";
    
    NSArray* documentsPathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = [documentsPathArr lastObject];
    NSString* ofLicensePath = [NSString stringWithFormat:@"%@/%@", documentPath, ofLicenseName];
    OF_Result checkResult = OF_CheckSerialNumber([ofSerialNumber UTF8String], [ofLicensePath UTF8String]);
    if (checkResult != OF_Result_Success) {
        NSLog(@"check orange filter license failed");
    }
    
    _captureSize = CGSizeMake(720, 1280);
    _cameraUtil = [[CameraUtil alloc] initWithGLContext:_context captureSize:AVCaptureSessionPreset1280x720];
    
    int width = (int) (self.view.bounds.size.width * self.view.contentScaleFactor);
    int height = (int) (self.view.bounds.size.height * self.view.contentScaleFactor);
    const char* dataPath = [[[NSBundle mainBundle] bundlePath] UTF8String];
    _render = new EffectRender(width, height, dataPath);
    _render->video_init(&YYVideoCallBack);
    
    if (_render->GetContext() != OF_INVALID_HANDLE) {
        [self initUI];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^() {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"" message:@"OrangeFilter SDK初始化失败，请检查授权是否过期。" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:TRUE completion:nil];
        });
    }
}


- (void)initGLContext {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (_context == nil) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    GLKView* view = (GLKView*) self.view;
    view.context = _context;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
    view.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
    
    [EAGLContext setCurrentContext:_context];
}

- (void)initUI {
    CGSize size = [[UIScreen mainScreen] bounds].size;
    _screenWidth = (int) size.width;
    _screenHeight = (int) size.height;
    
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets edge = UIApplication.sharedApplication.delegate.window.safeAreaInsets;
        _edgeBottom = edge.bottom;
    } else {
        _edgeBottom = 0;
    }
    
    const float tabH = 40;
    float tabHEdge = tabH + _edgeBottom;
    _bottomTab = [[UIView alloc] initWithFrame:CGRectMake(0, _screenHeight - tabHEdge, _screenWidth, tabHEdge)];
    _bottomTab.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
    [self.view addSubview:_bottomTab];
    
    UIView* tab = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, tabH)];
    [_bottomTab addSubview:tab];
    
    NSMutableArray* subviews = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; ++i) {
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(_screenWidth / 4 * i, 0, _screenWidth / 4, tab.frame.size.height)];
        label.font = [UIFont systemFontOfSize:17];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        [tab addSubview:label];
        [subviews addObject:label];
    }
    
    UILabel* beauty = subviews[0];
    UILabel* filter = subviews[1];
    UILabel* sticker = subviews[2];
    UILabel* avatar = subviews[3];
    
    [beauty setText:@"美颜"];//美颜
    beauty.userInteractionEnabled = TRUE;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBeauty)];
    [beauty addGestureRecognizer:tap];
    
    [filter setText:@"滤镜"];//滤镜
    filter.userInteractionEnabled = TRUE;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickFilter)];
    [filter addGestureRecognizer:tap];
    
    [sticker setText:@"贴纸"];//贴纸
    sticker.userInteractionEnabled = TRUE;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickSticker)];
    [sticker addGestureRecognizer:tap];
    
    [avatar setText:@""];//虚拟角色
    avatar.userInteractionEnabled = TRUE;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickAvatar)];
    [avatar addGestureRecognizer:tap];
    
    const float panelHeight = 250;
    
    // beauty
    _beautyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    [_beautyView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
    _beautyView.userInteractionEnabled = TRUE;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBeautyView)];
    [_beautyView addGestureRecognizer:tap];
    
    _beautyPanel = [[BeautyEffectPanel alloc] initWithFrame:CGRectMake(0, _screenHeight - panelHeight, _screenWidth, panelHeight) andContext:_render->GetContext()];
    [_beautyView addSubview:_beautyPanel];
    
    _render->SetBeautyUtil([_beautyPanel getBeautyUtil]);
    
    // filter
    _filterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    [_filterView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
    _filterView.userInteractionEnabled = TRUE;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickFilterView)];
    [_filterView addGestureRecognizer:tap];
    
    _filterPanel = [[FilterEffectPanel alloc] initWithFrame:CGRectMake(0, _screenHeight - panelHeight, _screenWidth, panelHeight) andContext:_render->GetContext()];
    [_filterView addSubview:_filterPanel];
    
    _render->SetFilterUtil([_filterPanel getFilterUtil]);
    
    // sticker
    _stickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _screenWidth, _screenHeight)];
    [_stickerView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
    _stickerView.userInteractionEnabled = TRUE;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickStickerView)];
    [_stickerView addGestureRecognizer:tap];
    
    const float stickerTabH = 50;
    const float stickerLineH = 1;
    float stickerPanelH = stickerTabH + stickerLineH + panelHeight;
    _stickerPanel = [[StickerEffectPanel alloc] initWithFrame:CGRectMake(0, _screenHeight - stickerPanelH, _screenWidth, stickerPanelH) andContext:_render->GetContext()];
    [_stickerView addSubview:_stickerPanel];
    
    _render->SetStickerUtil([_stickerPanel getStickerUtil]);
}

- (void)clickBeauty {
    if (_beautyPanel != nil) {
        [_bottomTab setHidden:TRUE];
        [self.view addSubview:_beautyView];
        [_beautyPanel show];
    }
}

- (void)clickFilter {
    if (_filterPanel != nil) {
        [_bottomTab setHidden:TRUE];
        [self.view addSubview:_filterView];
        [_filterPanel show];
    }
}

- (void)clickSticker {
    if (_stickerPanel != nil) {
        [_bottomTab setHidden:TRUE];
        [self.view addSubview:_stickerView];
        [_stickerPanel show];
    }
}

- (void)clickAvatar {
    NSLog(@"clickAvatar");
}

- (void)clickBeautyView {
    [_beautyView removeFromSuperview];
    [_bottomTab setHidden:FALSE];
}

- (void)clickFilterView {
    [_filterView removeFromSuperview];
    [_bottomTab setHidden:FALSE];
}

- (void)clickStickerView {
    [_stickerView removeFromSuperview];
    [_bottomTab setHidden:FALSE];
}

- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    if ([_cameraUtil hasCameraTexture]) {
        int width = [_cameraUtil getCameraTextureWidth];
        int height = [_cameraUtil getCameraTextureHeight];
        
        memset(&_frameData, 0, sizeof(_frameData));
        _frameData.width = width;
        _frameData.height = height;
        _frameData.format = OF_PixelFormat_BGR32;
        _frameData.imageData = [_cameraUtil getCameraImageData];
        _frameData.widthStep = [_cameraUtil getCameraImageDataPitch];
        _frameData.timestamp = 0;
        _frameData.isUseCustomHarsLib = OF_FALSE;
        
        if (_frameData.isUseCustomHarsLib) {
            NSLog(@"Please add your own humanaction library!");
        }
        
        _render->Render([_cameraUtil getCameraTextureId], width, height, &_frameData);
    }
}


- (IBAction)exitChannel:(UIButton *)sender {
    [TTTRtcManager.manager.rtcEngine stopPreview];
    [TTTRtcManager.manager.rtcEngine leaveChannel:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TTTRtcEngineDelegate

//上报声音大小
- (void)rtcEngine:(TTTRtcEngineKit *)engine reportAudioLevel:(int64_t)userID audioLevel:(NSUInteger)audioLevel audioLevelFullRange:(NSUInteger)audioLevelFullRange {
//    NSLog(@"3TLog------%d", audioLevel);
}

//上报本地音视频上行码率
- (void)rtcEngine:(TTTRtcEngineKit *)engine reportRtcStats:(TTTRtcStats *)stats {
    _statsLabel.text = [NSString stringWithFormat:@"A-↑%ldkbps  V-↑%ldkbps", stats.txAudioKBitrate, stats.txVideoKBitrate];
}

- (void)rtcEngineConnectionDidLost:(TTTRtcEngineKit *)engine {
    NSLog(@"3TLog--:网络连接丢失，正在重连");
}

- (void)rtcEngineReconnectServerSucceed:(TTTRtcEngineKit *)engine {
    NSLog(@"3TLog--:重连成功");
}
    
- (void)rtcEngineReconnectServerTimeout:(TTTRtcEngineKit *)engine {
    NSLog(@"3TLog--:重连失败——退出房间");
    [self exitChannel:_exitBtn];
}
//被踢出房间
- (void)rtcEngine:(TTTRtcEngineKit *)engine didKickedOutOfUid:(int64_t)uid reason:(TTTRtcKickedOutReason)reason {
    NSString *errorInfo = @"";
    switch (reason) {
        case TTTRtc_KickedOut_PushRtmpFailed:
            errorInfo = @"rtmp推流失败";
            break;
        case TTTRtc_KickedOut_ReLogin:
            errorInfo = @"重复登录";
            break;
        case TTTRtc_KickedOut_NewChairEnter:
            errorInfo = @"其他人以主播身份进入";
            break;
        default:
            errorInfo = @"未知错误";
            break;
    }
    NSLog(@"3TLog--:%@", errorInfo);
    [self exitChannel:_exitBtn];
}
@end
