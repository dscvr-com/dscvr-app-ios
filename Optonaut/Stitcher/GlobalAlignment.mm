#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>
#define OPTONAUT_TARGET_PHONE

#include "stitcher.hpp"
#include "GlobalAlignment.hpp"
#include "Stores.h"
#include "CommonInternal.h"
#include "progressCallback.hpp"
#include "projection.hpp"
#include "panoramaBlur.hpp"

@implementation GlobalAlignment: NSObject

-(id)init {
    self = [super init];
    return self;
};

struct ConversionCancellation {
};

-(void)finish {
    optonaut::GlobalAlignment globalAlignment(Stores::post, Stores::left, Stores::right);
    
    try {
        globalAlignment.Finish();
    
    } catch (ConversionCancellation c) { }
};
@end
