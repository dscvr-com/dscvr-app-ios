#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <vector>
#include <string>
#define OPTONAUT_TARGET_PHONE

#include "imageSink.hpp"
#include "storageSink.hpp"
//#include "stitcherSink.hpp"
#include "recorder.hpp"
#include "intrinsics.hpp"
#include "Recorder.h"
#include "Stores.h"
#include "CommonInternal.h"

int counter = 0;

@implementation SelectionPoint

@end

GLKMatrix4 CVMatToGLK4(const cv::Mat &m) {
    assert(m.cols == 4 && m.rows == 4 && m.type() == CV_64F);
    assert(sizeof(float) == 4);
    assert(sizeof(double) == 8);
    
    return GLKMatrix4Make((float)m.at<double>(0, 0), (float)m.at<double>(0, 1), (float)m.at<double>(0, 2), (float)m.at<double>(0, 3),
                          (float)m.at<double>(1, 0), (float)m.at<double>(1, 1), (float)m.at<double>(1, 2), (float)m.at<double>(1, 3),
                          (float)m.at<double>(2, 0), (float)m.at<double>(2, 1), (float)m.at<double>(2, 2), (float)m.at<double>(2, 3),
                          (float)m.at<double>(3, 0), (float)m.at<double>(3, 1), (float)m.at<double>(3, 2), (float)m.at<double>(3, 3));
}

GLKMatrix3 CVMatToGLK3(const cv::Mat &m) {
    assert(m.cols == 3 && m.rows == 3 && m.type() == CV_64F);
    assert(sizeof(float) == 4);
    assert(sizeof(double) == 8);
    
    return GLKMatrix3Make((float)m.at<double>(0, 0), (float)m.at<double>(0, 1), (float)m.at<double>(0, 2),
                          (float)m.at<double>(1, 0), (float)m.at<double>(1, 1), (float)m.at<double>(1, 2),
                          (float)m.at<double>(2, 0), (float)m.at<double>(2, 1), (float)m.at<double>(2, 2));
}

void GLK4ToCVMat(GLKMatrix4 m, cv::Mat &output) {
    cv::Mat tmp = cv::Mat(4, 4, CV_32F, m.m);
    tmp.convertTo(output, CV_64F);
}

GLKVector3 CVMatToGLK3Vec(const cv::Mat &m) {
    assert(m.cols == 1 && m.rows >= 3 && m.type() == CV_64F);
    
    return GLKVector3Make((float)m.at<double>(0, 0), (float)m.at<double>(1, 0), (float)m.at<double>(2, 0));
}

void ImageBufferToCVMat(ImageBuffer image, cv::Mat &output) {
    cv::cvtColor(cv::Mat(image.height, image.width, CV_8UC4, image.data), output, cv::COLOR_RGBA2RGB);
}

optonaut::InputImageRef ImageBufferToImageRef(ImageBuffer image) {
    optonaut::InputImageRef ref;
    ref.data = image.data;
    ref.width = image.width;
    ref.height = image.height;
    ref.colorSpace = optonaut::colorspace::RGBA;
    
    return ref;
}

CGImageRef CVMatToCGImage(const cv::Mat &input) {
    CGContextRef ctx = CGBitmapContextCreate(input.data, input.cols, input.rows, 8, input.cols * 3, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaNone);
    
    assert(ctx != nullptr);
    
    return CGBitmapContextCreateImage(ctx);
}

SelectionPoint* ConvertSelectionPoint(optonaut::SelectionPoint point) {
    SelectionPoint* newPoint = [SelectionPoint alloc];
    newPoint->_globalId = point.globalId;
    newPoint->_localId = point.localId;
    newPoint->_ringId = point.ringId;
    newPoint->_extrinsics = CVMatToGLK4(point.extrinsics);
    return newPoint;
}

