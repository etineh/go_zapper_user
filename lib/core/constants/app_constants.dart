class AppConstants {
  // App Info
  static const String appName = 'GoZapper';
  static const String appTagline = 'Need it fast? Just Zap it!';

  static const String appVersion = '1.0.0';

  // Local API Configuration - Android emulator uses 10.0.2.2 instead of localhost
  // static const String baseUrl = 'http://10.0.2.2:5001/api/v1';
  // static const String deliveryBaseUrl = 'http://10.0.2.2:5003/api/v1';
  // static const String notificationBaseUrl = 'http://10.0.2.2:5002/api/v1';
  // static const String paymentBaseUrl = 'http://10.0.2.2:5004/api/v1';
  // static const String organizationBaseUrl = 'http://10.0.2.2:5005/api/v1';

  // Remote API Configuration
  static const String baseUrl =
      'https://gozapper-organization.onrender.com/api/v1';
  static const String deliveryBaseUrl =
      'https://gozapper-delivery.onrender.com/api/v1';
  static const String notificationBaseUrl =
      'https://gozapper-notification.onrender.com/api/v1';
  static const String paymentBaseUrl =
      'https://gozapper-payment.onrender.com/api/v1';
  static const String organizationBaseUrl =
      'https://gozapper-organization.onrender.com/api/v1';

  // API Endpoints
  static const String authenticationEndpoint = '/authentication';
  static const String registerEndpoint = '/authentication/signup';
  static const String loginEndpoint = '/authentication/login';
  static const String verifyOtpEndpoint = '/authentication/verify/email';
  static const String resendOtpEndpoint = '/authentication/verify/resend';
  static const String refreshTokenEndpoint = '/authentication/token';
  static const String logoutEndpoint = '/authentication/logout';
  static const String profileEndpoint = '/profile/';
  static const String profileExportEndpoint = '/profile/export';
  static const String deviceTokenEndpoint = '/profile/device-token';
  static const String deliveriesEndpoint = '/delivery';
  static const String credentialsEndpoint = '/credential';
  static const String notificationEndpoint = '/notification';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String apiKeyKey = 'active_api_key';
  static const String apiKeyEnvironmentKey = 'api_key_environment';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // OTP
  static const int otpLength = 6;
  static const int otpResendDelay = 60; // seconds

  // Phone Number
  static const String defaultCountryCode = 'US';
  static const List<String> supportedCountries = ['US', 'NG', 'FR'];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Stripe Configuration
  static const String stripePublishableKey =
      'pk_test_51SWhc0Qj4OfczuROnLvAzJbGThrgjZ92yYlCKssMv9dq4tUaC4iEF0TNxsRBQCcdEiL00XYnA7HciW8knMaZjc6900b27rUph2';

  // Vehicle Types
  static const String vehicleTypeMotorcycle = 'Bike';
  static const String vehicleTypeCar = 'Car';
  static const String vehicleTypeVan = 'Van';
  static const String vehicleTypeTruck = 'Truck';

  static const List<String> vehicleTypes = [
    vehicleTypeMotorcycle,
    vehicleTypeCar,
    vehicleTypeVan,
    vehicleTypeTruck,
  ];

  // what to display on the UI list for vehicle types
  static const Map<String, String> vehicleTypeLabels = {
    vehicleTypeMotorcycle: 'Bike',
    vehicleTypeCar: 'Car',
    vehicleTypeVan: 'Van',
    vehicleTypeTruck: 'Truck',
  };
}
