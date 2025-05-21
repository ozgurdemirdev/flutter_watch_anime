import 'package:flutter/material.dart';
import '../utils/anime_storage.dart';

class AnimeDrawer extends StatefulWidget {
  final Function(String, String) onContinueWatching;

  const AnimeDrawer({
    Key? key,
    required this.onContinueWatching,
  }) : super(key: key);

  @override
  State<AnimeDrawer> createState() => _AnimeDrawerState();
}

class _AnimeDrawerState extends State<AnimeDrawer> {
  Map<String, dynamic> _animeList = {};

  @override
  void initState() {
    super.initState();
    _loadAnimeList();
  }

  Future<void> _loadAnimeList() async {
    final list = await getAnimeList();
    setState(() {
      _animeList = list;
    });
  }

  Future<void> deleteAnime(String animeKey) async {
    await removeAnimeFromList(animeKey);
  }

  String _getEpisodeFromUrl(String url) {
    final episodeRegex = RegExp(r'episode/(\d+)');
    final match = episodeRegex.firstMatch(url);
    return match != null ? 'Bölüm ${match.group(1)}' : 'Bilinmeyen Bölüm';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Center(
              child: Text(
                'Anime Listem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAnimeList,
              child: ListView.builder(
                itemCount: _animeList.length,
                itemBuilder: (context, index) {
                  final animeKey = _animeList.keys.elementAt(index);
                  final anime = _animeList[animeKey] as Map<String, dynamic>;
                  final animeName = anime['name'] as String;
                  final lastUrl = anime['lastUrl'] as String;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ListTile(
                      title: Text(
                        animeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(_getEpisodeFromUrl(lastUrl)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await removeAnimeFromList(animeKey);
                              _loadAnimeList();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {
                              widget.onContinueWatching(animeKey, lastUrl);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
