#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

struct ImageBuffer {
    void* data;
    int width;
    int height;
};

struct SelectionPoint {
    GLKMatrix4 extrinsics;
    int id;
    int ringId;
    int localId;
};

@interface IosPipeline : NSObject

//This interface takes matrices in SCNSpace and also gives them back in SCNSpace.
//It's that simple.

+ (NSString*)GetVersion;

- (void)Push:(GLKMatrix4)extrinsics :(struct ImageBuffer)image;
- (GLKMatrix4)GetCurrentRotation;
- (GLKMatrix4)GetPreviewRotation;
- (bool)IsPreviewImageValialble;
- (struct ImageBuffer)GetPreviewImage;
- (void)FreeImageBuffer:(struct ImageBuffer)toFree;
- (NSArray<NSValue*>*)GetSelectionPoints;
- (struct SelectionPoint)CurrentPoint;
- (struct SelectionPoint)PreviousPoint;
- (void)EnableDebug:(NSString*)path;
- (struct ImageBuffer)GetLeftResult;
- (struct ImageBuffer)GetRightResult;
- (bool)AreAdjacent:(struct SelectionPoint)a and:(struct SelectionPoint)b;

@end