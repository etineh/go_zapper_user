import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/datasources/notification_remote_datasource.dart';
import 'package:gozapper/domain/entities/notification.dart';
import 'package:gozapper/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Notification>>> getNotifications({
    String? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final notifications = await remoteDataSource.getNotifications(
        type: type,
        limit: limit,
        offset: offset,
      );
      final entities = notifications.map((model) => model.toEntity()).toList();
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
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      await remoteDataSource.deleteNotification(id);
      return const Right(null);
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
