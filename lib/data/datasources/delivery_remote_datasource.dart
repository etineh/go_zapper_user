import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/network/api_client.dart';
import 'package:gozapper/data/models/delivery_model.dart';
import 'package:gozapper/data/models/quote_request_model.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

abstract class DeliveryRemoteDataSource {
  Future<List<DeliveryModel>> getDeliveries({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Generate a delivery quote
  Future<QuoteResponseModel> generateQuote(QuoteRequestModel request);

  /// Accept a quote and create a delivery
  Future<DeliveryModel> acceptQuote(String quoteId);

  /// Get a single delivery by ID
  Future<DeliveryModel> getDeliveryById(String deliveryId);

  /// Cancel a delivery
  Future<bool> cancelDelivery(String deliveryId, String reason);
}

class DeliveryRemoteDataSourceImpl implements DeliveryRemoteDataSource {
  late final Dio _dio; // For Delivery service (API Key auth)
  final ApiClient apiClient; // For Organization API (Bearer token auth)
  final FlutterSecureStorage _storage;
  final Logger _logger;

  DeliveryRemoteDataSourceImpl({
    required this.apiClient,
    FlutterSecureStorage? storage,
    Logger? logger,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _logger = logger ?? Logger() {
    // Dio instance for Delivery service (quote operations with API Key)
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.deliveryBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for API Key authentication (Delivery service only)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add API Key as Bearer token to requests for delivery service
          final apiKey = await _storage.read(key: AppConstants.apiKeyKey);
          print('🔑 Delivery API - API Key found: ${apiKey != null}');
          if (apiKey != null && apiKey.isNotEmpty) {
            print('🔍 API Key length: ${apiKey.length}');
            print(
                '🔍 API Key prefix: ${apiKey.substring(0, apiKey.length < 20 ? apiKey.length : 20)}...');
            print('✅ Adding Authorization Bearer header to delivery request');
            options.headers['Authorization'] = 'Bearer $apiKey';
          } else {
            print('⚠️ WARNING: No API key found or empty!');
          }
          return handler.next(options);
        },
      ),
    );

    // Add pretty logger to delivery service Dio
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

  Future<void> _handleUnauthorized() async {
    // Clear tokens
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<List<DeliveryModel>> getDeliveries({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Use apiClient for delivery history (organization service endpoint with Bearer token)
      final response = await apiClient.get(
        AppConstants.deliveriesEndpoint,
        queryParameters: {
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'limit': 50, // adjust later for pagination
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle response format: { "data": { "deliveries": [...] } }
        final List<dynamic> deliveriesJson;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final dataObj = data['data'];
          if (dataObj is Map<String, dynamic> &&
              dataObj.containsKey('deliveries')) {
            deliveriesJson = dataObj['deliveries'] as List<dynamic>;
          } else {
            _logger.w('No deliveries key in data: $dataObj');
            return [];
          }
        } else if (data is Map<String, dynamic> &&
            data.containsKey('deliveries')) {
          deliveriesJson = data['deliveries'] as List<dynamic>;
        } else if (data is List) {
          deliveriesJson = data;
        } else {
          _logger.w('Unexpected response format: $data');
          return [];
        }

        return deliveriesJson
            .map((json) => DeliveryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch deliveries',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError fetching deliveries: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error fetching deliveries: $e');
      rethrow;
    }
  }

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
  Future<QuoteResponseModel> generateQuote(QuoteRequestModel request) async {
    try {
      final response = await _dio.post(
        '/quote',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return QuoteResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to generate quote',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError generating quote: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error generating quote: $e');
      rethrow;
    }
  }

  @override
  Future<DeliveryModel> acceptQuote(String quoteId) async {
    try {
      final response = await _dio.post(
        '/quote/$quoteId/accept',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response using AcceptQuoteResponseModel to extract delivery data
        final acceptQuoteResponse =
            AcceptQuoteResponseModel.fromJson(response.data);
        // Now parse the delivery data into DeliveryModel
        return DeliveryModel.fromJson(acceptQuoteResponse.delivery);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to accept quote',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError accepting quote: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error accepting quote: $e');
      rethrow;
    }
  }

  @override
  Future<DeliveryModel> getDeliveryById(String deliveryId) async {
    try {
      // Use apiClient for delivery tracking (organization service endpoint with Bearer token)
      final response = await apiClient.get(
        '${AppConstants.deliveriesEndpoint}/$deliveryId',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle response format: { "data": { "delivery": { ... delivery object ... } } }
        Map<String, dynamic> deliveryJson;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final dataObj = data['data'];
          if (dataObj is Map<String, dynamic> &&
              dataObj.containsKey('delivery')) {
            deliveryJson = dataObj['delivery'] as Map<String, dynamic>;
          } else {
            deliveryJson = dataObj as Map<String, dynamic>;
          }
        } else {
          deliveryJson = data as Map<String, dynamic>;
        }

        return DeliveryModel.fromJson(deliveryJson);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch delivery',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError fetching delivery by ID: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error fetching delivery by ID: $e');
      rethrow;
    }
  }

  @override
  Future<bool> cancelDelivery(String deliveryId, String reason) async {
    try {
      // Use _dio for delivery service (API Key auth) instead of apiClient
      final response = await _dio.post(
        '/cancel/$deliveryId',
        data: {'reason': reason},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('✅ Delivery cancelled successfully');
        return true;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to cancel delivery',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError cancelling delivery: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error cancelling delivery: $e');
      rethrow;
    }
  }
}
