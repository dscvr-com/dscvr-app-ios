#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface ImageBuffer : NSObject
@property void* data;
@property int width;
@property int height;
@end

@interface SelectionPoint : NSObject
@property GLKMatrix4 extrinsics;
@property int id;
@property int ringId;
@property int localId;
@end

@interface IosPipeline : NSObject

//This interface takes matrices in SCNSpace and also gives them back in SCNSpace.
//It's that simple.

- (void)Push:(GLKMatrix4)extrinsics :(ImageBuffer*)image;
- (GLKMatrix4)GetCurrentRotation;
- (bool)IsPreviewImageValialble;
- (ImageBuffer*)GetPreviewImage;
- (void)FreeImageBuffer:(ImageBuffer*)toFree;
- (NSArray<SelectionPoint*>*)GetSelectionPoints;
- (void)DisableSelectionPoint:(SelectionPoint*)toDisable;

@end