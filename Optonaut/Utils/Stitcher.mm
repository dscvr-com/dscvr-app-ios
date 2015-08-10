#include "Stitcher.h"

#include <opencv2/opencv.hpp>
#include "wrapper.hpp"

#include <Foundation/foundation.h>

@implementation Stitcher : NSObject

+ (bool)push:(double [])extrinsics :(double [])intrinsics :(void *)image :(int)width :(int)height :(double [])newExtrinsics :(int)frameCount {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    std::string *dirp = new std::string([dir UTF8String]);
    
    return optonaut::wrapper::Push(extrinsics, intrinsics, (unsigned char *) image, width, height, newExtrinsics, frameCount, *dirp);
}

@end
