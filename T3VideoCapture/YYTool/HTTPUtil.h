#import <UIKit/UIKit.h>

@interface HTTPUtil : NSObject

+ (void)request:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate callbackData:(void(^)(NSData* data, NSError* error))callback;
+ (void)request:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate callbackJson:(void (^)(NSDictionary* json, NSError* error))callback;
+ (void)request:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate file:(NSString*)path callbackFile:(void (^)(NSString* file, NSError* error))callback;
+ (void)loadImage:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate to:(UIImageView*)view;

@end
