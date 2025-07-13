// opencv_wrapper.cpp

#include <vector>
#include <cmath>

#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

// OpenCV header'larý

extern "C" __declspec(dllexport) double compare_images(
    const unsigned char* img1Data, int img1Len,
    const unsigned char* img2Data, int img2Len,
    int resizeWidth, int resizeHeight)
{
    // Bufferlardan OpenCV Mat oluþtur
    std::vector<uchar> buf1(img1Data, img1Data + img1Len);
    std::vector<uchar> buf2(img2Data, img2Data + img2Len);

    cv::Mat img1 = cv::imdecode(buf1, cv::IMREAD_COLOR);
    cv::Mat img2 = cv::imdecode(buf2, cv::IMREAD_COLOR);

    if (img1.empty() || img2.empty()) {
        return -1.0; // hata durumu
    }

    cv::resize(img1, img1, cv::Size(resizeWidth, resizeHeight));
    cv::resize(img2, img2, cv::Size(resizeWidth, resizeHeight));

    // Ortalama farký hesapla
    double totalDiff = 0.0;
    int count = 0;

    for (int y = 0; y < img1.rows; y += 4) {
        for (int x = 0; x < img1.cols; x += 4) {
            cv::Vec3b a = img1.at<cv::Vec3b>(y, x);
            cv::Vec3b b = img2.at<cv::Vec3b>(y, x);

            int grayA = static_cast<int>(0.299 * a[2] + 0.587 * a[1] + 0.114 * a[0]);
            int grayB = static_cast<int>(0.299 * b[2] + 0.587 * b[1] + 0.114 * b[0]);

            totalDiff += std::abs(grayA - grayB);
            count++;
        }
    }

    return (count > 0) ? (totalDiff / count) : 0.0;
}
