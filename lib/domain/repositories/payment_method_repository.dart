import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/models/payment_method_model.dart';
import 'package:gozapper/data/models/transaction_model.dart';

abstract class PaymentMethodRepository {
  Future<Either<Failure, PaymentMethodResponseModel>> savePaymentMethod(
      PaymentMethodRequestModel request);
  Future<Either<Failure, PaymentMethodDetailsResponseModel>> getPaymentMethodDetails();
  Future<Either<Failure, TransactionListResponseModel>> getTransactions({
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
