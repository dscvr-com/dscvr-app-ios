#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>

#include "pipeline.hpp"
#include "intrinsics.hpp"
#include "Stitcher.h"

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

void ImageBufferToCVMat(ImageBuffer image, cv::Mat &output) {
    cv::cvtColor(Mat(image.height, image.width, CV_8UC4, image.data), output, COLOR_RGBA2RGB);
}

optonaut::ImageRef ImageBufferToImageRef(ImageBuffer image) {
    optonaut::ImageRef ref;
    ref.data = image.data;
    ref.width = image.width;
    ref.height = image.height;
    ref.colorSpace = optonaut::colorspace::RGBA;
    
    return ref;
}

ImageBuffer CVMatToImageBuffer(const cv::Mat &input) {
    ImageBuffer output;
    output.width = input.cols;
    output.height = input.rows;
    output.data = malloc(output.width * output.height * 4);
    
    Mat converted(input.rows, input.cols, CV_8UC4, output.data);
    cv::cvtColor(input, converted, COLOR_RGB2RGBA);
    
    return output;
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

@implementation IosPipeline {
@private
    optonaut::Pipeline* pipe;
    cv::Mat intrinsics;
    std::string debugPath;
    bool isDebug;
}

+ (NSString*)GetVersion {
    return [NSString stringWithCString:optonaut::Pipeline::version.c_str() encoding: [NSString defaultCStringEncoding]];
}

-(id)init {
    self = [super init];
    self->intrinsics = optonaut::iPhone6Intrinsics;
    self->isDebug = false,
    self->pipe = new optonaut::Pipeline(optonaut::Pipeline::iosBase, optonaut::Pipeline::iosZero, self->intrinsics, optonaut::RecorderGraph::ModeAll, true);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tempDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/tmp/"];
    
    counter = 0;
    
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:tempDirectory isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create temp folder failed: %@", tempDirectory);
    
    optonaut::Pipeline::tempDirectory = std::string([tempDirectory UTF8String]);

    return self;
}

- (void)Push:(GLKMatrix4)extrinsics :(ImageBuffer)image {
    optonaut::ImageP oImage(new optonaut::Image());
    //Nu-Uh. No more copying. Save some memory. 
    //ImageBufferToCVMat(image, oImage->img);
    oImage->dataRef = ImageBufferToImageRef(image);
    oImage->intrinsics = intrinsics;
    oImage->id = counter++;
    GLK4ToCVMat(extrinsics, oImage->extrinsics);
    oImage->source = "Camera";
    
    if(isDebug) {
        cv::imwrite(debugPath + "/pushed.jpg", oImage->img);
    }
    
    pipe->Push(oImage);
}
- (GLKMatrix4)GetCurrentRotation {
    return CVMatToGLK4(pipe->GetCurrentRotation());
}
- (GLKMatrix4)GetPreviewRotation {
    return CVMatToGLK4(pipe->GetPreviewRotation());
}
- (bool)IsPreviewImageAvailable {
    return pipe->IsPreviewImageAvailable();
}
- (ImageBuffer)GetPreviewImage {
    if(isDebug) {
        cv::imwrite(debugPath + "/preview.jpg", pipe->GetPreviewImage()->img);
    }
    return CVMatToImageBuffer(pipe->GetPreviewImage()->img);
}
- (void)FreeImageBuffer:(ImageBuffer)toFree {
    free(toFree.data);
}
- (SelectionPoint*)CurrentPoint {
    return ConvertSelectionPoint(pipe->CurrentPoint().closestPoint);
}

- (SelectionPoint*)PreviousPoint {
    return ConvertSelectionPoint(pipe->PreviousPoint().closestPoint);
}

- (bool)AreAdjacent:(SelectionPoint*)a and:(SelectionPoint*)b {
    optonaut::SelectionPoint convA;
    optonaut::SelectionPoint convB;
    ConvertSelectionPoint(a, &convA);
    ConvertSelectionPoint(b, &convB);
    return pipe->AreAdjacent(convA, convB);
}
- (void)EnableDebug:(NSString*)path {
    assert(false);
    debugPath = std::string([path UTF8String]);
    isDebug = true;
}
- (ImageBuffer)GetLeftResult {
    return CVMatToImageBuffer(pipe->FinishLeft()->image);
}
- (ImageBuffer)GetRightResult {
    return CVMatToImageBuffer(pipe->FinishRight()->image);
}

- (SelectionPointIterator*)GetSelectionPoints {
    return [[SelectionPointIterator alloc] init: pipe->GetSelectionPoints()];
}
- (void)SetIdle:(bool)isIdle {
    pipe->SetIdle(isIdle);
}
- (bool)IsIdle {
    return pipe->IsIdle();
}
- (bool)HasResults {
    return pipe->HasResults();
}
- (GLKMatrix4)GetBallPosition {
    return CVMatToGLK4(pipe->GetBallPosition());
}

@end