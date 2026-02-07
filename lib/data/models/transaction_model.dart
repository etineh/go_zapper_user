class TransactionModel {
  final String id;
  final double amount;
  final String currency;
  final String transactionType;
  final String? paymentIntentID;
  final String? refundIntentID;
  final String? deliveryID;
  final String organizationID;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.transactionType,
    this.paymentIntentID,
    this.refundIntentID,
    this.deliveryID,
    required this.organizationID,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? json['ID'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'usd',
      transactionType: json['transactionType'] ?? json['TransactionType'] ?? 'charge',
      paymentIntentID: json['paymentIntentID'] ?? json['PaymentIntentID'],
      refundIntentID: json['refundIntentID'] ?? json['RefundIntentID'],
      deliveryID: json['deliveryID'] ?? json['DeliveryID'],
      organizationID: json['organizationID'] ?? json['OrganizationID'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['CreatedAt'] != null
              ? DateTime.parse(json['CreatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'transactionType': transactionType,
      'paymentIntentID': paymentIntentID,
      'refundIntentID': refundIntentID,
      'deliveryID': deliveryID,
      'organizationID': organizationID,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TransactionListResponseModel {
  final String message;
  final List<TransactionModel> transactions;

  TransactionListResponseModel({
    required this.message,
    required this.transactions,
  });

  factory TransactionListResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final transactionsJson = data['transactions'] as List<dynamic>? ?? [];

    return TransactionListResponseModel(
      message: json['message'] ?? '',
      transactions: transactionsJson
          .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
