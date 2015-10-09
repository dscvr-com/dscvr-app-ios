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

+ (NSString*)GetVersion;

- (void)Push:(GLKMatrix4)extrinsics :(struct ImageBuffer)image;
- (GLKMatrix4)GetCurrentRotation;
- (void)FreeImageBuffer:(struct ImageBuffer)toFree;
- (SelectionPointIterator*)GetSelectionPoints;
- (SelectionPoint*)CurrentPoint;
- (SelectionPoint*)PreviousPoint;
- (void)EnableDebug:(NSString*)path;
- (void)SetIdle:(bool)isIdle;
- (bool)IsIdle;
- (bool)AreAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b;
- (GLKMatrix4)GetBallPosition;
- (bool)IsFinished;
- (double)GetDistanceToBall;
- (GLKVector3)GetAngularDistanceToBall;
- (uint32_t)GetRecordedImagesCount;
- (uint32_t)GetImagesToRecordCount;
- (void)Finish;
- (void)Dispose;
- (bool)IsDisposed;

@end
