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
#include "projection.hpp"
#include "panoramaBlur.hpp"

@implementation Stitcher {
@private
    optonaut::ProgressCallbackAccumulator* callback;
    optonaut::ProgressCallback* callbackWrapper;
}

struct StitcherCancellation {

};

-(NSArray<NSValue*>*)blurAndGetCubeFaces:(struct ImageBuffer)erBuf {
    
    cv::Mat sphere = ImageBufferToCVMat(erBuf);
    cv::Mat blurred;
    optonaut::PanoramaBlur panoBlur(sphere.size(), cv::Size(sphere.cols, std::max(sphere.cols / 2, sphere.rows)));
    panoBlur.Blur(sphere, blurred);
    sphere.release();

    
    int width = blurred.cols / 4; // That's as good as it gets.

    NSMutableArray<NSValue*>* cubeFaces = [[NSMutableArray<NSValue*> alloc] init];
    
    for(int i = 0; i < 6; i++) {
        Mat m;
        optonaut::CreateCubeMapFace(blurred, m, i, width, width);
        ImageBuffer buf = CVMatToImageBuffer(m);
        NSValue* conv = [NSValue valueWithBytes:&buf objCType:@encode(ImageBuffer)];
        [cubeFaces addObject:conv];
    }
    
    return [NSArray<NSValue*> arrayWithArray:cubeFaces];
}

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

- (struct ImageBuffer)getLeftResult {
    
    optonaut::Stitcher stitcher(Stores::left);
    
    try {
        cv::Mat sphere = stitcher.Finish(callback->At(0))->image.data;
        return CVMatToImageBuffer(sphere);
    } catch (StitcherCancellation c) { }

    return MakeImageBuffer();
    
}

- (struct ImageBuffer)getRightResult {
    optonaut::Stitcher stitcher(Stores::right);
    
    try {
        cv::Mat sphere = stitcher.Finish(callback->At(0))->image.data;
        return CVMatToImageBuffer(sphere);
    } catch (StitcherCancellation c) { }
    return MakeImageBuffer();
}

- (bool)hasUnstitchedRecordings {
    return Stores::left.HasUnstitchedRecording() && Stores::right.HasUnstitchedRecording();
}
- (bool)hasData {
    return Stores::left.HasData() || Stores::right.HasData();
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
