import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/datasources/support_remote_datasource.dart';
import 'package:gozapper/domain/repositories/support_repo.dart';
import 'package:dartz/dartz.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource remoteDataSource;

  SupportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> submitEnquiry({
    required String fullName,
    required String email,
    required String enquiry,
  }) async {
    try {
      await remoteDataSource.submitEnquiry(
        fullName: fullName,
        email: email,
        enquiry: enquiry,
      );
      return const Right(true);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
