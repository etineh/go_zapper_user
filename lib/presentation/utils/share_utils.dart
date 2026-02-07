import 'package:share_plus/share_plus.dart';
import 'package:gozapper/domain/entities/notification.dart';

class ShareUtils {
  /// Share a notification
  static Future<void> shareNotification(Notification notification) async {
    final text = '${notification.title}\n\n${notification.message}';
    await Share.share(text);
  }

  /// Share custom text
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }
}
