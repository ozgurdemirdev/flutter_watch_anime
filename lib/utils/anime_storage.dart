import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> getAnimeList() async {
  final prefs = await SharedPreferences.getInstance();
  final listStr = prefs.getString('anime_list');
  if (listStr == null) return {};
  return Map<String, dynamic>.from(jsonDecode(listStr));
}

Future<void> saveAnimeList(Map<String, dynamic> animeList) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('anime_list', jsonEncode(animeList));
}

Future<String?> getAnimeLastUrl(String animeKey) async {
  final animeList = await getAnimeList();
  return animeList[animeKey]?['lastUrl'];
}

Future<void> setAnimeLastUrl(String animeKey, String url) async {
  final animeList = await getAnimeList();
  if (animeList[animeKey] == null) return;
  animeList[animeKey]['lastUrl'] = url;
  await saveAnimeList(animeList);
}

Future<void> addAnimeToList(
    String animeKey, String animeName, String url) async {
  final animeList = await getAnimeList();
  if (animeList.containsKey(animeKey)) return;
  animeList[animeKey] = {
    'name': animeName,
    'lastUrl': url,
  };
  await saveAnimeList(animeList);
}

Future<bool> isAnimeInList(String animeKey) async {
  final animeList = await getAnimeList();
  return animeList.containsKey(animeKey);
}

Future<void> clearAnimePrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

Future<void> removeAnimeFromList(String animeKey) async {
  final animeList = await getAnimeList();
  animeList.remove(animeKey);
  await saveAnimeList(animeList);
}
