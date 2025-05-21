import 'package:animecx/bridge/screen_shoot_bindings.dart';
import 'package:animecx/models/skip_entry.dart';
import 'package:animecx/screens/video_player_screen.dart';
import 'package:animecx/utils/capture_video_area.dart';
import 'package:animecx/widgets/anime_skip_settings.dart';
import 'package:desktop_screenshot/desktop_screenshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'widgets/video_controls.dart';
import 'widgets/video_seek_bar.dart';
import 'utils/video_utils.dart';
import 'utils/frame_utils.dart';

bool isDebugMode = false;

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  final String animeKey;
  final Future<void> Function(bool? isNext)? onVideoEnd;
  final Future<void> Function() onGoBackMain;

  const VideoWidget({
    required this.videoUrl,
    required this.animeKey,
    this.onVideoEnd,
    required this.onGoBackMain,
    super.key,
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late final Player player;
  late final VideoController videoController;
  bool isPlaying = false;
  bool isMuted = false;
  bool isFullscreen = false;
  double volume = 1.0;
  bool isInitialized = false;
  bool isLoading = true;
  String? error;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double buffered = 0.0;
  final FocusNode _focusNode = FocusNode();

  bool _controlsVisible = false;
  Timer? _hideTimer;
  bool _mouseOnControls = false;
  Timer? _frameCheckTimer;

  final GlobalKey videoKey =
      GlobalKey(); // Bunu video player widget'ına veriyoruz

  @override
  void initState() {
    super.initState();
    player = Player();
    videoController = VideoController(player);
    _loadVolume();
    _initController();
    loadReferenceImages().then((_) => _startFrameCheck());
    _enterFullscreenAndPlay();
  }

  @override
  void didUpdateWidget(VideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // VideoWidget tekrar açıldığında otomatik başlat ve fullscreen'e al
    _initController(); // controller'ı yeniden başlat
    _enterFullscreenAndPlay();
  }

  Future<void> _enterFullscreenAndPlay() async {
    // Fullscreen'e geç
    if (!isFullscreen) {
      await Future.delayed(const Duration(milliseconds: 100));
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (Platform.isWindows) {
        await windowManager.setFullScreen(true);
      }
      setState(() {
        isFullscreen = true;
      });
    }
    // Video başlat
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!isPlaying) {
        player.play();
        setState(() {
          isPlaying = true;
        });
      }
    });
  }

  Future<void> _enterWindowedMode() async {
    if (isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (Platform.isWindows) {
        await windowManager.setFullScreen(false);
      }
      setState(() {
        isFullscreen = false;
      });
    }
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVolume = prefs.getDouble('video_volume');
    if (savedVolume != null) {
      setState(() {
        volume = savedVolume;
      });
    }
  }

  Future<void> _saveVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('video_volume', value);
  }

  Future<void> _initController() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      await player.open(Media(widget.videoUrl));
      await player.setVolume((volume * 100));
      player.stream.playing.listen((playing) {
        setState(() {
          isPlaying = playing;
        });
      });
      player.stream.position.listen((pos) {
        setState(() {
          position = pos;
        });
      });
      player.stream.duration.listen((dur) {
        setState(() {
          duration = dur;
        });
      });
      player.stream.buffer.listen((buf) {
        setState(() {
          // buf is Duration, duration is Duration
          buffered = duration.inMilliseconds > 0
              ? buf.inMilliseconds / duration.inMilliseconds
              : 0.0;
        });
      });
      setState(() {
        isInitialized = true;
        isLoading = false;
      });
      player.play();
    } catch (e) {
      setState(() {
        error = 'Video yüklenemedi: $e';
        if (widget.onVideoEnd != null) {
          widget.onVideoEnd!(null);
        }
        isLoading = false;
      });
    }
  }

  List<SkipEntry> _introImages = [];
  List<SkipEntry> _outroImages = [];

  Future<void> loadReferenceImages() async {
    try {
      final settings = await AnimeSkipSettingsHelper.loadSkipSettingsForAnime(
          widget.animeKey);

      setState(() {
        _introImages = settings.intros.map((intro) {
          return SkipEntry(
            image: intro.image,
            seconds: intro.seconds,
            minute: intro.minute,
            skipped: false,
          );
        }).toList();

        _outroImages = settings.outros.map((outro) {
          return SkipEntry(
            image: outro.image,
            seconds: outro.seconds,
            minute: outro.minute,
            skipped: false,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading reference images: $e');
      setState(() {
        _introImages = [];
        _outroImages = [];
      });
    }
  }

  void _startFrameCheck() {
    if (!Platform.isWindows) return;

    _frameCheckTimer =
        Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (_introImages.isEmpty && _outroImages.isEmpty) {
        print('Frame check skipped: reference images are null');
        return;
      }
      try {
        if (isDebugMode) {
          Uint8List? captured = screenCapture.capture();
          setState(() {
            _croppedFrame = captured;
          });
        }

        Uint8List? captured = screenCapture.capture();
        if (captured.isEmpty) return;

        // INTRO karşılaştırma
        for (final intro in _introImages) {
          if (intro.skipped || intro.image.isEmpty) continue;
          bool controlAvg = await compareImages(captured, intro.image);
          if (controlAvg) {
            _onSeek((position + Duration(seconds: intro.seconds))
                .inMilliseconds
                .toDouble());
            intro.skipped = true;
            break;
          }
        }

        // OUTRO karşılaştırma
        for (final outro in _outroImages) {
          if (outro.skipped || outro.image.isEmpty) continue;
          int controlMin = outro.minute ?? 20;
          if (controlMin > position.inMinutes) continue;
          bool controlAvg = await compareImages(captured, outro.image);
          if (controlAvg) {
            if (widget.onVideoEnd != null) {
              await widget.onVideoEnd!(true);
            }
            break;
          }
        }
      } catch (e) {
        print('Error during frame check: $e');
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    _frameCheckTimer?.cancel();
    _focusNode.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _toggleMute() {
    if (isMuted) {
      player.setVolume((volume == 0 ? 1.0 : volume) * 100);
      setState(() {
        isMuted = false;
      });
      _saveVolume(volume == 0 ? 1.0 : volume);
    } else {
      player.setVolume(0);
      setState(() {
        isMuted = true;
      });
      _saveVolume(0.0);
    }
  }

  void _onVolumeChanged(double value) {
    player.setVolume((value * 100));
    setState(() {
      volume = value;
      isMuted = value == 0;
    });
    _saveVolume(value);
  }

  void _onSeek(double value) {
    final seekTo = Duration(milliseconds: value.round());
    player.seek(seekTo);
  }

  void _toggleFullscreen() async {
    if (!isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (Platform.isWindows) {
        await windowManager.setFullScreen(true);
      }
    } else {
      if (Platform.isWindows) {
        await windowManager.setFullScreen(false);
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {
      isFullscreen = !isFullscreen;
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.space) {
        _togglePlayPause();
      } else if (key == LogicalKeyboardKey.keyM) {
        _toggleMute();
      } else if (key == LogicalKeyboardKey.keyF) {
        _toggleFullscreen();
      } else if (key == LogicalKeyboardKey.arrowRight) {
        _onSeek(
            (position + const Duration(seconds: 5)).inMilliseconds.toDouble());
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        _onSeek((position - const Duration(seconds: 5))
            .inMilliseconds
            .clamp(0, duration.inMilliseconds)
            .toDouble());
      } else if (key == LogicalKeyboardKey.arrowUp) {
        double newVolume = (volume + 0.05).clamp(0.0, 1.0);
        _onVolumeChanged(newVolume);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        double newVolume = (volume - 0.05).clamp(0.0, 1.0);
        _onVolumeChanged(newVolume);
      }
      _showControls();
    }
  }

  void _showControls() {
    setState(() {
      _controlsVisible = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (!_mouseOnControls && mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _onMouseMove(PointerEvent event) {
    _showControls();
  }

  void _onMouseEnter(PointerEvent event) {
    _mouseOnControls = true;
    _showControls();
  }

  void _onMouseExit(PointerEvent event) {
    _mouseOnControls = false;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (!_mouseOnControls && mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  Uint8List? _croppedFrame;
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            error!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    if (!isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Video bulunamadı',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: isFullscreen,
      resizeToAvoidBottomInset: false,
      body: Listener(
        onPointerMove: _onMouseMove,
        onPointerHover: _onMouseMove,
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  onDoubleTap: _toggleFullscreen,
                  child: Container(
                    key: videoKey,
                    color: Colors.black,
                    child: Center(
                      child: Video(
                        controller: videoController,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // Burada küçük bir önizleme kutusu ekliyoruz:
              if (_croppedFrame != null && isDebugMode)
                Positioned(
                  top: 40,
                  right: 20,
                  width: 300,
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      color: Colors.black87,
                    ),
                    child: Image.memory(
                      _croppedFrame!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (_introImages.isNotEmpty && isDebugMode)
                Positioned(
                  top: 40,
                  right: 380,
                  width: 300,
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70),
                      color: Colors.black87,
                    ),
                    child: /*Image.memory(
                      _introImages[0].image,
                      fit: BoxFit.cover,
                    ),*/
                        Text("Intro: ${_introImages[0].seconds} sn"),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoControls(
                  visible: _controlsVisible,
                  isPlaying: isPlaying,
                  isMuted: isMuted,
                  volume: volume,
                  onPlayPause: _togglePlayPause,
                  onMute: _toggleMute,
                  onVolumeChanged: _onVolumeChanged,
                  onFullscreen: _toggleFullscreen,
                  seekBar: VideoSeekBar(
                    videoKey: videoKey,
                    animeKey: widget.animeKey,
                    controller: player, // MediaKit Player nesnesi
                    position: position,
                    duration: duration,
                    buffered: buffered,
                    onSeek: _onSeek,
                    onMouseEnter: _onMouseEnter,
                    onMouseExit: _onMouseExit,
                    onReferansChanged: () {
                      print("Referans değişti");
                      loadReferenceImages();
                    },
                    onNextEpisode: () {
                      if (widget.onVideoEnd != null) {
                        print("Sonraki bölüm tıklandı");
                        widget.onVideoEnd!(true);
                      }
                    },
                    onPrevEpisode: () {
                      if (widget.onVideoEnd != null) {
                        widget.onVideoEnd!(false);
                      }
                    },
                    onGoBackMain: () {
                      _enterWindowedMode();
                      widget.onGoBackMain();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
