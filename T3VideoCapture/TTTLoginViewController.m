//
//  TTTLoginViewController.m
//  T3VideoCapture
//
//  Created by Work on 2019/7/3.
//  Copyright © 2019 yanzhen. All rights reserved.
//

#import "TTTLoginViewController.h"
#import "TTTRtcManager.h"

@interface TTTLoginViewController ()<TTTRtcEngineDelegate>
@property (weak, nonatomic) IBOutlet UITextField *roomTF;
@property (nonatomic, assign) int64_t uid;
@end

@implementation TTTLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _uid = arc4random() % 100000 + 1;
    int64_t roomID = [[NSUserDefaults standardUserDefaults] stringForKey:@"ENTERROOMID"].integerValue;
    if (roomID == 0) {
        roomID = arc4random() % 1000000 + 1;
    }
    _roomTF.text = [NSString stringWithFormat:@"%lld", roomID];
}

- (IBAction)joinChannel:(UIButton *)sender {
    if (_roomTF.text.length == 0) {
        NSLog(@"3TLog--:请输入正确的房间ID");
        return;
    }
    TTTRtcEngineKit *engine = TTTRtcManager.manager.rtcEngine;
    engine.delegate = self;
    //以单主播直播为例
    [engine setChannelProfile:TTTRtc_ChannelProfile_LiveBroadcasting];
    [engine setClientRole:TTTRtc_ClientRole_Anchor];
    //设置推流地址---可以不设置
    TTTPublisherConfigurationBuilder *builder = [[TTTPublisherConfigurationBuilder alloc] init];
    NSString *pushURL = [@"rtmp://push.3ttech.cn/sdk/" stringByAppendingFormat:@"%@", _roomTF.text];
    //通过拉流 rtmp://pull.3ttech.cn/sdk/123   ———和推流地址相对应房间号查看效果
    [builder setPublisherUrl:pushURL];
    [engine configPublisher:builder.build];
    //设置接近采集的分辨率(内部会自动设置码率和帧率)--参考枚举
    BOOL swapWH = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation);
    //以720P分辨率为例
    [engine setVideoProfile:TTTRtc_VideoProfile_720P swapWidthAndHeight:swapWH];
    [engine enableAudioVolumeIndication:1000 smooth:3];
    
    
    
    
    
    
    
    
    
    [engine setLocalVideoFrameCaptureFormat:TTTRtc_VideoFrameFormat_Texture isVideoSizeSameWithProfile:NO];
    
    
    
    
    
    
    
//    //外部美颜需要做的事情
    [engine setExternalVideoSource:YES useTexture:NO];
    //加入房间
    [engine joinChannelByKey:nil channelName:_roomTF.text uid:_uid joinSuccess:nil];
}
    
#pragma mark - TTTRtcEngineDelegate
- (void)rtcEngine:(TTTRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(int64_t)uid elapsed:(NSInteger)elapsed {
    //加入房间成功跳转页面
    [self performSegueWithIdentifier:@"LIVE" sender:nil];
}

//加入房间出现error
- (void)rtcEngine:(TTTRtcEngineKit *)engine didOccurError:(TTTRtcErrorCode)errorCode {
    NSString *errorInfo = @"";
    switch (errorCode) {
        case TTTRtc_Error_Enter_TimeOut:
        errorInfo = @"超时,10秒未收到服务器返回结果";
        break;
        case TTTRtc_Error_Enter_Failed:
        errorInfo = @"该直播间不存在";
        break;
        case TTTRtc_Error_Enter_BadVersion:
        errorInfo = @"版本错误";
        break;
        case TTTRtc_Error_InvalidChannelName:
        errorInfo = @"Invalid channel name";
        break;
        case TTTRtc_Error_Enter_NoAnchor:
        errorInfo = @"房间内无主播";
        break;
        default:
        errorInfo = [NSString stringWithFormat:@"未知错误：%zd",errorCode];
        break;
    }
    NSLog(@"3TLog--:%@", errorInfo);
}
@end
