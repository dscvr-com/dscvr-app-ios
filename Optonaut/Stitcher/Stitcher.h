#import <Foundation/Foundation.h>
#include "CommonExternal.h"

@interface Stitcher : NSObject
- (struct ImageBuffer)getLeftResult;
- (struct ImageBuffer)getRightResult;
- (void)clear;
- (bool)hasUnstitchedRecordings;
- (void)setProgressCallback:(bool(^)(float))progressHandler;

@end