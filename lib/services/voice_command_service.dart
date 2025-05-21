import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VoiceCommandService {
  bool isListening = false;
  Timer? listenTimer;
  final Function(String) onCommandReceived;

  VoiceCommandService({required this.onCommandReceived});

  Future<void> toggleListening() async {
    isListening = !isListening;
    if (isListening) {
      await http.get(Uri.parse('http://localhost:5000/start'));
      _startPeriodicListening();
    } else {
      await http.get(Uri.parse('http://localhost:5000/stop'));
      listenTimer?.cancel();
    }
  }

  void _startPeriodicListening() {
    listenTimer?.cancel();
    listenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isListening) {
        _listenForCommands();
      }
    });
  }

  Future<void> _listenForCommands() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/listen'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['action'] != null) {
          onCommandReceived(data['action']);
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void dispose() {
    listenTimer?.cancel();
  }
}