void ConvertSelectionPoint(SelectionPoint* point, optonaut::SelectionPoint *newPoint) {
    newPoint->globalId = point->_globalId;
    newPoint->localId = point->_localId;
    newPoint->ringId = point->_ringId;
    GLK4ToCVMat(point->_extrinsics, newPoint->extrinsics);
}



@implementation SelectionPointIterator {
@private
    std::vector<optonaut::SelectionPoint> data;
    int i;
}
- (id)init:(std::vector<optonaut::SelectionPoint>)points {
    self  = [super init];
    self->i = 0;
    self->data = points;
    return self;
}
- (SelectionPoint*)Next {
    assert(i < data.size());
    
    SelectionPoint* q = ConvertSelectionPoint(data[i]);
    i++;
    return q;
}
- (bool)HasMore {
    return i < data.size();
}
@end

std::string debugPath;

@implementation Recorder {
@private
    optonaut::Recorder* pipe;
    cv::Mat intrinsics;
    NSString* tempPath;
}

+ (void)enableDebug:(NSString*)path {
    debugPath = std::string([path UTF8String]);
}
+ (void)disableDebug {
    debugPath = "";
}

+ (NSString*)getVersion {
    return [NSString stringWithCString:optonaut::Recorder::version.c_str() encoding: [NSString defaultCStringEncoding]];
}
+ (GLKMatrix3)getIPhone6Intrinsics {
    return CVMatToGLK3(optonaut::iPhone6Intrinsics);
}
+ (GLKMatrix3)getIPhone5Intrinsics {
    return CVMatToGLK3(optonaut::iPhone5Intrinsics);
}
+ (void)freeImageBuffer:(ImageBuffer)toFree {
    free(toFree.data);
}

// TODO - using static variables here is dangerous.
// Promote to class variables instead (somehow). 
// optonaut::StorageSink storageSink(Stores::left, Stores::right);
//optonaut::StitcherSink stitcherSink;
optonaut::ImageSink imageSink(Stores::post);

-(id)init:(RecorderMode)recorderMode {
    self = [super init];
    self->intrinsics = optonaut::iPhone6Intrinsics;
    
    // Yes, asserting in init is evil.
    // But you sould never even think of starting a new recording
    // while an old one is in the stores. 
    assert(!Stores::left.HasUnstitchedRecording());
    assert(!Stores::right.HasUnstitchedRecording());
    
    Stores::left.Clear();
    Stores::right.Clear();
    Stores::common.Clear();
    Stores::post.Clear();
    
    optonaut::CheckpointStore::DebugStore = &Stores::debug;
    
  //  optonaut::StereoSink& sink = storageSink;
    
    optonaut::ImageSink& sink = imageSink;
    
    int internalRecordingMode = optonaut::RecorderGraph::ModeTruncated;
    
    switch(recorderMode) {
        case TinyDebug:
            internalRecordingMode = optonaut::RecorderGraph::ModeTinyDebug;
            //sink = stitcherSink;
            break;
        case Center:
            internalRecordingMode = optonaut::RecorderGraph::ModeCenter;
            //sink = stitcherSink;
            break;
        case Full:
            internalRecordingMode = optonaut::RecorderGraph::ModeAll;
            //sink = storageSink;
            break;
        default: break; //Explicitely default to truncated. This removes the compiler warning.
    }
    
    optonaut::Recorder::exposureEnabled = false;
    optonaut::Recorder::alignmentEnabled = true;
    
    
    self->pipe = new optonaut::Recorder(optonaut::Recorder::iosBase, optonaut::Recorder::iosZero,
                                        self->intrinsics, sink,
                                        debugPath, internalRecordingMode);
    
    counter = 0;

    return self;
}

