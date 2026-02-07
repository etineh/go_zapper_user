import 'package:gozapper/data/models/user_model.dart';

class AuthResponseModel {
  final String? token;
  final String? refreshToken;
  final UserModel? user;
  final String? message;
  final bool success;

  AuthResponseModel({
    this.token,
    this.refreshToken,
    this.user,
    this.message,
    required this.success,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Backend sends nested data in 'data' field
    final data = json['data'] as Map<String, dynamic>?;

    return AuthResponseModel(
      token: data?['token'] ?? json['token'] ?? json['access_token'] ?? json['accessToken'],
      refreshToken: data?['refreshToken'] ?? json['refresh_token'] ?? json['refreshToken'],
      // Backend sends 'organization' not 'user'
      user: (data?['organization'] ?? json['organization'] ?? json['user']) != null
          ? UserModel.fromJson(data?['organization'] ?? json['organization'] ?? json['user'])
          : null,
      message: json['message'] ?? json['msg'],
      success: json['success'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refresh_token': refreshToken,
      'user': user?.toJson(),
      'message': message,
      'success': success,
    };
  }
}
