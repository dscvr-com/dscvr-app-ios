#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


@interface HeadTracker : NSObject

- (void)startTracking:(UIInterfaceOrientation)orientation;
- (void)stopTracking;
- (GLKMatrix4)lastHeadView;
- (void)updateDeviceOrientation:(UIInterfaceOrientation)orientation;
- (bool)neckModelEnabled;
- (void)setNeckModelEnabled:(bool)isIdle;
- (bool)isReady;

@end
