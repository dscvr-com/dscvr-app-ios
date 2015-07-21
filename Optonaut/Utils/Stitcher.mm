#include "Stitcher.h"

#include <opencv2/opencv.hpp>
#include "wrapper.hpp"

@implementation Stitcher : NSObject

+ (void)push:(double [])extrinsics :(double [])intrinsics :(void *)image :(int)width :(int)height :(double [])newExtrinsics {
    optonaut::wrapper::Push(extrinsics, intrinsics, (unsigned char *) image, width, height, newExtrinsics, 0);
}

@end
