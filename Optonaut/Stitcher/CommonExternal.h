#ifndef OPTONAUT_IOS_COMMON_EXTERNA_HEADER
#define OPTONAUT_IOS_COMMON_EXTERNA_HEADER

struct ImageBuffer {
    void* data;
    uint32_t width;
    uint32_t height;
};

struct ImageBuffer MakeImageBuffer();

struct RecorderParamInfo {
    double graphHOverlap;
    double graphVOverlap;
    double stereoHBuffer;
    double stereoVBuffer;
    double tolerance;
    bool halfGraph;
};

struct RecorderParamInfo MakeRecorderParamInfo();

#endif
