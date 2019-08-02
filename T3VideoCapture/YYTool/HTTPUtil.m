#import "HTTPUtil.h"
#import <CommonCrypto/CommonDigest.h>

@implementation HTTPUtil

+ (void)request:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate callbackData:(void (^)(NSData* data, NSError* error))callback {
    const double timeout = 30;
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeout];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                callback(data, nil);
            });
        } else {
            if (error != nil) {
                callback(nil, error);
            }
        }
    }];
    [task resume];
}

+ (void)request:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate callbackJson:(void (^)(NSDictionary* json, NSError* error))callback {
    [HTTPUtil request:url sessionDelegate:delegate callbackData:^(NSData* data, NSError* error) {
        if (data != nil) {
            NSError* jsonErr = nil;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonErr];
            
            if (json != nil) {
                callback(json, nil);
            } else {
                callback(nil, jsonErr);
            }
        } else {
            if (error != nil) {
                callback(nil, error);
            }
        }
    }];
}

+ (void)request:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate file:(NSString*)path callbackFile:(void (^)(NSString* file, NSError* error))callback {
    [HTTPUtil request:url sessionDelegate:delegate callbackData:^(NSData* data, NSError* error) {
        if (data != nil) {
            BOOL success = [data writeToFile:path atomically:TRUE];
            if (success) {
                callback(path, nil);
            } else {
                NSLog(@"write file failed, path: %@", path);
            }
        } else {
            if (error != nil) {
                callback(nil, error);
            }
        }
    }];
}

+ (void)loadImage:(NSString*)url sessionDelegate:(id <NSURLSessionDelegate>)delegate to:(UIImageView*)view {
    unsigned char md5[16];
    const char* utf8 = [url UTF8String];
    CC_MD5(utf8, (CC_LONG) strlen(utf8), md5);
    NSString* md5Str = @"";
    for (int i = 0; i < 16; ++i) {
        md5Str = [NSString stringWithFormat:@"%@%02x", md5Str, md5[i]];
    }
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachesDir = [paths objectAtIndex:0];
    NSString* path = [NSString stringWithFormat:@"%@/%@.dat", cachesDir, md5Str];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSData* data = [NSData dataWithContentsOfFile:path];
        if (data != nil) {
            view.image = [UIImage imageWithData:data];
        } else {
            NSLog(@"read cached image file error, path: %@", path);
        }
    } else {
        [HTTPUtil request:url sessionDelegate:delegate callbackData:^(NSData* data, NSError* error) {
            if (data != nil) {
                view.image = [UIImage imageWithData:data];
                
                BOOL success = [data writeToFile:path atomically:TRUE];
                if (!success) {
                    NSLog(@"write file failed, path: %@", path);
                }
            } else {
                if (error != nil) {
                    NSLog(@"%@", error.localizedDescription);
                }
            }
        }];
    }
}

@end
