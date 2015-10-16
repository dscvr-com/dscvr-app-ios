#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include "Sensors/HeadTracker.hpp"
#include "HeadTracker.h"


@implementation HeadTracker  {
@private
    CardboardSDK::HeadTracker tracker;
}
- (void)startTracking:(UIInterfaceOrientation)orientation {
    tracker.startTracking(orientation);
}
- (void)stopTracking {
    tracker.stopTracking();
}
- (GLKMatrix4)lastHeadView{
    return tracker.lastHeadView();
}
- (void)updateDeviceOrientation:(UIInterfaceOrientation)orientation{
    tracker.updateDeviceOrientation(orientation);
}

- (bool)neckModelEnabled {
    return tracker.neckModelEnabled();
}
- (void)setNeckModelEnabled:(bool)isIdle {
    tracker.setNeckModelEnabled(isIdle);
}
- (bool)isReady {
    return tracker.isReady();
}
@end
