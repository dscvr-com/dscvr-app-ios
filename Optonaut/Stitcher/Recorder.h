#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#include "CommonExternal.h"

@interface SelectionPoint : NSObject {
    @public
        GLKMatrix4 _extrinsics;
        uint32_t _globalId;
        uint32_t _ringId;
        uint32_t _localId;
}
@property uint32_t globalId;
@property uint32_t ringId;
@property uint32_t localId;
@property GLKMatrix4 extrinsics;
@end

typedef NS_ENUM(NSInteger, RecorderMode) {
    TinyDebug,
    Truncated,
    Center,
    Full
};

struct ExposureInfo {
    uint32_t iso;
    double exposureTime;
    AVCaptureWhiteBalanceGains gains;
};

@interface SelectionPointIterator : NSObject
- (bool)HasMore;
- (SelectionPoint*)Next;
@end

@interface Recorder : NSObject

//This interface takes matrices in SCNSpace and also gives them back in SCNSpace.
//It's that simple.

+ (void)enableDebug:(NSString*)path;
+ (void)disableDebug;
+ (NSString*)getVersion;
+ (GLKMatrix3)getIPhone6Intrinsics;
+ (GLKMatrix3)getIPhone5Intrinsics;
+ (void)freeImageBuffer:(struct ImageBuffer)toFree;

- (id)init:(RecorderMode)recorderMode;
- (void)push:(GLKMatrix4)extrinsics :(struct ImageBuffer)image :(struct ExposureInfo)exposure :(AVCaptureWhiteBalanceGains)gains;
- (GLKMatrix4)getCurrentRotation;
- (SelectionPointIterator*)getSelectionPoints;
- (SelectionPoint*)lastKeyframe;
- (void)setIdle:(bool)isIdle;
- (bool)isIdle;
- (bool)hasStarted;
- (bool)areAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b;
- (GLKMatrix4)getNextKeyframePosition;
- (bool)isFinished;
- (double)getDistanceToNextKeyframe;
- (GLKVector3)getAngularDistanceToNextKeyframe;
- (uint32_t)getRecordedImagesCount;
- (uint32_t)getImagesToRecordCount;
- (void)finish;
- (void)dispose;
- (bool)isDisposed;
- (struct ExposureInfo)getExposureHint;
- (bool)previewAvailable;
- (struct ImageBuffer)getPreviewImage;

@end
