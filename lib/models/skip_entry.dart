import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SkipEntry {
  Uint8List image;
  int seconds;
  int? minute;
  bool skipped;

  // Decode edilmiş versiyonu sadece bellekte tutulur, JSON’a yazılmazssss

  SkipEntry({
    required this.image,
    required this.seconds,
    this.minute,
    this.skipped = false,
  });

  Map<String, dynamic> toJson() => {
        'image': image,
        'seconds': seconds,
        'minute': minute,
      };

  static SkipEntry fromJson(Map<String, dynamic> json) => SkipEntry(
        image: Uint8List.fromList(List<int>.from(json['image'])),
        seconds: json['seconds'],
        minute: json['minute'],
      );
}
