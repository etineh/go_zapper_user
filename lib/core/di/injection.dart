import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gozapper/core/network/api_client.dart';
import 'package:gozapper/data/datasources/auth_local_datasource.dart';
import 'package:gozapper/data/datasources/auth_remote_datasource.dart';
import 'package:gozapper/data/datasources/credential_remote_datasource.dart';
import 'package:gozapper/data/datasources/delivery_remote_datasource.dart';
import 'package:gozapper/data/datasources/payment_method_remote_datasource.dart';
import 'package:gozapper/data/repositories/auth_repository_impl.dart';
import 'package:gozapper/data/repositories/credential_repository_impl.dart';
import 'package:gozapper/data/repositories/delivery_repository_impl.dart';
import 'package:gozapper/data/repositories/payment_method_repository_impl.dart';
import 'package:gozapper/domain/repositories/auth_repository.dart';
import 'package:gozapper/domain/repositories/credential_repository.dart';
import 'package:gozapper/domain/repositories/delivery_repository.dart';
import 'package:gozapper/domain/repositories/payment_method_repository.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/providers/credential_provider.dart';
import 'package:gozapper/presentation/providers/delivery_provider.dart';
import 'package:gozapper/presentation/providers/payment_method_provider.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Injection {
  static late final SharedPreferences _sharedPreferences;
  static late final FlutterSecureStorage _secureStorage;
  static late final Logger _logger;
  static late final ApiClient _apiClient;

  // Data sources
  static late final AuthLocalDataSource _authLocalDataSource;
  static late final AuthRemoteDataSource _authRemoteDataSource;
  static late final CredentialRemoteDataSource _credentialRemoteDataSource;
  static late final DeliveryRemoteDataSource _deliveryRemoteDataSource;
  static late final PaymentMethodRemoteDataSource _paymentMethodRemoteDataSource;

  // Repositories
  static late final AuthRepository _authRepository;
  static late final CredentialRepository _credentialRepository;
  static late final DeliveryRepository _deliveryRepository;
  static late final PaymentMethodRepository _paymentMethodRepository;

  // Providers
  static late final AuthProvider authProvider;
  static late final CredentialProvider credentialProvider;
  static late final DeliveryProvider deliveryProvider;
  static late final PaymentMethodProvider paymentMethodProvider;

  static Future<void> init() async {
    // Core
    _sharedPreferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
      ),
    );

    // API Client (session expiration callback will be set after authProvider is created)
    _apiClient = ApiClient(
      storage: _secureStorage,
      logger: _logger,
    );

    // Data sources
    _authLocalDataSource = AuthLocalDataSourceImpl(
      sharedPreferences: _sharedPreferences,
    );

    _authRemoteDataSource = AuthRemoteDataSourceImpl(
      apiClient: _apiClient,
    );

    _credentialRemoteDataSource = CredentialRemoteDataSourceImpl(
      storage: _secureStorage,
      logger: _logger,
    );

    _deliveryRemoteDataSource = DeliveryRemoteDataSourceImpl(
      apiClient: _apiClient,
      storage: _secureStorage,
      logger: _logger,
    );

    _paymentMethodRemoteDataSource = PaymentMethodRemoteDataSourceImpl(
      apiClient: _apiClient,
    );

    // Repositories
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: _authRemoteDataSource,
      localDataSource: _authLocalDataSource,
    );

    _credentialRepository = CredentialRepositoryImpl(
      remoteDataSource: _credentialRemoteDataSource,
    );

    _deliveryRepository = DeliveryRepositoryImpl(
      remoteDataSource: _deliveryRemoteDataSource,
    );

    _paymentMethodRepository = PaymentMethodRepositoryImpl(
      remoteDataSource: _paymentMethodRemoteDataSource,
    );

    // Providers
    // Note: Create credentialProvider first so it can be injected into authProvider
    credentialProvider = CredentialProvider(credentialRepository: _credentialRepository);
    authProvider = AuthProvider(
      authRepository: _authRepository,
      credentialProvider: credentialProvider,
    );
    deliveryProvider = DeliveryProvider(deliveryRepository: _deliveryRepository);
    paymentMethodProvider = PaymentMethodProvider(paymentMethodRepository: _paymentMethodRepository);

    // Inject delivery and payment method providers into auth provider for clearing user data on logout
    authProvider.setDeliveryProvider(deliveryProvider);
    authProvider.setPaymentMethodProvider(paymentMethodProvider);

    // Set up session expiration callback for ApiClient
    _apiClient.onSessionExpired = () {
      authProvider.handleSessionExpired();
    };

    // Initialize auth provider (will also load credentials if already logged in)
    await authProvider.initialize();
  }

  // Getters for dependencies if needed elsewhere
  static ApiClient get apiClient => _apiClient;
  static Logger get logger => _logger;
  static SharedPreferences get sharedPreferences => _sharedPreferences;
  static FlutterSecureStorage get secureStorage => _secureStorage;
}
