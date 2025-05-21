import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_screenshot/desktop_screenshot.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

final _desktopScreenshotPlugin = DesktopScreenshot();
Future<Uint8List?> processScreenshot(Uint8List bytes) async {
  return compute(_processImageInIsolate, bytes);
}

Uint8List? _processImageInIsolate(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  final screenWidth = image.width;
  final screenHeight = image.height;

  final cropWidth = 20;
  final cropHeight = 20;
  final cropX = 0;
  final cropY = 0;

  final cropped = img.copyCrop(image,
      x: cropX, y: cropY, width: cropWidth, height: cropHeight);

  final jpgBytes = img.encodeJpg(cropped, quality: 20);

  return Uint8List.fromList(jpgBytes);
}

// Kullanım:

Future<Uint8List?> captureAndProcessScreenshot() async {
  Uint8List? captured = await _desktopScreenshotPlugin.getScreenshot();
  if (captured == null) {
    print('Screenshot alınamadı');
    return null;
  }

  Uint8List? processed = await processScreenshot(captured);
  if (processed == null) {
    print('Screenshot işlenemedi');
  }
  return processed;
}
