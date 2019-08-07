#import "CameraUtil.h"

@interface CameraUtil () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    BOOL _frontCamera;
    CVPixelBufferRef _pixelBuffer;
    dispatch_queue_t _queue;
    CVPixelBufferRef _renderBuffer;
}

@property (nonatomic) AVCaptureSession* cameraSession;
@property (nonatomic) AVCaptureDeviceDiscoverySession* deviceDiscoverySession;
@property (nonatomic) AVCaptureDevice* cameraDevice;
@property (nonatomic) AVCaptureDeviceInput* cameraInput;
@property (nonatomic) AVCaptureVideoDataOutput* cameraOutput;

@end

@implementation CameraUtil

- (CVPixelBufferRef) getCameraPixelBuffer
{
    return _pixelBuffer;
}

- (void) releasePixelBuffer
{
    CVPixelBufferRelease(_pixelBuffer);
    _pixelBuffer = nil;
}

- (id)initWithCaptureSize:(AVCaptureSessionPreset)size
{
    self = [super init];
    
    BOOL frontCamera = TRUE;
    
    self.cameraSession = [[AVCaptureSession alloc] init];
    self.deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position: frontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
    [self.cameraSession setSessionPreset:size];
    
    [self selectCamera:frontCamera];
    
    return self;
}

- (void)dealloc {
    if (_pixelBuffer)
    {
        CVPixelBufferRelease(_pixelBuffer);
    }
}

- (void)selectCamera:(BOOL)front
{
    if ([self.cameraSession isRunning])
    {
        [self.cameraSession stopRunning];
    }
    if (self.cameraInput)
    {
        [self.cameraSession removeInput:self.cameraInput];
    }
    if (self.cameraOutput)
    {
        [self.cameraSession removeOutput:self.cameraOutput];
    }
    
    [self.cameraSession beginConfiguration];
    
    NSArray<AVCaptureDevice*>* devices = self.deviceDiscoverySession.devices;
    
    for (AVCaptureDevice* device in devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if (device.position == front ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)
            {
                self.cameraDevice = device;
                _frontCamera = front;
                break;
            }
        }
    }
    
    self.cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.cameraDevice error:nil];
    [self.cameraSession addInput:self.cameraInput];
    
    self.cameraOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.cameraSession addOutput:self.cameraOutput];
    
    AVCaptureConnection* connection = [self.cameraOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoMirrored:front];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [self.cameraOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.cameraOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
//    [self.cameraOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if (!_queue)
    {
        _queue = dispatch_queue_create("video_cap", NULL);
    }
    [self.cameraOutput setSampleBufferDelegate:self queue:_queue];
    
    [self.cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 24)];
    [self.cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 24)];
    
    [self.cameraSession commitConfiguration];
    [self.cameraSession startRunning];
}

- (void)focusAuto
{
    NSError *error;
    if ([self.cameraDevice lockForConfiguration:&error])
    {
        if ([self.cameraDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        {
            [self.cameraDevice setFocusPointOfInterest:CGPointMake(0.5, 0.5)];
            [self.cameraDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if ([self.cameraDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure ])
        {
            [self.cameraDevice setExposurePointOfInterest:CGPointMake(0.5, 0.5)];
            [self.cameraDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        
        [self.cameraDevice unlockForConfiguration];
    }
}

- (void)focusAtPoint:(CGPoint)point
{
    NSError *error;
    if ([self.cameraDevice lockForConfiguration:&error])
    {
        //对焦模式和对焦点
        if ([self.cameraDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus])
        {
            [self.cameraDevice setFocusPointOfInterest:point];
            [self.cameraDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //曝光模式和曝光点
        if ([self.cameraDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose ])
        {
            [self.cameraDevice setExposurePointOfInterest:point];
            [self.cameraDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.cameraDevice unlockForConfiguration];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFRetain(sampleBuffer);
    _pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferRef buffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (_renderBuffer) {
        if ([_delegate respondsToSelector:@selector(camera:output:)]) {
            [_delegate camera:self output:_renderBuffer];
        }
    }
}


-(void)renderDone:(CVPixelBufferRef)buffer {
    _renderBuffer = buffer;
}
@end
