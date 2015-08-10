#import <Foundation/Foundation.h>

@interface Stitcher : NSObject

+ (bool)push:(double [])extrinsics :(double [])intrinsics :(void *)image :(int)width :(int)height :(double [])newExtrinsics :(int)frameCount;

@end