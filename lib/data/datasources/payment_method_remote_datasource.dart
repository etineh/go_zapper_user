import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/network/api_client.dart';
import 'package:gozapper/data/models/payment_method_model.dart';
import 'package:gozapper/data/models/transaction_model.dart';

abstract class PaymentMethodRemoteDataSource {
  Future<PaymentMethodResponseModel> savePaymentMethod(PaymentMethodRequestModel request);
  Future<PaymentMethodDetailsResponseModel> getPaymentMethodDetails();
  Future<TransactionListResponseModel> getTransactions({
    String? transactionType,
    String? paymentIntentID,
    String? refundIntentID,
    String? startDate,
    String? endDate,
    String? currency,
    int? limit,
    int? page,
  });
}

class PaymentMethodRemoteDataSourceImpl implements PaymentMethodRemoteDataSource {
  final ApiClient apiClient;

  PaymentMethodRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PaymentMethodResponseModel> savePaymentMethod(
      PaymentMethodRequestModel request) async {
    try {
      final response = await apiClient.post(
        '/payment',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentMethodResponseModel.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : {'success': true, 'message': 'Payment method added successfully'},
        );
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to save payment method',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaymentMethodDetailsResponseModel> getPaymentMethodDetails() async {
    try {
      final response = await apiClient.get('/payment/method');

      if (response.statusCode == 200) {
        return PaymentMethodDetailsResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch payment method details',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TransactionListResponseModel> getTransactions({
    String? transactionType,
    String? paymentIntentID,
    String? refundIntentID,
    String? startDate,
    String? endDate,
    String? currency,
    int? limit,
    int? page,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (transactionType != null) queryParams['transactionType'] = transactionType;
      if (paymentIntentID != null) queryParams['paymentIntentID'] = paymentIntentID;
      if (refundIntentID != null) queryParams['refundIntentID'] = refundIntentID;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (currency != null) queryParams['currency'] = currency;
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;

      final response = await apiClient.get(
        '/payment/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return TransactionListResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          response.data['message'] ?? 'Failed to fetch transactions',
          response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
