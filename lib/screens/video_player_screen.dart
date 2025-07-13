import 'package:animecx/widgets/anime_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/anime_storage.dart';
import '../widgets/anime_webview.dart';
import '../services/video_service.dart';
import '../services/voice_command_service.dart';
import '../video_player.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late InAppWebViewController _webViewController;
  late VideoService _videoService;
  late VoiceCommandService _voiceCommandService;
  bool isPlaying = true;
  String? _videoControllerJs;
  bool _shouldGoToNextEpisode = false;
  bool _shouldGoToOldEpisode = false;
  String? _currentUrl;
  String? _currentAnimeKey;
  String? _currentAnimeName;
  String? _currentAnimeLink;
  bool _showAddAnimeButton = false;
  bool _showStartWatchingButton = false;
  bool _isBrowse = false;
  bool _showBackButton = false;
  String? _mp4Link;
  bool _isLoading = false;
  List<String> _loadingSteps = [];
  double _loadingProgress = 0.0;
  InAppWebView? _invisibleWebView;
  int _notFoundDelaySeconds = 1;

  // Bu değişkenlerle son tıklanan next/prev url'yi tutalım
  String? _pendingNextUrl;
  String? _pendingPrevUrl;

  @override
  void initState() {
    super.initState();
    _voiceCommandService = VoiceCommandService(
      onCommandReceived: _handleVoiceCommand,
    );
    _loadJavaScript();
    _openBrowse();
  }

  void _openBrowse() {
    setState(() {
      _isBrowse = true;
      _showAddAnimeButton = false;
      _showStartWatchingButton = false;
      _showBackButton = false;
      _currentUrl = 'https://animecix.tv/browse';
      _mp4Link = null;
      _isLoading = false;
      _loadingSteps.clear();
      _loadingProgress = 0.0;
      _invisibleWebView = null;
    });
  }

  Future<void> _loadJavaScript() async {
    _videoControllerJs =
        await rootBundle.loadString('assets/js/video_controller.js');
  }

  void _handleVoiceCommand(String action) {
    if (action == 'play') {
      _videoService.play();
      setState(() => isPlaying = true);
    } else if (action == 'pause') {
      _videoService.pause();
      setState(() => isPlaying = false);
    }
  }

  void _parseAnimeInfo(String url) {
    final reg = RegExp(r'animecix\.tv\/titles\/(\d+)\/([^\/]+)');
    final match = reg.firstMatch(url);
    if (match != null) {
      _currentAnimeKey = match.group(1);
      _currentAnimeLink = match.group(2);
      _currentAnimeName = match.group(2)?.replaceAll('-', ' ');
    } else {
      _currentAnimeKey = null;
      _currentAnimeName = null;
      _currentAnimeLink = null;
    }
    print(
        'Anime Key: $_currentAnimeKey Anime Name: $_currentAnimeName Anime Link: $_currentAnimeLink');
  }

  void _parseAnimeInfoFromTitle(String? title) async {
    if (title == null) return;
    if (title.startsWith('animecix.tv/titles/')) {
      final reg = RegExp(r'animecix\.tv\/titles\/(\d+)\/([^\/]+)');
      final match = reg.firstMatch(title);
      if (match != null) {
        _currentAnimeKey = match.group(1);
        _currentAnimeLink = match.group(2);
        _currentAnimeName = match.group(2)?.replaceAll('-', ' ');
        _updateAnimeButtons();
      }
    } else if (title.contains(' - AnimeciX')) {
      _currentAnimeName = title.replaceAll(' - AnimeciX', '');
      _updateAnimeButtons();
    }
  }

  Future<void> _updateAnimeButtons() async {
    if (_currentAnimeKey != null) {
      final inList = await isAnimeInList(_currentAnimeKey!);
      setState(() {
        _showAddAnimeButton = !inList;
        _showStartWatchingButton = true;
        _showBackButton = true;
      });
    }
  }

  Future<void> _onWebViewUrlChanged(String? url) async {
    print('WebView URL changed: $url');
    if (url == null) return;

    // --- DÜZELTME: _currentAnimeKey, _currentAnimeName, _currentAnimeLink değişkenlerini burada asla sıfırlama! ---
    // Sadece /browse veya titles içermeyen sayfalarda sıfırlanmalı.

    setState(() {
      _currentUrl = url;
      _showAddAnimeButton = false;
      _showStartWatchingButton = false;
      _showBackButton = false;
      _isBrowse = false;
    });

    if (url.contains('/browse')) {
      setState(() {
        _isBrowse = true;
        _showBackButton = false;
        _showAddAnimeButton = false;
        _showStartWatchingButton = false;
        _currentAnimeKey = null;
        _currentAnimeName = null;
        _currentAnimeLink = null;
      });
      return;
    }

    if (url.contains('/titles/')) {
      _parseAnimeInfo(url);
      if (_currentAnimeKey != null) {
        final inList = await isAnimeInList(_currentAnimeKey!);
        setState(() {
          _showAddAnimeButton = !inList;
          _showStartWatchingButton = true;
          _showBackButton = true;
        });
        // Otomatik video yükleme tetikle
        bool shouldAutoPlay = false;
        String? autoPlayUrl;

        if (_pendingNextUrl != null && url == _pendingNextUrl) {
          shouldAutoPlay = true;
          autoPlayUrl = _pendingNextUrl;
          _pendingNextUrl = null;
        } else if (_pendingPrevUrl != null && url == _pendingPrevUrl) {
          shouldAutoPlay = true;
          autoPlayUrl = _pendingPrevUrl;
          _pendingPrevUrl = null;
        }

        if (url.contains('episode')) {
          await _handleSaveNextEpisode(_currentAnimeKey!, url);
        }
      } else {
        setState(() {
          _showAddAnimeButton = false;
          _showStartWatchingButton = false;
        });
      }
    }
  }

  Future<void> _handleAddAnime(bool watchNow) async {
    if (_currentAnimeKey == null || _currentAnimeLink == null) return;
    final inList = await isAnimeInList(_currentAnimeKey!);
    if (inList && !watchNow) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Zaten Kayıtlı'),
          content: const Text('Bu anime zaten listende mevcut.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }
    final firstEpisodeUrl =
        'https://animecix.tv/titles/${_currentAnimeKey!}/${_currentAnimeLink!}/season/1/episode/1';
    await addAnimeToList(
        _currentAnimeKey!, _currentAnimeName ?? '', firstEpisodeUrl);
    setState(() {
      _showAddAnimeButton = false;
    });
  }

  Future<void> _handleStartWatching() async {
    await _handleAddAnime(true);
    if (_currentAnimeKey == null || _currentAnimeLink == null) return;
    final animeList = await getAnimeList();
    String? lastUrl = animeList[_currentAnimeKey!]?['lastUrl'];
    print('Last URL: $lastUrl');
    // Eğer lastUrl geçersizse veya "clicked" gibi bir değer ise, ilk bölüme yönlendir
    if (lastUrl == null ||
        lastUrl == "" ||
        lastUrl == "clicked" ||
        lastUrl == "not found") {
      lastUrl =
          'https://animecix.tv/titles/${_currentAnimeKey!}/${_currentAnimeLink!}/season/1/episode/1';
      await setAnimeLastUrl(_currentAnimeKey!, lastUrl);
    }
    await _loadAndPlayVideoWithResult(lastUrl, false);
  }

  Future<String> _getLasturlanime() async {
    if (_currentAnimeKey == null || _currentAnimeLink == null) return "";
    final animeList = await getAnimeList();
    String? lastUrl = animeList[_currentAnimeKey!]?['lastUrl'];

    // Sadece "clicked" için kontrol et, diğer değerleri döndür
    if (lastUrl != null && lastUrl != "clicked") {
      return lastUrl;
    }
    return "";
  }

  Future<void> _handleSaveNextEpisode(String crAnime, String url) async {
    print("Test Url: $url animeKey: $crAnime");
    await setAnimeLastUrl(crAnime, url);
  }

  Future<void> _retryLoadAndPlayVideo(bool isProblem) async {
    int retryCount = 0;

    while (retryCount < 3) {
      // 🔴 Daha önceki görünmez WebView varsa temizle
      setState(() {
        _invisibleWebView = null;
      });

      // 🔁 Yeni URL ile yükleme denemesi
      String? url = await getAnimeLastUrl(_currentAnimeKey!);
      bool success = await _loadAndPlayVideoWithResult(url!, isProblem);

      if (success) break;

      retryCount++;
      _notFoundDelaySeconds += 1;

      // 🔁 Yeni deneme öncesi bekleme
      await Future.delayed(Duration(seconds: _notFoundDelaySeconds));
    }
  }

  Future<bool> _loadAndPlayVideoWithResult(String url, bool notFound) async {
    setState(() {
      _isLoading = true;
      _mp4Link = null;
      _loadingSteps = ['Başlatılıyor...'];
      _loadingProgress = 0.1;
    });

    bool success = false;
    final Completer<String> mp4Completer = Completer<String>();
    InAppWebViewController? tempController;
    late VideoService tempVideoService;
    print("notFound: $notFound");
    if (notFound) {
      _notFoundDelaySeconds += 1;
      print("Tekrar deneniyor: " + _notFoundDelaySeconds.toString());
    }
    final webView = InAppWebView(
      key: UniqueKey(),
      initialUrlRequest: URLRequest(url: WebUri(url)),
      onWebViewCreated: (controller) async {
        tempController = controller;
        tempVideoService = VideoService(tempController!);
        if (_videoControllerJs != null) {
          tempVideoService.setVideoControllerJs(_videoControllerJs!);
        }
        setState(() {
          _loadingProgress = 0.2;
          _loadingSteps.add('WebView oluşturuldu');
        });
      },
      onLoadStop: (controller, uri) async {
        print("MyUrl : $url");

        print("Delay:" + _notFoundDelaySeconds.toString());
        if (uri?.host == "animecix.tv") {
          setState(() {
            _loadingProgress = 0.3;
            _loadingSteps.add('Sayfa yükleniyor: ${uri?.toString()}');
          });
          print("Delay: bekleniyor");
          await Future.delayed(Duration(seconds: _notFoundDelaySeconds));
          print("Delay: Bitti");
          setState(() {
            _loadingProgress = 0.4;
            _loadingSteps.add('Sayfa yüklendi: ${uri?.toString()}');
          });
          if (url.contains('titles')) {
            _parseAnimeInfo(url);
          }
          bool controlAndClickRes = await tempVideoService.controlAndClick();

          _loadingSteps.add('Kontrol edildi ve tıklandı: $controlAndClickRes');
          if (!controlAndClickRes) {
            if (mounted) {
              mp4Completer.complete("");
              return;
            }
          }
          await Future.delayed(Duration(seconds: _notFoundDelaySeconds));
          setState(() {
            _loadingProgress = 0.5;
          });
          if (_shouldGoToNextEpisode) {
            // Sadece tıklama kontrolü yap, url'yi burada alma!
            String clickResult =
                await tempVideoService.clickNextEpisodeButton();
            setState(() {
              _loadingSteps.add('Sonraki bölüm tıklandı: $clickResult');
            });
            if (clickResult != "clicked") {
              if (mounted) {
                mp4Completer.complete("");
                return;
              }
            } else {
              _shouldGoToNextEpisode = false;
            }
            await Future.delayed(Duration(seconds: 2));
          } else if (_shouldGoToOldEpisode) {
            String clickResult = await tempVideoService.clickOldEpisodeButton();
            setState(() {
              _loadingSteps.add('Önceki bölüm tıklandı: $clickResult');
            });
            if (clickResult != "clicked") {
              if (mounted) {
                mp4Completer.complete("");
                return;
              }
            } else {
              _shouldGoToOldEpisode = false;
            }
            await Future.delayed(Duration(seconds: _notFoundDelaySeconds));
          }
          setState(() {
            _loadingSteps.add('Tau linki aranıyor:');
          });
          String tauLink = await tempVideoService.getTauLink();
          setState(() {
            _loadingSteps.add('Tau linki aranıyor: $tauLink');
          });
          if (tauLink == null || tauLink == "not found" || tauLink == "") {
            if (mounted) {
              mp4Completer.complete("");
              return;
            }
          }
          setState(() {
            _loadingProgress = 0.6;
          });
          if (_currentAnimeKey == null) {
            if (mounted) {
              mp4Completer.complete("");
              return;
            }
          }
          controller.loadUrl(urlRequest: URLRequest(url: WebUri(tauLink)));
        } else if (uri?.host == "tau-video.xyz") {
          setState(() {
            _loadingProgress = 0.7;
          });
          await Future.delayed(Duration(seconds: _notFoundDelaySeconds));
          setState(() {
            _loadingProgress = 0.8;
          });
          String mp4Link = await tempVideoService.getVideoMp4Link();
          if (mp4Link == "" || mp4Link == "") {
            success = false;
            mp4Completer.complete("");
            return;
          } else {
            setState(() {
              _loadingSteps.add('MP4 link bulundu');
              _loadingProgress = 1.0;
              _notFoundDelaySeconds = 1;
            });
            success = true;
            mp4Completer.complete(mp4Link);
            return;
          }
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (consoleMessage.message.contains('Cannot match any routes')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Sayfa bulunamadı veya geçersiz bir linke tıklandı.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        print('onUpdateVisitedHistory url: ${url?.toString()}');

        if (_shouldGoToNextEpisode) {
          _pendingNextUrl = url?.toString();
        } else if (_shouldGoToOldEpisode) {
          _pendingPrevUrl = url?.toString();
        }
        _onWebViewUrlChanged(url?.toString());
      },
    );

    setState(() {
      if (!isDebugMode) {
        _invisibleWebView = webView;
      } else {
        _invisibleWebView = null;
      }
    });

    if (isDebugMode) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Video Yükleniyor')),
            body: webView,
          ),
        ),
      );
    }

    String mp4Link = await mp4Completer.future;
    print('MP4 Link: $mp4Link');
    if (mp4Link == "not found" || mp4Link == "") {
      await Future.delayed(
        const Duration(seconds: 2),
      );
      setState(() {
        _loadingSteps.add('MP4 link bulunamadı');
        _loadingProgress = 1.0;
        _notFoundDelaySeconds = 1;
      });
      if (mounted) {
        await _retryLoadAndPlayVideo(true);
      }
      return false;
    }
    setState(() {
      _mp4Link = mp4Link;
      _isLoading = false;
      _loadingSteps.clear();
      _loadingProgress = 0.0;
      _invisibleWebView = null;
    });
    return success;
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _showAddAnimeButton = false;
      _showStartWatchingButton = false;
      _currentAnimeKey = null;
      _currentAnimeName = null;
      _mp4Link = null;
      _isLoading = false;
      _loadingSteps.clear();
      _loadingProgress = 0.0;
      _invisibleWebView = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm ayarlar ve kayıtlar temizlendi.')),
    );
  }

  @override
  void dispose() {
    _voiceCommandService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            Container(
              color: Colors.grey.shade900,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color.fromARGB(255, 103, 158, 56),
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _loadingProgress,
                      color: Color.fromARGB(255, 153, 211, 102),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 56, 88, 28),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._loadingSteps.map((step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            step,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white70),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            if (!isDebugMode && _invisibleWebView != null)
              Offstage(
                offstage: true,
                child: SizedBox(
                  width: 0,
                  height: 0,
                  child: _invisibleWebView,
                ),
              ),
          ],
        ),
      );
    }
    if (_mp4Link != null) {
      return VideoWidget(
        videoUrl: _mp4Link!,
        animeKey: _currentAnimeKey ?? "none",
        onGoBackMain: () async {
          setState(() {
            print("GoBackMain");
            _mp4Link = null;
            _currentAnimeKey = null;
            _currentAnimeName = null;
            _isLoading = false;
            _loadingSteps.clear();
            _loadingProgress = 0.0;
            _invisibleWebView = null;
            _currentUrl = 'https://animecix.tv/browse';
          });
        },
        onVideoEnd: (bool? isNext) async {
          String? animeLastUrl = await getAnimeLastUrl(_currentAnimeKey!);
          print("currurL" + animeLastUrl.toString());
          if (isNext == true) {
            _shouldGoToNextEpisode = true;
            // Sonraki bölüm butonuna tıklandığında yeni bölümü yükle

            await _loadAndPlayVideoWithResult(animeLastUrl ?? '', false);
          } else if (isNext == false) {
            _shouldGoToOldEpisode = true;
            // Önceki bölüm butonuna tıklandığında önceki bölümü yükle
            await _loadAndPlayVideoWithResult(animeLastUrl ?? '', false);
          } else {
            _shouldGoToNextEpisode = false;
            _shouldGoToOldEpisode = false;
          }
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_webViewController != null) {
              _webViewController.goBack();
            }
          },
        ),
        title: const Text('AnimeCx'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.list),
                tooltip: 'Drawer Aç',
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimeWebView(
            initialUrl: _currentUrl ?? 'https://animecix.tv/browse',
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (uri) async {
              print('onLoadStop url: $uri');
            },
            onTitleChanged: (title) => _parseAnimeInfoFromTitle(title),
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              print('onUpdateVisitedHistory url: ${url?.toString()}');
              _onWebViewUrlChanged(url?.toString());
            },
          ),
        ],
      ),
      drawer: AnimeDrawer(
        onContinueWatching: (animeKey, animeUrl) {
          setState(() {
            _currentAnimeKey = animeKey;
            _currentAnimeName = animeKey;
            _currentAnimeLink = animeUrl;
            if (_currentAnimeLink != null) {
              _loadAndPlayVideoWithResult(_currentAnimeLink!, false);
            }
          });
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_showAddAnimeButton)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                heroTag: 'addAnime',
                onPressed: () => _handleAddAnime(false),
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Kaydet'),
              ),
            ),
          if (_showStartWatchingButton)
            FloatingActionButton.extended(
              heroTag: 'startWatching',
              onPressed: _handleStartWatching,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Şimdi İzle'),
            ),
        ],
      ),
    );
  }
}
