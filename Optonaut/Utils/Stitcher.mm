#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>

#include "pipeline.hpp"
#include "intrinsics.hpp"
#include "Stitcher.h"

@implementation IosPipeline {
@private
    optonaut::Pipeline* pipe;
}

-(id)init {
    self = [super init];
    self->pipe = new optonaut::Pipeline(optonaut::Pipeline::iosBase, optonaut::Pipeline::iosZero, optonaut::iPhone6Intrinsics);
    return self;
}

+ (void)Push:(GLKMatrix4)extrinsics :(GLKMatrix3)intrinsics :(ImageBuffer*)image {
    
}
+ (GLKMatrix4)GetCurrentRotation {
    return GLKMatrix4MakeWithArray(NULL);
}
+ (bool)IsPreviewImageValialble {
    return false;
}
+ (ImageBuffer*)GetPreviewImage {
    return NULL;
}
+ (void)FreeImageBuffer:(ImageBuffer*)toFree {
    
}
+ (NSArray<SelectionPoint*>*)GetSelectionPoints {
    return NULL;
}
+ (void)DisableSelectionPoint:(SelectionPoint*)toDisable {
    
}
@end
