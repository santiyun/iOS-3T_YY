#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>

@class CameraUtil;
@protocol CameraUtilDelegate <NSObject>

- (void)camera:(CameraUtil *)camera output:(CVPixelBufferRef)pixelBuffer;

@end

@interface CameraUtil : NSObject

@property (nonatomic, weak) id<CameraUtilDelegate> delegate;

- (id)initWithCaptureSize:(AVCaptureSessionPreset)size;
- (CVPixelBufferRef) getCameraPixelBuffer;
- (void)releasePixelBuffer;
- (void)focusAuto;
- (void)focusAtPoint:(CGPoint)point;
- (void)renderDone:(CVPixelBufferRef)buffer;

@end
