import 'package:dartz/dartz.dart';
import 'package:gozapper/core/errors/failures.dart';
import 'package:gozapper/domain/entities/notification.dart' as notification_entity;

abstract class NotificationRepository {
  /// Get notifications with optional filtering
  ///
  /// [type] - Filter by type: 'delivery', 'payment', 'account', or null for all
  /// [limit] - Number of notifications to return (default: 20)
  /// [offset] - Pagination offset (default: 0)
  Future<Either<Failure, List<notification_entity.Notification>>> getNotifications({
    String? type,
    int limit = 20,
    int offset = 0,
  });

  /// Delete a notification by ID
  Future<Either<Failure, void>> deleteNotification(String id);
}
