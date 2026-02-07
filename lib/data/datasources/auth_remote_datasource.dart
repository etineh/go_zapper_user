import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/network/api_client.dart';
import 'package:gozapper/data/models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  });

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  });

  Future<bool> resendOtp({
    required String email,
  });

  Future<void> logout();

  Future<AuthResponseModel> getProfile();

  Future<AuthResponseModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? photoUrl,
  });

  Future<Map<String, dynamic>> exportProfile();

  Future<void> deleteAccount();

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<String> forgotPassword({
    required String email,
  });

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<String?> getStoredToken();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final response = await apiClient.post(
        AppConstants.registerEndpoint,
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        print("General log: the error data - ${response.data}");

        // Save tokens if available
        if (authResponse.token != null) {
          await apiClient.saveToken(authResponse.token!);
        }
        if (authResponse.refreshToken != null) {
          await apiClient.saveRefreshToken(authResponse.refreshToken!);
        }

        return authResponse;
      } else {
        print("General log: the error data - $response");

        throw ServerException(
          response.data['message'] ?? 'Registration failed',
          response.statusCode,
        );
      }
    } catch (e) {
      print("General log: the error is $e");
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        print('🔍 Login response data type: ${response.data.runtimeType}');
        print('🔍 Login response data: ${response.data}');

        final authResponse = AuthResponseModel.fromJson(response.data);

        print('🔍 Parsed token: ${authResponse.token?.substring(0, 20)}...');
        print('🔍 Parsed refreshToken: ${authResponse.refreshToken?.substring(0, 20)}...');

        // Save tokens
        if (authResponse.token != null) {
          print('💾 Saving token to secure storage...');
          await apiClient.saveToken(authResponse.token!);
          print('✅ Token saved!');
        } else {
          print('❌ No token to save!');
        }

        if (authResponse.refreshToken != null) {
          print('💾 Saving refresh token to secure storage...');
          await apiClient.saveRefreshToken(authResponse.refreshToken!);
          print('✅ Refresh token saved!');
        } else {
          print('❌ No refresh token to save!');
        }

        // Verify tokens were saved
        final savedToken = await apiClient.getToken();
        print('🔍 Verification - Token in storage: ${savedToken != null}');

        return authResponse;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Login failed',
          response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await apiClient.post(
        AppConstants.verifyOtpEndpoint,
        data: {
          'email': email,
          'code': otp,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          response.data['message'] ?? 'OTP verification failed',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> resendOtp({
    required String email,
  }) async {
    try {
      final response = await apiClient.post(
        AppConstants.resendOtpEndpoint,
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to resend OTP',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await apiClient.post(AppConstants.logoutEndpoint);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          response.data['message'] ?? 'Logout failed',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> getProfile() async {
    try {
      final response = await apiClient.get(AppConstants.profileEndpoint);

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        return authResponse;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch profile',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final data = {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      };

      // Only include photoUrl if it's provided
      if (photoUrl != null && photoUrl.isNotEmpty) {
        data['photoUrl'] = photoUrl;
      }

      final response = await apiClient.patch(
        AppConstants.profileEndpoint,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response.data is a Map
        if (response.data is! Map<String, dynamic>) {
          throw ServerException(
            'Invalid response format: expected JSON object',
            response.statusCode,
          );
        }

        final authResponse = AuthResponseModel.fromJson(response.data);
        return authResponse;
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? response.data['error'] ?? 'Failed to update profile')
            : 'Failed to update profile';
        throw ServerException(message, response.statusCode);
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      print('updateProfile error: $e');
      print('Stack trace: $stackTrace');
      throw ServerException('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> exportProfile() async {
    try {
      final response = await apiClient.get(AppConstants.profileExportEndpoint);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to export profile data',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await apiClient.delete(AppConstants.profileEndpoint);

      if (response.statusCode != 200) {
        throw ServerException(
          response.data['message'] ?? 'Failed to delete account',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.patch(
        '${AppConstants.profileEndpoint}/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        // Return the success message from the API
        return response.data is String
            ? response.data
            : response.data['message'] ?? 'Password changed successfully';
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to change password',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConstants.authenticationEndpoint}/password/forgot',
        data: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        // Return the success message from the API
        return response.data is String
            ? response.data
            : response.data['message'] ??
                'If the email exists, a reset code has been sent';
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to send reset code',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await apiClient.post(
        '${AppConstants.authenticationEndpoint}/password/reset',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        // Return the success message from the API
        return response.data is String
            ? response.data
            : response.data['message'] ?? 'Password reset successfully';
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to reset password',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getStoredToken() async {
    return await apiClient.getToken();
  }
}
