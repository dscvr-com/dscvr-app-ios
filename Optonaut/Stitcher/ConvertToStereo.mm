#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>
#define OPTONAUT_TARGET_PHONE

#include "stitcher.hpp"
#include "ConvertToStereo.h"
#include "convertToStereo.hpp"
#include "Stores.h"
#include "CommonInternal.h"
#include "progressCallback.hpp"
#include "projection.hpp"
#include "panoramaBlur.hpp"

@implementation ConvertToStereo

-(id)init {
    self = [super init];
    return self;
};

struct ConversionCancellation {
};

-(void)convert {
    optonaut::ConvertToStereo convertToStereo(Stores::post, Stores::left, Stores::right);
    
    try {
        convertToStereo.Finish();
    
    } catch (ConversionCancellation c) { }
};
@end