import 'package:dio/dio.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/network/api_client.dart';
import 'package:gozapper/data/models/notification_model.dart';
import 'package:logger/logger.dart';

abstract class NotificationRemoteDataSource {
  /// Get notifications with optional filtering
  ///
  /// [type] - Filter by type: 'delivery', 'payment', 'account', or null for all
  /// [limit] - Number of notifications to return (default: 20)
  /// [offset] - Pagination offset (default: 0)
  Future<List<NotificationModel>> getNotifications({
    String? type,
    int limit = 20,
    int offset = 0,
  });

  /// Delete a notification by ID
  Future<void> deleteNotification(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;
  final Logger _logger;

  NotificationRemoteDataSourceImpl({
    required this.apiClient,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  Exception _handleDioError(DioException error) {
    _logger.e('DioError: ${error.message}', error: error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
            'Connection timeout. Please check your internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ??
            error.response?.data['error'] ??
            'An error occurred';

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
        return NetworkException(
            'An unexpected error occurred: ${error.message}');
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParameters = {
        'limit': limit,
        'offset': offset,
        if (type != null) 'type': type,
      };

      final response = await apiClient.get(
        AppConstants.notificationEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle response format: { "data": { "notifications": [...] } }
        final List<dynamic> notificationsJson;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final dataObj = data['data'];
          if (dataObj is Map<String, dynamic> &&
              dataObj.containsKey('notifications')) {
            final notifs = dataObj['notifications'];
            if (notifs == null) {
              _logger.w('Notifications is null in response');
              return [];
            }
            notificationsJson = notifs as List<dynamic>;
          } else {
            _logger.w('No notifications key in data: $dataObj');
            return [];
          }
        } else if (data is Map<String, dynamic> &&
            data.containsKey('notifications')) {
          final notifs = data['notifications'];
          if (notifs == null) {
            _logger.w('Notifications is null in response');
            return [];
          }
          notificationsJson = notifs as List<dynamic>;
        } else if (data is List) {
          notificationsJson = data;
        } else {
          _logger.w('Unexpected response format: $data');
          return [];
        }

        return notificationsJson
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch notifications',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError fetching notifications: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error fetching notifications: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      final response = await apiClient.delete(
        '${AppConstants.notificationEndpoint}/$id',
      );

      if (response.statusCode != 200) {
        throw ServerException(
          response.data['message'] ?? 'Failed to delete notification',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError deleting notification: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error deleting notification: $e');
      rethrow;
    }
  }
}
