import 'package:url_launcher/url_launcher.dart';

class LinkUtils {
  // 將原本的方法改成 static，並傳入 context 用於顯示錯誤
  static Future<void> openUrl(String url, Function showErrorCallback) async {
    var uri = Uri.tryParse(url);
    if (uri == null) {
      await showErrorCallback();
      return;
    }

    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await showErrorCallback();
      }
    } catch (_) {
      await showErrorCallback();
    }
  }
}