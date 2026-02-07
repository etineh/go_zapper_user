import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  });

  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String otp,
  });

  Future<Either<Failure, bool>> resendOtp({
    required String email,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User?>> getCurrentUser();

  Future<Either<Failure, bool>> isLoggedIn();

  Future<Either<Failure, User>> getProfile();

  Future<Either<Failure, User>> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? photoUrl,
  });

  Future<Either<Failure, Map<String, dynamic>>> exportProfile();

  Future<Either<Failure, void>> deleteAccount();

  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, String>> forgotPassword({
    required String email,
  });

  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
