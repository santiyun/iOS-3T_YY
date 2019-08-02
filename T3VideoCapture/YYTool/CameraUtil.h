#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>


@interface CameraUtil : NSObject

- (id)initWithGLContext:(EAGLContext*)context captureSize:(AVCaptureSessionPreset)size;
- (BOOL)hasCameraTexture;
- (int)getCameraTextureWidth;
- (int)getCameraTextureHeight;
- (GLuint)getCameraTextureId;
- (int)getCameraImageDataPitch;
- (uint8_t*)getCameraImageData;
- (void)focusAuto;
- (void)focusAtPoint:(CGPoint)point;

@end
