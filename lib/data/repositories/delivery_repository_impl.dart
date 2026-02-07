import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/datasources/delivery_remote_datasource.dart';
import 'package:gozapper/data/models/quote_request_model.dart';
import 'package:gozapper/domain/entities/delivery.dart';
import 'package:gozapper/domain/repositories/delivery_repository.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  final DeliveryRemoteDataSource remoteDataSource;

  DeliveryRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Delivery>>> getDeliveries({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final deliveries = await remoteDataSource.getDeliveries(
        startTime: startTime,
        endTime: endTime,
      );

      // Convert models to entities
      final entities = deliveries.map((model) => model.toEntity()).toList();
      return Right(entities);
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
  Future<Either<Failure, QuoteResponseModel>> generateQuote(
      QuoteRequestModel request) async {
    try {
      final quote = await remoteDataSource.generateQuote(request);
      return Right(quote);
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
  Future<Either<Failure, Delivery>> acceptQuote(String quoteId) async {
    try {
      final delivery = await remoteDataSource.acceptQuote(quoteId);
      return Right(delivery.toEntity());
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
  Future<Either<Failure, Delivery>> getDeliveryById(String deliveryId) async {
    try {
      final delivery = await remoteDataSource.getDeliveryById(deliveryId);
      return Right(delivery.toEntity());
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
  Future<Either<Failure, bool>> cancelDelivery(String deliveryId, String reason) async {
    try {
      final result = await remoteDataSource.cancelDelivery(deliveryId, reason);
      return Right(result);
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
