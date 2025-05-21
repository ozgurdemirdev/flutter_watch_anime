import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveVideoVolume(double value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('video_volume', value);
}

Future<double?> loadVideoVolume() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('video_volume');
}
