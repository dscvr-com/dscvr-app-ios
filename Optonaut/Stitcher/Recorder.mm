#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>
#define OPTONAUT_TARGET_PHONE

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

void GLK4ToCVMat(GLKMatrix4 m, cv::Mat &output) {
    double data[16] = { m.m00, m.m01, m.m02, m.m03,
        m.m10, m.m11, m.m12, m.m13,
        m.m20, m.m21, m.m22, m.m23,
        m.m30, m.m31, m.m32, m.m33 };
  
    output = cv::Mat(4, 4, CV_64F, data).clone();
}

GLKVector3 CVMatToGLK3Vec(const cv::Mat &m) {
    assert(m.cols == 1 && m.rows >= 3 && m.type() == CV_64F);
    
    return GLKVector3Make((float)m.at<double>(0, 0), (float)m.at<double>(1, 0), (float)m.at<double>(2, 0));
}

void ImageBufferToCVMat(ImageBuffer image, cv::Mat &output) {
    cv::cvtColor(Mat(image.height, image.width, CV_8UC4, image.data), output, COLOR_RGBA2RGB);
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

@implementation Recorder {
@private
    optonaut::Recorder* pipe;
    cv::Mat intrinsics;
    std::string debugPath;
    bool isDebug;
    NSString* tempPath;
}

+ (NSString*)getVersion {
    return [NSString stringWithCString:optonaut::Recorder::version.c_str() encoding: [NSString defaultCStringEncoding]];
}
+ (void)freeImageBuffer:(ImageBuffer)toFree {
    free(toFree.data);
}

-(id)init {
    self = [super init];
    self->intrinsics = optonaut::iPhone6Intrinsics;
    self->isDebug = false;
    
    // Yes, asserting in init is evil.
    // But you sould never even think of starting a new recording
    // while an old one is in the stores. 
    assert(!Stores::left.HasUnstitchedRecording());
    assert(!Stores::right.HasUnstitchedRecording());
    
    self->pipe = new optonaut::Recorder(optonaut::Recorder::iosBase, optonaut::Recorder::iosZero, self->intrinsics, Stores::left, Stores::right, optonaut::RecorderGraph::ModeTruncated, true);
    
    counter = 0;

    return self;
}

- (bool)isDisposed {
    return pipe == NULL;
}
- (void)push:(GLKMatrix4)extrinsics :(ImageBuffer)image {
    assert(pipe != NULL);
    optonaut::InputImageP oImage(new optonaut::InputImage());

    oImage->dataRef = ImageBufferToImageRef(image);
    oImage->intrinsics = intrinsics;
    oImage->id = counter++;
    GLK4ToCVMat(extrinsics, oImage->originalExtrinsics);

    pipe->Push(oImage);
}
- (GLKMatrix4)getCurrentRotation {
    assert(pipe != NULL);
    return CVMatToGLK4(pipe->GetCurrentRotation());
}
- (SelectionPoint*)currentPoint {
    assert(pipe != NULL);
    return ConvertSelectionPoint(pipe->CurrentPoint().closestPoint);
}

- (SelectionPoint*)previousPoint {
    assert(pipe != NULL);
    return ConvertSelectionPoint(pipe->PreviousPoint().closestPoint);
}
- (double)getExposureBias {
    assert(pipe != NULL);
    return pipe->GetExposureBias();
}

- (bool)areAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b {
    assert(pipe != NULL);
    optonaut::SelectionPoint convA;
    optonaut::SelectionPoint convB;
    ConvertSelectionPoint(a, &convA);
    ConvertSelectionPoint(b, &convB);
    return pipe->AreAdjacent(convA, convB);
}
- (void)enableDebug:(NSString*)path {
    assert(false);
    debugPath = std::string([path UTF8String]);
    isDebug = true;
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
@end