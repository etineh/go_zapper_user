import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/exceptions.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/data/datasources/auth_local_datasource.dart';
import 'package:gozapper/data/datasources/auth_remote_datasource.dart';
import 'package:gozapper/domain/entities/user.dart';
import 'package:gozapper/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final authResponse = await remoteDataSource.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      if (authResponse.user != null) {
        await localDataSource.cacheUser(authResponse.user!);
        await localDataSource.setLoggedIn(true);
        return Right(authResponse.user!.toEntity());
      } else {
        // Registration successful but user data not returned (email verification required)
        // Create a temporary user object with the registration data
        final tempUser = User(
          id: '',
          email: email,
          firstName: firstName,
          lastName: lastName,
          fullName: '$firstName $lastName',
          phoneNumber: phoneNumber,
          emailVerified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return Right(tempUser);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await remoteDataSource.login(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        await localDataSource.cacheUser(authResponse.user!);
        await localDataSource.setLoggedIn(true);
        return Right(authResponse.user!.toEntity());
      } else {
        return const Left(
            ServerFailure('Login successful but user data not returned'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final result = await remoteDataSource.verifyOtp(
        email: email,
        otp: otp,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> resendOtp({
    required String email,
  }) async {
    try {
      final result = await remoteDataSource.resendOtp(email: email);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call remote logout endpoint to invalidate session on server
      await remoteDataSource.logout();

      // Clear local cache and logged-in status
      await localDataSource.clearCache();
      await localDataSource.setLoggedIn(false);
      return const Right(null);
    } on ServerException catch (e) {
      // Even if server logout fails, clear local data
      await localDataSource.clearCache();
      await localDataSource.setLoggedIn(false);
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      // Even if network fails, clear local data
      await localDataSource.clearCache();
      await localDataSource.setLoggedIn(false);
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      // Even if logout fails, clear local data
      await localDataSource.clearCache();
      await localDataSource.setLoggedIn(false);
      return Left(CacheFailure('Failed to logout: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getCachedUser();
      if (userModel != null) {
        return Right(userModel.toEntity());
      }
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      // Check both the logged-in flag AND if token exists
      final isLoggedIn = await localDataSource.isLoggedIn();

      if (!isLoggedIn) {
        print('🔍 Auth check - isLoggedIn flag: false');
        return const Right(false);
      }

      // Also verify token exists in secure storage
      final token = await remoteDataSource.getStoredToken();
      print('🔍 Auth check - isLoggedIn flag: $isLoggedIn, hasToken: ${token != null}');

      if (token == null) {
        print('⚠️ User flag is true but token is missing! Clearing cached data...');
        // Token missing but flag is true - clear everything to force re-login
        await localDataSource.clearCache();
        await localDataSource.setLoggedIn(false);
        return const Right(false);
      }

      print('✅ Auth check passed - user is logged in with valid token');
      return const Right(true);
    } catch (e) {
      print('❌ Error checking auth status: $e');
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final authResponse = await remoteDataSource.getProfile();

      if (authResponse.user != null) {
        // Update cached user with latest data
        await localDataSource.cacheUser(authResponse.user!);
        return Right(authResponse.user!.toEntity());
      } else {
        return const Left(ServerFailure('Failed to fetch profile'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    try {
      final authResponse = await remoteDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
      );

      if (authResponse.user != null) {
        // Update cached user with latest data
        await localDataSource.cacheUser(authResponse.user!);
        return Right(authResponse.user!.toEntity());
      } else {
        return const Left(ServerFailure('Failed to update profile'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportProfile() async {
    try {
      final data = await remoteDataSource.exportProfile();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      // Call remote delete endpoint
      await remoteDataSource.deleteAccount();

      // Clear local cache and logged-in status after successful deletion
      await localDataSource.clearCache();
      await localDataSource.setLoggedIn(false);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final message = await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword({
    required String email,
  }) async {
    try {
      final message = await remoteDataSource.forgotPassword(
        email: email,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final message = await remoteDataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }
}
