#import <Foundation/Foundation.h>
#include "CommonExternal.h"

@interface Stitcher : NSObject
- (struct ImageBuffer)getLeftResult;
- (struct ImageBuffer)getRightResult;
- (NSArray<NSValue*>*)getCubeFaces:(struct ImageBuffer)erBuf;
- (void)clear;
- (bool)hasUnstitchedRecordings;
- (bool)hasData;
- (void)setProgressCallback:(bool(^)(float))progressHandler;
@end
