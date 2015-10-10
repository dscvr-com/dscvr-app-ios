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
#include "progressCallback.hpp"

@implementation Stitcher {
@private
    optonaut::ProgressCallbackAccumulator* callback;
    optonaut::ProgressCallback* callbackWrapper;
}

struct StitcherCancellation {

};

-(id)init {
    self = [super init];
    self->callback = NULL;
    return self;
}
- (void)setProgressCallback:(bool(^)(float))progressHandler {
    if(callback != NULL) {
        delete callback;
        delete callbackWrapper;
    }
    callbackWrapper = new optonaut::ProgressCallback(
                             [progressHandler](float progress) -> bool {
                                 if(!progressHandler(progress)) {
                                     throw StitcherCancellation();
                                 }
                                 
                                 return true;
                             }
                         );
    callback = new optonaut::ProgressCallbackAccumulator(*callbackWrapper, {0.5f, 0.5f});
}
- (ImageBuffer)getLeftResult {
    
    optonaut::Stitcher stitcher(Stores::left);
    
    ImageBuffer result;
    
    try {
        result = CVMatToImageBuffer(stitcher.Finish(callback->At(0))->image.data);
    } catch (StitcherCancellation c) { }
    return result;
}
- (ImageBuffer)getRightResult {
    optonaut::Stitcher stitcher(Stores::right);
    
    ImageBuffer result;
    
    try {
        return CVMatToImageBuffer(stitcher.Finish(callback->At(1))->image.data);
    } catch (StitcherCancellation c) { }
    return result;
}
- (bool)hasUnstitchedRecordings {
    return Stores::left.HasUnstitchedRecording() || Stores::right.HasUnstitchedRecording();
}
- (void)clear {
    if(callback != NULL) {
        delete callback;
        delete callbackWrapper;
        callback = NULL;
    }

    Stores::left.Clear();
    Stores::right.Clear();
}
@end