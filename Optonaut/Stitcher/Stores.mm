#import <Foundation/foundation.h>
#include "Stores.h"

optonaut::CheckpointStore MakeStore(std::string path) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *tempPath = [[paths objectAtIndex:0] stringByAppendingString:@"/tmp/"];
    
    return optonaut::CheckpointStore(std::string([tempPath UTF8String]) + path + "/", std::string([tempPath UTF8String]) + "shared/");
}

optonaut::CheckpointStore Stores::left = MakeStore("left");
optonaut::CheckpointStore Stores::right = MakeStore("right");
