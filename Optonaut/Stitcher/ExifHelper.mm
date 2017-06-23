//
//  ExifHelper.m
//  DSCVR
//
//  Created by Emanuel Jöbstl on 23/06/2017.
//  Copyright © 2017 Optonaut. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ExifHelper.h"
#include <exiv2/exiv2.hpp>

@implementation ExifHelper
+ (void)addPanoExifData:(NSString*)path:(int)width:(int)height {
    
    std::string strPath = std::string([path UTF8String]);
    
    Exiv2::XmpProperties::registerNs("http://ns.google.com/photos/1.0/panorama/", "GPano");
    
    Exiv2::XmpData xmpData;
    
    xmpData["Xmp.GPano.UsePanoramaViewer"] = boolean_t(true);
    xmpData["Xmp.GPano.ProjectionType"] = "equirectangular";
    xmpData["Xmp.GPano.CaptureSoftware"] = "DSVCR 360";
    xmpData["Xmp.GPano.StitchingSoftware"] = "DSVCR 360";
    xmpData["Xmp.GPano.FullPanoWidthPixels"] = uint32_t(width);
    xmpData["Xmp.GPano.FullPanoHeightPixels"] = uint32_t(width / 2);
    xmpData["Xmp.GPano.CroppedAreaLeftPixels"] = uint32_t(0);
    xmpData["Xmp.GPano.CroppedAreaTopPixels"] = uint32_t((width - height) / 2);
    xmpData["Xmp.GPano.CroppedAreaImageWidthPixels"] = uint32_t((width - height) / 2);
    xmpData["Xmp.GPano.CroppedAreaImageHeightPixels"] = uint32_t((width - height) / 2);
    
    Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(strPath);
    assert(image.get() != 0);
    image->setXmpData(xmpData);
    image->writeMetadata();
}
@end
