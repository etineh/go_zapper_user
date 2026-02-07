import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/data/models/credential_model.dart';
import 'package:logger/logger.dart';

abstract class CredentialRemoteDataSource {
  Future<List<CredentialModel>> getCredentials();
  Future<CredentialModel> getActiveCredential();
  Future<CredentialModel> createSandboxCredential(String name);
  Future<CredentialModel> createProductionCredential(String name);
  Future<bool> updateCredentialStatus(String id, bool status);
}

class CredentialRemoteDataSourceImpl implements CredentialRemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger;

  CredentialRemoteDataSourceImpl({
    Dio? dio,
    FlutterSecureStorage? storage,
    Logger? logger,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _logger = logger ?? Logger(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(
                    milliseconds: AppConstants.connectionTimeout),
                receiveTimeout:
                    const Duration(milliseconds: AppConstants.receiveTimeout),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<List<CredentialModel>> getCredentials() async {
    try {
      final response = await _dio.get(AppConstants.credentialsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle response format: { "data": { "credentials": [...] } }
        final List<dynamic> credentialsJson;
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final dataObj = data['data'];
          if (dataObj is Map<String, dynamic> &&
              dataObj.containsKey('credentials')) {
            credentialsJson = dataObj['credentials'] as List<dynamic>;
          } else {
            _logger.w('No credentials key in data: $dataObj');
            return [];
          }
        } else if (data is Map<String, dynamic> &&
            data.containsKey('credentials')) {
          credentialsJson = data['credentials'] as List<dynamic>;
        } else if (data is List) {
          credentialsJson = data;
        } else {
          _logger.w('Unexpected credentials response format: $data');
          return [];
        }

        _logger.i('📋 Credentials JSON: $credentialsJson');

        final credentials = credentialsJson.map((json) {
          _logger.i('🔍 Parsing credential JSON: $json');
          final credential =
              CredentialModel.fromJson(json as Map<String, dynamic>);
          _logger.i(
              '✅ Parsed credential - ID: ${credential.id}, Environment: ${credential.environment}');
          return credential;
        }).toList();

        return credentials;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch credentials',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError fetching credentials: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error fetching credentials: $e');
      rethrow;
    }
  }

  @override
  Future<CredentialModel> getActiveCredential() async {
    try {
      // First, try to get from storage
      final storedApiKey = await _storage.read(key: AppConstants.apiKeyKey);
      final storedEnvironment =
          await _storage.read(key: AppConstants.apiKeyEnvironmentKey);

      if (storedApiKey != null && storedEnvironment != null) {
        _logger.i('Using stored API key for $storedEnvironment environment');
        // Return a credential model from stored data
        return CredentialModel(
          id: '',
          apiKey: storedApiKey,
          environment: storedEnvironment,
          status: true,
          organizationId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // If not in storage, fetch from API and find active one
      final credentials = await getCredentials();

      // Try to find active credential
      final activeCredential = credentials.firstWhere(
        (c) => c.status,
        orElse: () {
          // If no active credential, use sandbox as default
          final sandboxCred = credentials.firstWhere(
            (c) => c.environment == 'sandbox',
            orElse: () => credentials.isNotEmpty
                ? credentials.first
                : throw ServerException('No credentials available', 404),
          );
          return sandboxCred;
        },
      );

      // Store the active credential
      await _storage.write(
          key: AppConstants.apiKeyKey, value: activeCredential.apiKey);
      await _storage.write(
          key: AppConstants.apiKeyEnvironmentKey,
          value: activeCredential.environment);

      return activeCredential;
    } on DioException catch (e) {
      _logger.e('DioError fetching active credential: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error fetching active credential: $e');
      rethrow;
    }
  }

  @override
  Future<CredentialModel> createSandboxCredential(String name) async {
    try {
      _logger.i('Creating sandbox credential with name: $name');

      final response = await _dio.post(
        '/credential/sandbox',
        data: {'name': name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('✅ Sandbox credential created successfully');
        _logger.i('📦 Response data: ${response.data}');

        // Extract data from response
        final data = response.data['data'] ?? {};
        final apiKey = data['apiKey'] ?? '';
        final credentialId = data['ID'] ?? data['id'] ?? '';

        _logger.i('📝 Credential ID: $credentialId');
        _logger.i(
            '📝 API Key: ${apiKey.isNotEmpty ? apiKey.substring(0, apiKey.length < 20 ? apiKey.length : 20) : "EMPTY"}...');
        _logger.i('📝 API Key length: ${apiKey.length}');

        // Store as active credential
        await _storage.write(key: AppConstants.apiKeyKey, value: apiKey);
        await _storage.write(
            key: AppConstants.apiKeyEnvironmentKey, value: 'sandbox');

        // Create a minimal credential model for return
        final credential = CredentialModel(
          id: credentialId,
          apiKey: apiKey,
          environment: 'sandbox',
          status: true,
          organizationId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return credential;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to create sandbox credential',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError creating sandbox credential: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error creating sandbox credential: $e');
      rethrow;
    }
  }

  @override
  Future<CredentialModel> createProductionCredential(String name) async {
    try {
      _logger.i('Creating production credential with name: $name');

      final response = await _dio.post(
        '/credential/production',
        data: {'name': name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('✅ Production credential created successfully');
        _logger.i('📦 Response data: ${response.data}');

        // Extract data from response
        final data = response.data['data'] ?? {};
        final apiKey = data['apiKey'] ?? '';
        final credentialId = data['ID'] ?? data['id'] ?? '';

        _logger.i('📝 Credential ID: $credentialId');
        _logger.i(
            '📝 API Key: ${apiKey.isNotEmpty ? apiKey.substring(0, apiKey.length < 20 ? apiKey.length : 20) : "EMPTY"}...');
        _logger.i('📝 API Key length: ${apiKey.length}');

        // Store as active credential
        await _storage.write(key: AppConstants.apiKeyKey, value: apiKey);
        await _storage.write(
            key: AppConstants.apiKeyEnvironmentKey, value: 'production');

        // Create a minimal credential model for return
        final credential = CredentialModel(
          id: credentialId,
          apiKey: apiKey,
          environment: 'production',
          status: true,
          organizationId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return credential;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to create production credential',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError creating production credential: ${e.message}',
          error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error creating production credential: $e');
      rethrow;
    }
  }

  @override
  Future<bool> updateCredentialStatus(String id, bool status) async {
    try {
      _logger.i('Updating credential status: $id to $status');

      final response = await _dio.patch(
        '/credential/status/$id',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Credential status updated successfully');
        return true;
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to update credential status',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.e('DioError updating credential status: ${e.message}', error: e);
      throw _handleDioError(e);
    } catch (e) {
      _logger.e('Error updating credential status: $e');
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
}
