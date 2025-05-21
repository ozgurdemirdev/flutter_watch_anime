String formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  final twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  return '${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds';
}
