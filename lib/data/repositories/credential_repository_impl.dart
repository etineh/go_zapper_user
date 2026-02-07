import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/datasources/credential_remote_datasource.dart';
import 'package:gozapper/domain/entities/credential.dart';
import 'package:gozapper/domain/repositories/credential_repository.dart';

class CredentialRepositoryImpl implements CredentialRepository {
  final CredentialRemoteDataSource remoteDataSource;

  CredentialRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Credential>>> getCredentials() async {
    try {
      final credentials = await remoteDataSource.getCredentials();
      final entities = credentials.map((model) => model.toEntity()).toList();
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
  Future<Either<Failure, Credential>> getActiveCredential() async {
    try {
      final credential = await remoteDataSource.getActiveCredential();
      return Right(credential.toEntity());
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
  Future<Either<Failure, Credential>> createSandboxCredential(String name) async {
    try {
      final credential = await remoteDataSource.createSandboxCredential(name);
      return Right(credential.toEntity());
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
  Future<Either<Failure, Credential>> createProductionCredential(String name) async {
    try {
      final credential = await remoteDataSource.createProductionCredential(name);
      return Right(credential.toEntity());
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
  Future<Either<Failure, bool>> updateCredentialStatus(String id, bool status) async {
    try {
      final result = await remoteDataSource.updateCredentialStatus(id, status);
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
