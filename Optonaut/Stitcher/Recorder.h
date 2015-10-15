#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
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


@interface SelectionPointIterator : NSObject
- (bool)HasMore;
- (SelectionPoint*)Next;
@end

@interface Recorder : NSObject

//This interface takes matrices in SCNSpace and also gives them back in SCNSpace.
//It's that simple.

+ (NSString*)getVersion;
+ (void)freeImageBuffer:(struct ImageBuffer)toFree;

- (void)push:(GLKMatrix4)extrinsics :(struct ImageBuffer)image;
- (GLKMatrix4)getCurrentRotation;
- (SelectionPointIterator*)getSelectionPoints;
- (SelectionPoint*)currentPoint;
- (SelectionPoint*)previousPoint;
- (void)enableDebug:(NSString*)path;
- (void)setIdle:(bool)isIdle;
- (bool)isIdle;
- (bool)areAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b;
- (GLKMatrix4)getBallPosition;
- (bool)isFinished;
- (double)getDistanceToBall;
- (double)getExposureBias;
- (GLKVector3)getAngularDistanceToBall;
- (uint32_t)getRecordedImagesCount;
- (uint32_t)getImagesToRecordCount;
- (void)finish;
- (void)dispose;
- (bool)isDisposed;

@end
