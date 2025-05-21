import 'package:animecx/bridge/screen_shoot_bindings.dart';
import 'package:animecx/models/skip_entry.dart';
import 'package:animecx/utils/raw_rgb_to_png.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;

import 'package:animecx/utils/capture_video_area.dart';

class AnimeSkipSettingsPopup extends StatefulWidget {
  final GlobalKey videoKey;
  final Player? controller;
  final Function() onReferansChanged;
  final Duration position;
  final String animeKey;

  const AnimeSkipSettingsPopup({
    required this.videoKey,
    required this.controller,
    required this.position,
    required this.animeKey,
    required this.onReferansChanged,
    super.key,
  });

  @override
  State<AnimeSkipSettingsPopup> createState() => _AnimeSkipSettingsPopupState();
}

class _AnimeSkipSettingsPopupState extends State<AnimeSkipSettingsPopup> {
  List<SkipEntry> intros = [];
  List<SkipEntry> outros = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings =
        await AnimeSkipSettingsHelper.loadSkipSettingsForAnime(widget.animeKey);
    setState(() {
      intros = List<SkipEntry>.from(settings.intros);
      outros = List<SkipEntry>.from(settings.outros);
    });
  }

  Future<void> _saveSettings() async {
    final settings = _AnimeSkipSettings(intros, outros);
    await AnimeSkipSettingsHelper.saveSkipSettingsForAnime(
        widget.animeKey, settings);
    widget.onReferansChanged();
  }

  void _onEntryChanged() async {
    setState(() {});
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('Intro',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...intros.map((e) => SkipEntryWidget(
                    entry: e,
                    onDelete: () async {
                      setState(() => intros.remove(e));
                      await _saveSettings();
                    },
                    onEdit: () {
                      // Görüntü değiştir
                    },
                    onChanged: _onEntryChanged,
                  )),
              ElevatedButton(
                onPressed: () async {
                  Uint8List? img = await _captureIntroFrame();
                  if (img != null) {
                    setState(() {
                      intros.add(SkipEntry(image: img, seconds: 0));
                    });
                    await _saveSettings();
                  }
                },
                child: const Text('Intro atlama ekle'),
              ),
              const Divider(),
              const Text('Outro',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...outros.map((e) => SkipEntryWidget(
                    entry: e,
                    onDelete: () async {
                      setState(() => outros.remove(e));
                      await _saveSettings();
                    },
                    onEdit: () {
                      // Görüntü değiştir
                    },
                    showMinute: true,
                    onChanged: _onEntryChanged,
                  )),
              ElevatedButton(
                onPressed: () async {
                  Uint8List? img = await _captureIntroFrame();
                  if (img != null) {
                    setState(() {
                      outros.add(SkipEntry(image: img, seconds: 0, minute: 20));
                    });
                    await _saveSettings();
                  }
                },
                child: const Text('Outro atlama ekle'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _captureIntroFrame() async {
    try {
      final img = screenCapture.capture();
      return img;
    } catch (e) {
      print('Görüntü yakalama hatası: $e');
      return null;
    }
  }
}

class SkipEntryWidget extends StatelessWidget {
  final SkipEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onChanged;
  final bool showMinute;
  const SkipEntryWidget({
    required this.entry,
    required this.onDelete,
    required this.onEdit,
    this.onChanged,
    this.showMinute = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Builder(builder: (context) {
            return Image.memory(entry.image, width: 150, height: 150);
          }),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Süre (sn): '),
                    SizedBox(
                      width: 50,
                      child: TextFormField(
                        initialValue: entry.seconds.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          entry.seconds = int.tryParse(v) ?? 0;
                          if (onChanged != null) onChanged!();
                        },
                      ),
                    ),
                    if (showMinute) ...[
                      const SizedBox(width: 16),
                      const Text('Dakikadan sonra ara: '),
                      SizedBox(
                        width: 40,
                        child: TextFormField(
                          initialValue: (entry.minute ?? 0).toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            entry.minute = int.tryParse(v) ?? 0;
                            if (onChanged != null) onChanged!();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                        onPressed: onEdit, child: const Text('Değiştir')),
                    TextButton(onPressed: onDelete, child: const Text('Sil')),
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

// Yardımcı sınıf: intro/outro ayarlarını yükle/kaydet
class AnimeSkipSettingsHelper {
  static Future<_AnimeSkipSettings> loadSkipSettingsForAnime(
      String animeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('anime_skip_settings_$animeKey');
    if (data != null) {
      return _AnimeSkipSettings.fromJsonString(data);
    }
    return _AnimeSkipSettings([], []);
  }

  static Future<void> saveSkipSettingsForAnime(
      String animeKey, _AnimeSkipSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'anime_skip_settings_$animeKey', settings.toJsonString());
  }
}

class _AnimeSkipSettings {
  final List<SkipEntry> intros;
  final List<SkipEntry> outros;
  _AnimeSkipSettings(this.intros, this.outros);

  Map<String, dynamic> toJson() => {
        'intros': intros.map((e) => e.toJson()).toList(),
        'outros': outros.map((e) => e.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  static _AnimeSkipSettings fromJsonString(String str) {
    final json = jsonDecode(str);
    return _AnimeSkipSettings(
      (json['intros'] as List).map((e) => SkipEntry.fromJson(e)).toList(),
      (json['outros'] as List).map((e) => SkipEntry.fromJson(e)).toList(),
    );
  }
}
