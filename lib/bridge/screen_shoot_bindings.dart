import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

ScreenCapture screenCapture = ScreenCapture();

// DLL'deki CaptureScreenRegionJpg fonksiyonunun imzası
typedef CaptureScreenRegionJpgNative = Pointer<Uint8> Function(
  Int32 x,
  Int32 y,
  Int32 width,
  Int32 height,
  Pointer<Int32> outSize,
);

typedef CaptureScreenRegionJpgDart = Pointer<Uint8> Function(
  int x,
  int y,
  int width,
  int height,
  Pointer<Int32> outSize,
);

// FreeCapturedImage fonksiyonu
typedef FreeCapturedImageNative = Void Function(Pointer<Uint8>);
typedef FreeCapturedImageDart = void Function(Pointer<Uint8>);

class ScreenCapture {
  late DynamicLibrary _dll;
  late CaptureScreenRegionJpgDart _captureScreenRegionJpg;
  late FreeCapturedImageDart _freeCapturedImage;

  ScreenCapture() {
    _dll = DynamicLibrary.open('getScreenShoot.dll');

    _captureScreenRegionJpg = _dll.lookupFunction<CaptureScreenRegionJpgNative,
        CaptureScreenRegionJpgDart>('CaptureScreenRegionJpg');

    _freeCapturedImage =
        _dll.lookupFunction<FreeCapturedImageNative, FreeCapturedImageDart>(
            'FreeCapturedImage');
  }

  /// Ekrandan belirtilen alanın JPG verisini döndürür (Uint8List)
  Uint8List capture({int x = 0, int y = 0, int width = 300, int height = 300}) {
    final outSizePtr = malloc<Int32>();
    final ptr = _captureScreenRegionJpg(x, y, width, height, outSizePtr);
    final size = outSizePtr.value;

    final bytes = Uint8List.fromList(ptr.asTypedList(size));

    malloc.free(outSizePtr);
    _freeCapturedImage(ptr); // malloc'la ayırılan belleği serbest bırak

    return bytes;
  }
}
