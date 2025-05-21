import 'dart:typed_data';

import 'package:animecx/bridge/screen_shoot_bindings.dart';
import 'package:animecx/utils/capture_video_area.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../utils/video_utils.dart';
import 'anime_skip_settings.dart';

class VideoSeekBar extends StatelessWidget {
  final Player? controller;
  final Duration position;
  final Duration duration;
  final double buffered;

  final ValueChanged<double> onSeek;
  final void Function(PointerEvent)? onMouseEnter;
  final void Function(PointerEvent)? onMouseExit;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPrevEpisode;
  final VoidCallback? onGoBackMain;
  final VoidCallback onReferansChanged;
  final Widget? leading;
  final GlobalKey videoKey;
  final String animeKey;

  const VideoSeekBar({
    super.key,
    required this.controller,
    required this.position,
    required this.duration,
    required this.buffered,
    required this.onSeek,
    required this.onReferansChanged,
    this.onMouseEnter,
    this.onMouseExit,
    this.onNextEpisode,
    this.onPrevEpisode,
    this.onGoBackMain,
    this.leading,
    required this.videoKey,
    required this.animeKey,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: onMouseEnter,
      onExit: onMouseExit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade700,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Buffered bar (arka plan)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: buffered.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Slider (ön plan)
                Slider(
                  min: 0,
                  max: duration.inMilliseconds.toDouble(),
                  value: position.inMilliseconds
                      .clamp(0, duration.inMilliseconds)
                      .toDouble(),
                  onChanged: onSeek,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (leading != null) leading!,
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.settings,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          showDialog(
                            barrierColor: Colors.transparent,
                            context: context,
                            builder: (context) => AnimeSkipSettingsPopup(
                              videoKey: videoKey,
                              controller: controller,
                              position: position,
                              animeKey: animeKey,
                              onReferansChanged: () {
                                onReferansChanged();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Text(
                      formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (onGoBackMain != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          print("Ana Menü butonuna tıklandı");
                          onGoBackMain!();
                        },
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: const Text("Ana Menü"),
                      ),
                    IconButton(
                      icon: const Icon(Icons.contact_support_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () async {
                        print("Tam ekran butonuna tıklandı");
                        Uint8List? test = screenCapture.capture();
                        if (test != null) {
                          print("Görüntü yakalandı, boyut: ${test.length}");
                        } else {
                          print("Görüntü yakalanamadı");
                        }
                      },
                    ),
                    if (onPrevEpisode != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          print("Önceki Bölüm butonuna tıklandı");
                          onPrevEpisode!();
                        },
                        icon: const Icon(Icons.skip_previous,
                            color: Colors.white),
                        label: const Text("Önceki Bölüm"),
                      ),
                    if (onNextEpisode != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          print("Sonraki bölüm tıklandı");
                          onNextEpisode!();
                        },
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        label: const Text("Sonraki Bölüm"),
                      ),
                    const SizedBox(width: 8),
                    Text(formatDuration(duration),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
