//
//  CommonExternal.c
//  DSCVR
//
//  Created by Emanuel Jöbstl on 30/06/2017.
//  Copyright © 2017 Optonaut. All rights reserved.
//

#import <Foundation/foundation.h>
#include "CommonExternal.h"

struct ImageBuffer MakeImageBuffer() {
    struct ImageBuffer buf;
    buf.data = 0;
    buf.width = 0;
    buf.height = 0;

    return buf;
}
