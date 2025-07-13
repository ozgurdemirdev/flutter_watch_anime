#pragma once

#ifdef OPENCVWRAPPER_EXPORTS
#define OPENCVWRAPPER_API __declspec(dllexport)
#else
#define OPENCVWRAPPER_API __declspec(dllimport)
#endif

extern "C" {
    OPENCVWRAPPER_API double compare_images(
        const unsigned char* img1Data, int img1Len,
        const unsigned char* img2Data, int img2Len,
        int resizeWidth, int resizeHeight
    );
}