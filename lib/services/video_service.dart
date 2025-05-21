import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VideoService {
  final InAppWebViewController webViewController;
  String? videoControllerJs;

  VideoService(this.webViewController);

  Future<bool> controlAndClick() async {
    var result = await webViewController.evaluateJavascript(source: """
    (function() {
      const spans = document.querySelectorAll('span.mat-button-wrapper');
      for (let span of spans) {
        if (span.innerText.includes('Şimdi İzle')) {
          span.click();
          return true;
        }
      }
      return false;
    })();
    """);
    print("Control and click result: $result");
    return result ?? false;
  }

  Future<String> clickNextEpisodeButton() async {
    // Sadece butona tıklandığını bildirir, url döndürmez!
    String result = await webViewController.evaluateJavascript(source: """
    (function() {
      const buttons = document.querySelectorAll('button');
      for (let btn of buttons) {
        if (btn.innerText.includes('Sonraki Bölüm')) {
          btn.click();
          return "clicked";
        }
      }
      return "not found";
    })();
    """) as String;
    print("Click next episode button result: $result");
    return result;
  }

  Future<String> clickOldEpisodeButton() async {
    String result = await webViewController.evaluateJavascript(source: """
    (function() {
      const buttons = document.querySelectorAll('button');
      for (let btn of buttons) {
        if (btn.innerText.includes('Önceki Bölüm')) {
          btn.click();
          return "clicked";
        }
      }
      return "not found";
    })();
    """) as String;
    print("Click old episode button result: $result");
    return result;
  }

  Future<String> getTauLink() async {
    var result = await webViewController.evaluateJavascript(source: """
    (function() {
      const iframe = document.getElementById('plyrFrame');
      if (iframe && iframe.src) {
        return iframe.src;
      }
      return "not found";
    })();
    """);
    print("Get tau link result: $result");
    return result?.toString() ?? "not found";
  }

  Future<String> getVideoMp4Link() async {
    final result = await webViewController.evaluateJavascript(source: """
    (function() {
      const sources = document.querySelectorAll('video source');
      for (let src of sources) {
        if (src.src && src.src.endsWith('.mp4')) {
          return src.src;
        }
      }
      return "not found";
    })();
    """);
    print("Get video mp4 link result: $result");
    return result?.toString() ?? "not found";
  }

  void play() {
    webViewController.evaluateJavascript(
      source: "${videoControllerJs}\nvideoController.play();",
    );
  }

  void pause() {
    webViewController.evaluateJavascript(
      source: "${videoControllerJs}\nvideoController.pause();",
    );
  }

  void setVideoControllerJs(String js) {
    videoControllerJs = js;
  }
}
