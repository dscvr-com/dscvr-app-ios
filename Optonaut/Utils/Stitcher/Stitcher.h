#import <Foundation/Foundation.h>
#include "CommonExternal.h"

@interface Stitcher : NSObject
- (struct ImageBuffer)GetLeftResult;
- (struct ImageBuffer)GetRightResult;
- (void)Clear;
- (bool)HasUnstitchedRecordings;

@end