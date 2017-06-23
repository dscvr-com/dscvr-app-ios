//
//  ExifHelper.h
//  DSCVR
//
//  Created by Emanuel Jöbstl on 23/06/2017.
//  Copyright © 2017 Optonaut. All rights reserved.
//

#ifndef ExifHelper_h
#define ExifHelper_h

@interface ExifHelper : NSObject

+ (void)addPanoExifData:(NSString*)path:(int)width:(int)height;
@end


#endif /* ExifHelper_h */
