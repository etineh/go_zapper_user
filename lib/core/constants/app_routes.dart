class AppRoutes {
  // Initial Route
  static const String splash = '/';

  // Auth Routes
  static const String onboarding = '/onboarding';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';
  static const String setPassword = '/set-password';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main App Routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String paymentBill = '/payment-bills';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String orders = '/orders';
  static const String orderDetails = '/order-details';
  static const String createOrder = '/create-order';
  static const String tracking = '/tracking';
  static const String trackMap = '/track-map';

  // Settings
  static const String settings = '/settings';
  static const String securitySettings = '/security-settings';
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';
  static const String help = '/help';
  static const String support = '/support';
  static const String supportSuccess = '/support-success';
  static const String aboutUs = '/about-us';

  // Payment
  static const String addPaymentMethod = '/add-payment-method';
  static const String billingManagement = '/billing-management';
}
