# optonaut-app-ios
Repository for the iOS optonaut app

## Dependencies

### Carthage Dependencies

See `Cartfile` to manage dependencies and run `carthage update --platform iOS` to install or update.

### External Dependencies (Non-Carthage)

Download and copy the needed frameworks into `Carthage/Build/iOS` by hand. I know this sucks.

* [OpenCV 3](http://opencv.org/downloads.html)
  * `opencv2.framework`
* [Crashlytics](https://fabric.io/kits/ios/crashlytics) - Install via Fabric OSX tool
  * `Crashlytics.framework`
  * `Fabric.framework`
