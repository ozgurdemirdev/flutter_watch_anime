import 'package:flutter/material.dart';

class VideoControls extends StatelessWidget {
  final bool visible;
  final bool isPlaying;
  final bool isMuted;
  final double volume;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onFullscreen;
  final Widget seekBar;
  final Widget? leading;

  const VideoControls({
    super.key,
    required this.visible,
    required this.isPlaying,
    required this.isMuted,
    required this.volume,
    required this.onPlayPause,
    required this.onMute,
    required this.onVolumeChanged,
    required this.onFullscreen,
    required this.seekBar,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        color: Colors.black54,
        padding: const EdgeInsets.only(bottom: 0, top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            seekBar,
            Row(
              children: [
                if (leading != null) leading!,
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: onPlayPause,
                ),
                IconButton(
                  icon: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: onMute,
                ),
                Expanded(
                  child: Slider(
                    value: volume,
                    min: 0,
                    max: 1,
                    onChanged: onVolumeChanged,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                  ),
                  onPressed: onFullscreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
