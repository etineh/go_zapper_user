import 'package:gozapper/domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.organizationId,
    required super.type,
    required super.title,
    required super.message,
    required super.referenceId,
    required super.referenceType,
    required super.data,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null || date == '') return DateTime.now();
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return NotificationModel(
      id: json['id'] ?? '',
      organizationId: json['organizationID'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      referenceId: json['referenceID'] ?? '',
      referenceType: json['referenceType'] ?? '',
      data: (json['data'] ?? {}) as Map<String, dynamic>,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationID': organizationId,
      'type': type,
      'title': title,
      'message': message,
      'referenceID': referenceId,
      'referenceType': referenceType,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Notification toEntity() {
    return Notification(
      id: id,
      organizationId: organizationId,
      type: type,
      title: title,
      message: message,
      referenceId: referenceId,
      referenceType: referenceType,
      data: data,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
