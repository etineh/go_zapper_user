/// Model for payment method setup request
class PaymentMethodRequestModel {
  final String paymentMethodToken;

  PaymentMethodRequestModel({
    required this.paymentMethodToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentMethodToken': paymentMethodToken,
    };
  }
}

/// Model for payment method setup response
class PaymentMethodResponseModel {
  final bool success;
  final String message;
  final String? paymentMethodId;

  PaymentMethodResponseModel({
    required this.success,
    required this.message,
    this.paymentMethodId,
  });

  factory PaymentMethodResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResponseModel(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Payment method added successfully',
      paymentMethodId: json['paymentMethodId'] ?? json['PaymentMethodID'],
    );
  }
}

/// Model for payment method details
class PaymentMethodDetailsModel {
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  PaymentMethodDetailsModel({
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  factory PaymentMethodDetailsModel.fromJson(Map<String, dynamic> json) {
    final paymentMethod = json['paymentMethod'] ?? json;

    return PaymentMethodDetailsModel(
      brand: paymentMethod['brand'] ?? 'card',
      last4: paymentMethod['last4'] ?? '****',
      expMonth: paymentMethod['expMonth'] ?? 0,
      expYear: paymentMethod['expYear'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'last4': last4,
      'expMonth': expMonth,
      'expYear': expYear,
    };
  }
}

/// Model for payment method details response
class PaymentMethodDetailsResponseModel {
  final String message;
  final PaymentMethodDetailsModel paymentMethod;

  PaymentMethodDetailsResponseModel({
    required this.message,
    required this.paymentMethod,
  });

  factory PaymentMethodDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return PaymentMethodDetailsResponseModel(
      message: json['message'] ?? '',
      paymentMethod: PaymentMethodDetailsModel.fromJson(data),
    );
  }
}
