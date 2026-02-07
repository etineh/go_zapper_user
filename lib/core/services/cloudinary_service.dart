import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class CloudinaryService {
  // Cloudinary credentials
  static const String cloudName = 'dqgm6lufp';
  static const String uploadPreset = 'gozapper_profiles';

  final Logger _logger = Logger();

  /// Uploads an image to Cloudinary and returns the secure URL
  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'] as String;
        _logger.i('Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        _logger.e('Failed to upload image: ${response.statusCode}');
        _logger.e('Response: $responseData');
        return null;
      }
    } catch (e) {
      _logger.e('Error uploading image: $e');
      return null;
    }
  }

  /// Uploads multiple images and returns list of URLs
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> urls = [];
    for (final file in imageFiles) {
      final url = await uploadImage(file);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}
