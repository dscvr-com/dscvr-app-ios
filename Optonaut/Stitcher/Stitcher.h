#import <Foundation/Foundation.h>
#include "CommonExternal.h"

@interface Stitcher : NSObject
- (NSArray<NSValue*>*)getLeftResult;
- (NSArray<NSValue*>*)getRightResult;
- (void)clear;
- (bool)hasUnstitchedRecordings;
- (void)setProgressCallback:(bool(^)(float))progressHandler;
- (struct ImageBuffer)getLeftEquirectangularResult;
- (struct ImageBuffer)getRightEquirectangularResult;
@end