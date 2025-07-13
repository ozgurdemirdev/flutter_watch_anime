#include <windows.h>
#include <iostream>
#include <vector>

// OpenCV (dll içinde encode işlemi için)
#include <opencv2/opencv.hpp>

extern "C" __declspec(dllexport)
unsigned char* CaptureScreenRegionJpg(int x, int y, int width, int height, int* outSize) {
    HDC hScreen = GetDC(NULL);
    HDC hDC = CreateCompatibleDC(hScreen);
    HBITMAP hBitmap = CreateCompatibleBitmap(hScreen, width, height);
    SelectObject(hDC, hBitmap);

    BitBlt(hDC, 0, 0, width, height, hScreen, x, y, SRCCOPY);

    BITMAPINFOHEADER bi;
    ZeroMemory(&bi, sizeof(BITMAPINFOHEADER));
    bi.biSize = sizeof(BITMAPINFOHEADER);
    bi.biWidth = width;
    bi.biHeight = -height;  // top-down
    bi.biPlanes = 1;
    bi.biBitCount = 24;
    bi.biCompression = BI_RGB;

    int rowSize = ((width * 3 + 3) & ~3);
    int bmpSize = rowSize * height;

    std::vector<uchar> buffer(bmpSize);
    GetDIBits(hDC, hBitmap, 0, height, buffer.data(), (BITMAPINFO*)&bi, DIB_RGB_COLORS);

    // BGR -> JPG encode işlemi
    cv::Mat img(height, width, CV_8UC3, buffer.data());
    std::vector<uchar> jpgBuffer;
    cv::imencode(".jpg", img, jpgBuffer, { cv::IMWRITE_JPEG_QUALITY, 90 });

    // OpenCV verisini heap'e kopyala (DLL dışına döndürmek için)
    unsigned char* result = (unsigned char*)malloc(jpgBuffer.size());
    memcpy(result, jpgBuffer.data(), jpgBuffer.size());
    *outSize = jpgBuffer.size();

    // Temizlik
    DeleteObject(hBitmap);
    DeleteDC(hDC);
    ReleaseDC(NULL, hScreen);

    return result;
}

extern "C" __declspec(dllexport)
void FreeCapturedImage(unsigned char* data) {
    if (data) {
        free(data);
    }
}