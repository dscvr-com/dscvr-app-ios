#include "CommonExternal.h"

static inline ImageBuffer CVMatToImageBuffer(const cv::Mat &input) {
ImageBuffer output;
output.width = input.cols;
output.height = input.rows;
output.data = malloc(output.width * output.height * 4);

Mat converted(input.rows, input.cols, CV_8UC4, output.data);
cv::cvtColor(input, converted, COLOR_RGB2RGBA);

return output;
}