- (bool)isDisposed {
    return pipe == NULL;
}
- (void)push:(GLKMatrix4)extrinsics :(struct ImageBuffer)image :(struct ExposureInfo)exposure  :(AVCaptureWhiteBalanceGains)gains{
    assert(pipe != NULL);
    optonaut::InputImageP oImage(new optonaut::InputImage());

    oImage->dataRef = ImageBufferToImageRef(image);
    oImage->intrinsics = intrinsics;
    oImage->id = counter++;
    oImage->exposureInfo.iso = exposure.iso;
    oImage->exposureInfo.exposureTime = exposure.exposureTime;
    oImage->exposureInfo.gains.red = gains.redGain;
    oImage->exposureInfo.gains.blue = gains.blueGain;
    oImage->exposureInfo.gains.green = gains.greenGain;
    GLK4ToCVMat(extrinsics, oImage->originalExtrinsics);

    pipe->Push(oImage);
}
- (GLKMatrix4)getCurrentRotation {
    assert(pipe != NULL);
    return CVMatToGLK4(pipe->GetCurrentRotation());
}
- (SelectionPoint*)lastKeyframe {
    assert(pipe != NULL);
   return ConvertSelectionPoint(pipe->GetCurrentKeyframe().closestPoint);
}
- (bool)areAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b {
    assert(pipe != NULL);
    optonaut::SelectionPoint convA;
    optonaut::SelectionPoint convB;
    ConvertSelectionPoint(a, &convA);
    ConvertSelectionPoint(b, &convB);
    return pipe->AreAdjacent(convA, convB);
}
- (SelectionPointIterator*)getSelectionPoints {
    assert(pipe != NULL);
    return [[SelectionPointIterator alloc] init: pipe->GetSelectionPoints()];
}
- (void)setIdle:(bool)isIdle {
    assert(pipe != NULL);
    pipe->SetIdle(isIdle);
}
- (bool)isIdle {
    assert(pipe != NULL);
    return pipe->IsIdle();
}
- (bool)hasStarted {
    assert(pipe != NULL);
    return pipe->HasStarted();
}

- (bool)hasResults {
    assert(pipe != NULL);
    return pipe->HasResults();
}
- (GLKMatrix4)getBallPosition {
    assert(pipe != NULL);
    return CVMatToGLK4(pipe->GetBallPosition());
}
- (bool)isFinished {
    assert(pipe != NULL);
    return pipe->IsFinished();
}
- (double)getDistanceToBall {
    assert(pipe != NULL);
    return pipe->GetDistanceToBall();
}
- (GLKVector3)getAngularDistanceToBall {
    assert(pipe != NULL);
    //Special coord remapping, so we respect the screen coord system.
    const Mat &m = pipe->GetAngularDistanceToBall();
    return GLKVector3Make((float)-m.at<double>(1, 0), (float)-m.at<double>(0, 0), (float)-m.at<double>(2, 0));
}
- (uint32_t)getRecordedImagesCount {
    assert(pipe != NULL);
    return pipe->GetRecordedImagesCount();
}
- (uint32_t)getImagesToRecordCount {
    assert(pipe != NULL);
    return pipe->GetImagesToRecordCount();
}
- (void)finish {
    assert(pipe != NULL);
    pipe->Finish();
}
- (void)dispose {
    assert(pipe != NULL);
    pipe->Dispose();
    [[NSFileManager defaultManager] removeItemAtPath:self->tempPath error:nil];
    delete pipe;
    pipe = NULL;
}

- (struct ExposureInfo)getExposureHint {
    assert(pipe != NULL);
    
    cv::Mat extrinsics;
    optonaut::ExposureInfo info = pipe->GetExposureHint();
    ExposureInfo converted;
    converted.iso = info.iso;
    converted.gains.redGain = info.gains.red;
    converted.gains.greenGain = info.gains.green;
    converted.gains.blueGain = info.gains.blue;
    converted.exposureTime = info.exposureTime;
    
    return converted;
}
- (bool)previewAvailable {
    assert(pipe != NULL);
    
    return pipe->PreviewAvailable();
}
- (struct ImageBuffer)getPreviewImage {
    ImageBuffer result;
    
    return CVMatToImageBuffer(pipe->FinishPreview()->image.data);
    return result;
}
@end