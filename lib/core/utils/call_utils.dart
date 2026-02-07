import 'package:url_launcher/url_launcher.dart';

class CallUtils {
  static Future<String?> launcherCaller(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return "No phone number provided";
    }

    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      await launchUrl(uri);
      return null;
    } catch (e) {
      return "Could not open phone app!";
    }
  }
}
