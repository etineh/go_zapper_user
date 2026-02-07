import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/datasources/payment_method_remote_datasource.dart';
import 'package:gozapper/data/models/payment_method_model.dart';
import 'package:gozapper/data/models/transaction_model.dart';
import 'package:gozapper/domain/repositories/payment_method_repository.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodRemoteDataSource remoteDataSource;

  PaymentMethodRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaymentMethodResponseModel>> savePaymentMethod(
      PaymentMethodRequestModel request) async {
    try {
      final response = await remoteDataSource.savePaymentMethod(request);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PaymentMethodDetailsResponseModel>> getPaymentMethodDetails() async {
    try {
      final response = await remoteDataSource.getPaymentMethodDetails();
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, TransactionListResponseModel>> getTransactions({
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
      final response = await remoteDataSource.getTransactions(
        transactionType: transactionType,
        paymentIntentID: paymentIntentID,
        refundIntentID: refundIntentID,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
        limit: limit,
        page: page,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }
}
