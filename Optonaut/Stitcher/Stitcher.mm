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
    cv::cvtColor(Mat(image.width, image.height, CV_8UC4), output, COLOR_RGBA2RGB);
}

ImageBuffer CVMatToImageBuffer(const cv::Mat &input) {
    Mat converted(input.rows, input.cols, CV_8UC4);
    cv::cvtColor(input, converted, COLOR_RGB2BGRA);
    
    ImageBuffer output;
    output.width = input.cols;
    output.height = input.rows;
    output.data = malloc(output.width * output.height * 4);
    memcpy(output.data, converted.data, output.width * output.height * 4);
    
    return output;
}


@implementation IosPipeline {
@private
    optonaut::Pipeline* pipe;
    cv::Mat intrinsics;
}

-(id)init {
    self = [super init];
    self->intrinsics = optonaut::iPhone6Intrinsics;
    self->pipe = new optonaut::Pipeline(optonaut::Pipeline::iosBase, optonaut::Pipeline::iosZero, self->intrinsics);
    return self;
}

- (void)Push:(GLKMatrix4)extrinsics :(ImageBuffer)image {
    optonaut::ImageP oImage(new optonaut::Image());
    ImageBufferToCVMat(image, oImage->img);
    oImage->intrinsics = intrinsics;
    oImage->id = 0;
    GLK4ToCVMat(extrinsics, oImage->extrinsics);
    oImage->source = "Camera";
    
    pipe->Push(oImage);
}
- (GLKMatrix4)GetCurrentRotation {
    return GLKMatrix4MakeWithArray(NULL);
}
- (bool)IsPreviewImageValialble {
    return pipe->IsPreviewImageAvailable();
}
- (ImageBuffer)GetPreviewImage {
    return CVMatToImageBuffer(pipe->GetPreviewImage()->img);
}
- (void)FreeImageBuffer:(ImageBuffer)toFree {
    free(toFree.data);
}
- (NSArray<NSValue*>*)GetSelectionPoints {
    vector<optonaut::SelectionPoint> points = pipe->GetSelectionPoints();
    
    NSMutableArray *outPoints = [NSMutableArray array];
    
    for(auto point : points) {
        SelectionPoint newPoint;
        newPoint.id = point.id;
        newPoint.localId = point.localId;
        newPoint.ringId = point.ringId;
        newPoint.extrinsics = CVMatToGLK4(point.extrinsics);
        
        [outPoints addObject:[NSValue valueWithBytes:&newPoint objCType:@encode(struct SelectionPoint)]];
    }
    
    NSArray *immutableOutPoints = [NSArray arrayWithArray:outPoints];
    
    return immutableOutPoints;
}
- (void)DisableSelectionPoint:(SelectionPoint)toDisable {
    optonaut::SelectionPoint p;
    p.id = toDisable.id;
    p.ringId = toDisable.ringId;
    p.localId = toDisable.localId;
    
    //Only Ids are needed to disable the selection point.
    pipe->DisableSelectionPoint(p);
}
@end
