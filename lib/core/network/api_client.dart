import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger;
  void Function()? onSessionExpired;

  ApiClient({
    FlutterSecureStorage? storage,
    Logger? logger,
    this.onSessionExpired,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _logger = logger ?? Logger() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        followRedirects: true,
        maxRedirects: 5,
        // Use default validateStatus (accepts 2xx as success)
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await _storage.read(key: AppConstants.tokenKey);
          print('🔑 Main API - Token found: ${token != null}');
          if (token != null) {
            print('✅ Adding Authorization header to request: ${options.path}');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print('⚠️ WARNING: No token found in storage for API request: ${options.path}');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            print('🚫 Got 401 error - token expired');
            // Try to refresh the token
            final refreshed = await _refreshToken();

            if (refreshed) {
              print('♻️ Token refreshed, retrying original request...');
              // Retry the original request with new token
              final options = error.requestOptions;
              final token = await _storage.read(key: AppConstants.tokenKey);
              options.headers['Authorization'] = 'Bearer $token';

              try {
                final response = await _dio.fetch(options);
                print('✅ Retry successful!');
                return handler.resolve(response);
              } catch (e) {
                print('❌ Retry failed: $e');
                // Return the new error from retry, not the original 401
                return handler.reject(e as DioException);
              }
            } else {
              print('❌ Token refresh failed, clearing tokens...');
              // Refresh failed, clear tokens
              await _handleUnauthorized();
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Add pretty logger in debug mode
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      print('🔄 Attempting to refresh token...');
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        print('❌ No refresh token available');
        _logger.w('No refresh token available');
        return false;
      }

      print('🔑 Refresh token found, calling refresh endpoint...');
      // Create a separate Dio instance for refresh to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ));

      print('📡 Calling: ${AppConstants.baseUrl}${AppConstants.refreshTokenEndpoint}');
      final response = await refreshDio.get(AppConstants.refreshTokenEndpoint);

      print('📥 Refresh response status: ${response.statusCode}');
      print('📥 Refresh response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final newToken = data['token'];
        final newRefreshToken = data['refreshToken'];

        // Save new tokens
        await _storage.write(key: AppConstants.tokenKey, value: newToken);
        await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);

        print('✅ Token refreshed successfully!');
        _logger.i('Token refreshed successfully');
        return true;
      }

      print('⚠️ Refresh failed - status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Token refresh error: $e');
      _logger.e('Token refresh failed', error: e);
      return false;
    }
  }

  Future<void> _handleUnauthorized() async {
    // Clear tokens
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    _logger.w('Session expired - tokens cleared');

    // Notify listeners that session has expired
    if (onSessionExpired != null) {
      onSessionExpired!();
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      // Log response details for debugging
      _logger.i('PATCH Response - Status: ${response.statusCode}, Has data: ${response.data != null}, Data type: ${response.data?.runtimeType}');

      // If we got a redirect response with empty body, the issue is with the server
      if ((response.statusCode == 307 || response.statusCode == 308) && response.data == null) {
        _logger.w('Got redirect with empty body. This might be a server configuration issue.');
      }

      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    _logger.e('DioError: ${error.message}', error: error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please check your internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        // Safely extract error message, handling cases where data might not be a Map
        String message = 'An error occurred';
        if (error.response?.data is Map) {
          message = error.response?.data['error'] ??
                   error.response?.data['message'] ??
                   'An error occurred';
        } else if (error.response?.data is String) {
          message = error.response?.data;
        }

        // Handle redirects specially
        if (statusCode == 307 || statusCode == 308) {
          final location = error.response?.headers['location']?.first;
          _logger.w('Got redirect to: $location');
          return ServerException(
            'Server redirect not followed. The profile endpoint might be on a different service.',
            statusCode,
          );
        }

        if (statusCode == 401) {
          return UnauthorizedException(message);
        }
        return ServerException(message, statusCode);

      case DioExceptionType.cancel:
        return NetworkException('Request was cancelled');

      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');

      case DioExceptionType.badCertificate:
        return NetworkException('Certificate verification failed');

      case DioExceptionType.unknown:
      default:
        return NetworkException('An unexpected error occurred: ${error.message}');
    }
  }

  // Helper method to save auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  // Helper method to save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  // Helper method to get token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  // Helper method to clear all tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}
