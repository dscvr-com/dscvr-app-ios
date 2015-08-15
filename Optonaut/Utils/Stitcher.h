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

- (void)Push:(GLKMatrix4)extrinsics :(ImageBuffer)image;
- (GLKMatrix4)GetCurrentRotation;
- (bool)IsPreviewImageValialble;
- (ImageBuffer)GetPreviewImage;
- (void)FreeImageBuffer:(ImageBuffer)toFree;
- (NSArray<NSValue*>*)GetSelectionPoints;
- (void)DisableSelectionPoint:(SelectionPoint)toDisable;

@end