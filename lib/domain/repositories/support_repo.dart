import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/failures.dart';

abstract class SupportRepository {
  Future<Either<Failure, bool>> submitEnquiry({
    required String fullName,
    required String email,
    required String enquiry,
  });
}
