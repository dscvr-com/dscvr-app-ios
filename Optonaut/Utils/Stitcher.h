#import <Foundation/Foundation.h>

@interface Stitcher : NSObject

+ (void)Push:(double [])extrinsics :(double [])intrinsics :(void *)image :(int)width :(int)height :(double [])newExtrinsics :(int)id_;

@end