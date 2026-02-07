import 'package:dartz/dartz.dart';
import 'package:gozapper/data/models/quote_request_model.dart';
import 'package:gozapper/domain/entities/delivery.dart';

import '../../core/errors/failures.dart';

abstract class DeliveryRepository {
  Future<Either<Failure, List<Delivery>>> getDeliveries({
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Generate a delivery quote
  Future<Either<Failure, QuoteResponseModel>> generateQuote(
      QuoteRequestModel request);

  /// Accept a quote and create a delivery
  Future<Either<Failure, Delivery>> acceptQuote(String quoteId);

  /// Get a single delivery by ID for tracking
  Future<Either<Failure, Delivery>> getDeliveryById(String deliveryId);

  /// Cancel a delivery
  Future<Either<Failure, bool>> cancelDelivery(String deliveryId, String reason);
}
