#import <Foundation/Foundation.h>

@interface Stitcher : NSObject

+ (void)push:(double [])extrinsics :(double [])intrinsics :(void *)image :(int)width :(int)height :(double [])newExtrinsics;

@end