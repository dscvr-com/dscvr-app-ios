#include <opencv2/opencv.hpp>
#import <GLKit/GLKit.h>
#import <Foundation/foundation.h>
#include <vector>
#include <string>

#include "pipeline.hpp"
#include "intrinsics.hpp"
#include "Stitcher.h"

GLKMatrix4 CVMatToGLK4(const cv::Mat &m) {
    assert(m.cols == 4 && m.rows == 4 && m.type() == CV_64F);
    
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
    Mat converted(input.rows, input.cols, CV_8UC4);
    cv::cvtColor(input, converted, COLOR_RGB2RGBA);
    
    ImageBuffer output;
    output.width = input.cols;
    output.height = input.rows;
    output.data = malloc(output.width * output.height * 4);
    memcpy(output.data, converted.data, output.width * output.height * 4);
    
    return output;
}

SelectionPoint ConvertSelectionPoint(optonaut::SelectionPoint point) {
    SelectionPoint newPoint;
    newPoint.id = point.id;
    newPoint.localId = point.localId;
    newPoint.ringId = point.ringId;
    newPoint.extrinsics = CVMatToGLK4(point.extrinsics);
    return newPoint;
}

optonaut::SelectionPoint ConvertSelectionPoint(SelectionPoint point) {
    optonaut::SelectionPoint newPoint;
    newPoint.id = point.id;
    newPoint.localId = point.localId;
    newPoint.ringId = point.ringId;
    GLK4ToCVMat(point.extrinsics, newPoint.extrinsics);
    return newPoint;
}


@implementation IosPipeline {
@private
    optonaut::Pipeline* pipe;
    cv::Mat intrinsics;
    std::string debugPath;
    bool isDebug;
}

-(id)init {
    self = [super init];
    self->intrinsics = optonaut::iPhone6Intrinsics;
    self->isDebug = false,
    self->pipe = new optonaut::Pipeline(optonaut::Pipeline::iosBase, optonaut::Pipeline::iosZero, self->intrinsics, optonaut::ImageSelector::ModeAll, true);
    return self;
}

- (void)Push:(GLKMatrix4)extrinsics :(ImageBuffer)image {
    optonaut::ImageP oImage(new optonaut::Image());
    //Nu-Uh. No more copying. Save some memory. 
    //ImageBufferToCVMat(image, oImage->img);
    oImage->dataRef = ImageBufferToImageRef(image);
    oImage->intrinsics = intrinsics;
    oImage->id = 0;
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
- (bool)IsPreviewImageValialble {
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
- (SelectionPoint)CurrentPoint {
    return ConvertSelectionPoint(pipe->CurrentPoint().closestPoint);
}

- (SelectionPoint)PreviousPoint {
    return ConvertSelectionPoint(pipe->PreviousPoint().closestPoint);
}
- (NSArray<NSValue*>*)GetSelectionPoints {
    vector<optonaut::SelectionPoint> points = pipe->GetSelectionPoints();
    
    NSMutableArray *outPoints = [NSMutableArray array];
    
    for(auto point : points) {
        SelectionPoint newPoint = ConvertSelectionPoint(point);
        
        [outPoints addObject:[NSValue valueWithBytes:&newPoint objCType:@encode(struct SelectionPoint)]];
    }
    
    NSArray *immutableOutPoints = [NSArray arrayWithArray:outPoints];
    
    return immutableOutPoints;
}
- (bool)AreAdjacent:(SelectionPoint)a and:(SelectionPoint)b {
    return pipe->AreAdjacent(ConvertSelectionPoint(a), ConvertSelectionPoint(b));
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
@end
