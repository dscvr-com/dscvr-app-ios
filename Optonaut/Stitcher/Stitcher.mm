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

-(NSArray<NSValue*>*)getCubeFaces:(cv::Mat)sphere {
    int width = sphere.cols / 4;

    NSMutableArray<NSValue*>* cubeFaces = [[NSMutableArray<NSValue*> alloc] init];
    
    for(int i = 0; i < 6; i++) {
        Mat m;
        optonaut::CreateCubeMapFace(sphere, m, i, width, width);
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
- (NSArray<NSValue*>*)getLeftResult {
    
    optonaut::Stitcher stitcher(Stores::left);
    
    NSArray<NSValue*>* result;
    
    try {
        cv::Mat sphere = stitcher.Finish(callback->At(0), "debug/left")->image.data;
        cv::Mat blurred;
        optonaut::PanoramaBlur panoBlur(sphere.size(), cv::Size(sphere.cols, std::max(sphere.cols / 2, sphere.rows)));
        panoBlur.Blur(sphere, blurred);
        sphere.release();
        
        return [self getCubeFaces:blurred];
    } catch (StitcherCancellation c) { }
    return result;
}
- (NSArray<NSValue*>*)getRightResult {
    optonaut::Stitcher stitcher(Stores::right);
    
    NSArray<NSValue*>* result;
    
    try {
        cv::Mat sphere = stitcher.Finish(callback->At(1), "debug/right")->image.data;
        cv::Mat blurred;
        optonaut::PanoramaBlur panoBlur(sphere.size(), cv::Size(sphere.cols, std::max(sphere.cols / 2, sphere.rows)));
        panoBlur.Blur(sphere, blurred);
        sphere.release();
        
        
        return [self getCubeFaces:blurred];
    } catch (StitcherCancellation c) { }
    return result;
}
- (bool)hasUnstitchedRecordings {
    return Stores::post.HasUnstitchedRecording();
}
- (void)clear {
    if(callback != NULL) {
        delete callback;
        delete callbackWrapper;
        callback = NULL;
    }

    Stores::left.Clear();
    Stores::right.Clear();
   // Stores::post.Clear();
}
@end