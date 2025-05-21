import 'dart:typed_data';
import 'package:image/image.dart' as img;

Uint8List rawRgbToPngold(Uint8List rgbBytes, int width, int height) {
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgbBytes.buffer, // <-- ByteBuffer veriyoruz burada
    numChannels: 3, // RGB
  );

  final pngBytes = img.encodePng(image);
  return Uint8List.fromList(pngBytes);
}
