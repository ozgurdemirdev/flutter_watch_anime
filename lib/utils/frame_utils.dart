import 'dart:typed_data';
import 'package:animecx/bridge/opencv_bindings.dart';
import 'package:animecx/utils/raw_rgb_to_png.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';

Future<double> compareImagesWithNative(Uint8List img1, Uint8List img2,
    {int resizeWidth = 300, int resizeHeight = 300}) async {
  final Pointer<Uint8> img1Ptr = malloc.allocate<Uint8>(img1.length);
  final Pointer<Uint8> img2Ptr = malloc.allocate<Uint8>(img2.length);
  img1Ptr.asTypedList(img1.length).setAll(0, img1);
  img2Ptr.asTypedList(img2.length).setAll(0, img2);

  final result = compareImagesNative(
    img1Ptr,
    img1.length,
    img2Ptr,
    img2.length,
    resizeWidth,
    resizeHeight,
  );

  malloc.free(img1Ptr);
  malloc.free(img2Ptr);

  return result;
}

Future<bool> compareImages(Uint8List a, Uint8List b,
    {int resizeWidth = 300,
    int resizeHeight = 300,
    double threshold = 3}) async {
  final double avgDiff = await compareImagesWithNative(
    a,
    b,
    resizeWidth: resizeWidth,
    resizeHeight: resizeHeight,
  );

  print('Average difference: $avgDiff');
  return avgDiff <= threshold;
}
