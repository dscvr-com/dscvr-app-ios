#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

struct ImageBuffer {
        void* data;
        uint32_t width;
        uint32_t height;
};

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

@interface IosPipeline : NSObject

//This interface takes matrices in SCNSpace and also gives them back in SCNSpace.
//It's that simple.

+ (NSString*)GetVersion;

- (void)Push:(GLKMatrix4)extrinsics :(struct ImageBuffer)image;
- (GLKMatrix4)GetCurrentRotation;
- (GLKMatrix4)GetPreviewRotation;
- (bool)IsPreviewImageAvailable;
- (struct ImageBuffer)GetPreviewImage;
- (void)FreeImageBuffer:(struct ImageBuffer)toFree;
- (SelectionPointIterator*)GetSelectionPoints;
- (SelectionPoint*)CurrentPoint;
- (SelectionPoint*)PreviousPoint;
- (void)EnableDebug:(NSString*)path;
- (void)SetIdle:(bool)isIdle;
- (bool)IsIdle;
- (struct ImageBuffer)GetLeftResult;
- (struct ImageBuffer)GetRightResult;
- (bool)AreAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b;
- (bool)HasResults;
- (GLKMatrix4)GetBallPosition;
- (bool)IsFinished;
- (void)SetPreviewImageEnabled:(bool)enabled;
- (double)GetDistanceToBall;
- (GLKVector3)GetAngularDistanceToBall;
- (uint32_t)GetRecordedImagesCount;
- (uint32_t)GetImagesToRecordCount;
- (void)Finish;
- (void)Dispose;
- (bool)IsDisposed;

@end
