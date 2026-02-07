import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String organizationId;
  final String type; // delivery, payment, account
  final String title;
  final String message;
  final String referenceId;
  final String referenceType; // delivery, transaction, account
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notification({
    required this.id,
    required this.organizationId,
    required this.type,
    required this.title,
    required this.message,
    required this.referenceId,
    required this.referenceType,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this is a delivery notification
  bool get isDelivery => type.toLowerCase() == 'delivery';

  /// Check if this is a payment notification
  bool get isPayment => type.toLowerCase() == 'payment';

  /// Check if this is an account notification
  bool get isAccount => type.toLowerCase() == 'account';

  /// Get human-readable time ago (e.g., "2h ago", "Yesterday")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return createdAt.toString().split(' ')[0];
    }
  }

  /// Get date grouping label
  String get dateGroup {
    final now = DateTime.now();
    final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = DateTime(now.year, now.month, now.day - 1);
    final weekAgoDate = DateTime(now.year, now.month, now.day - 7);

    if (notificationDate == todayDate) {
      return 'Today';
    } else if (notificationDate == yesterdayDate) {
      return 'Yesterday';
    } else if (notificationDate.isAfter(weekAgoDate)) {
      return 'This Week';
    } else {
      return 'Earlier';
    }
  }

  @override
  List<Object?> get props => [
    id,
    organizationId,
    type,
    title,
    message,
    referenceId,
    referenceType,
    data,
    createdAt,
    updatedAt,
  ];
}
