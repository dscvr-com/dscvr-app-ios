#include "Stitcher.h"

#include <opencv2/opencv.hpp>
#include "wrapper.hpp"

@implementation Stitcher : NSObject

+ (void)Push:(double [])extrinsics :(double [])intrinsics :(void *)image :(int)width :(int)height :(double [])newExtrinsics :(int)id_ {
    optonaut::Push(extrinsics, intrinsics, (unsigned char *) image, width, height, newExtrinsics, id_);
}

@end
