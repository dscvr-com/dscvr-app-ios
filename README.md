# DSCVR iOS App

Repository for the DSCVR (former Optonaut) iOS Application. 

The applications wraps the image processing component (`online-stitcher`, found [here]()), and adds the infrastucture necassary for recording and viewing on iOS.

## Project Structure

The project consists of the following modules: 

* *APIModel* Legacy code for former community feature. 
* *Database* Code to save recordings. 
* *Models* Data model classes. 
* *MotorServices* Discovery of bluetooth devices and control of the Orbit360 bluetooth base. 
* *Extensions* Extensions to other classes, mainly for convenience. 
* *Services* Service singletons for stitching, configuration and parameter management. 
* *Stitcher* Bridging code to the image stitcher. 
* *Utils* Utility classes. 
* *Views* The application's UI components. 
* *Vendor* 3rd party code and components, including distortion shaders and code for head tracking. 

### Carthage Dependencies

See `Cartfile` to manage dependencies and run `carthage update --platform iOS` to install or update.

### External Dependencies

Download and copy the needed frameworks into `Carthage/Build/iOS` by hand.

* [OpenCV 3](http://opencv.org/downloads.html)
  * `opencv2.framework`
