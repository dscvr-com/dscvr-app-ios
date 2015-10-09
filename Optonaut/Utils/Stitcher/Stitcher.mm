#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>
#define OPTONAUT_TARGET_PHONE

#include "stitcher.hpp"
#include "Stitcher.h"
#include "Stores.h"
#include "CommonInternal.h"

@implementation Stitcher {
@private
    
}

-(id)init {
    self = [super init];
    return self;
}
- (ImageBuffer)GetLeftResult {
    
    optonaut::Stitcher stitcher(Stores::left);
    
    return CVMatToImageBuffer(stitcher.Finish()->image.data);
}
- (ImageBuffer)GetRightResult {
    optonaut::Stitcher stitcher(Stores::right);
    
    return CVMatToImageBuffer(stitcher.Finish()->image.data);
}
- (bool)HasUnstitchedRecordings {
    return Stores::left.HasUnstitchedRecording() || Stores::right.HasUnstitchedRecording();
}
- (void)Clear {
    Stores::left.Clear();
    Stores::right.Clear();
}
@end