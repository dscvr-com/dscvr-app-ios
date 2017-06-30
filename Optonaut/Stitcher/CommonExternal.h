#ifndef OPTONAUT_IOS_COMMON_EXTERNA_HEADER
#define OPTONAUT_IOS_COMMON_EXTERNA_HEADER

struct ImageBuffer {
    void* data;
    uint32_t width;
    uint32_t height;

    ImageBuffer() {
        data = NULL;
        width = 0;
        height = 0;
    }
};

#endif
