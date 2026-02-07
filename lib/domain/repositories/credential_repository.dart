import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/domain/entities/credential.dart';

abstract class CredentialRepository {
  Future<Either<Failure, List<Credential>>> getCredentials();
  Future<Either<Failure, Credential>> getActiveCredential();
  Future<Either<Failure, Credential>> createSandboxCredential(String name);
  Future<Either<Failure, Credential>> createProductionCredential(String name);
  Future<Either<Failure, bool>> updateCredentialStatus(String id, bool status);
}
