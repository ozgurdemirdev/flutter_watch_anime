import 'dart:ffi';
import 'dart:io';

final DynamicLibrary nativeLib = Platform.isWindows
    ? (() {
        try {
          return DynamicLibrary.open('OpenCVWrapper.dll');
        } catch (e) {
          throw Exception('OpenCVWrapper.dll yüklenemedi: $e');
        }
      })()
    : throw UnsupportedError('Only supported on Windows');

typedef CompareFuncC = Double Function(
    Pointer<Uint8>, Int32, Pointer<Uint8>, Int32, Int32, Int32);

typedef CompareFuncDart = double Function(
    Pointer<Uint8>, int, Pointer<Uint8>, int, int, int);

final CompareFuncDart compareImagesNative = nativeLib
    .lookup<NativeFunction<CompareFuncC>>('compare_images')
    .asFunction();
