import 'package:gozapper/domain/entities/credential.dart';

class CredentialModel extends Credential {
  const CredentialModel({
    required super.id,
    required super.apiKey,
    required super.environment,
    required super.status,
    required super.organizationId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null || date == '') return DateTime.now();
      if (date is String) {
        try {
          if (date.startsWith('0001-01-01')) {
            return DateTime.now();
          }
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return CredentialModel(
      id: json['ID'] ?? json['id'] ?? '',
      apiKey: json['APIKey'] ?? json['apiKey'] ?? '',
      environment: json['Environment'] ?? json['environment'] ?? 'sandbox',
      status: json['Status'] ?? json['status'] ?? false,
      organizationId: json['OrganizationID'] ?? json['organizationId'] ?? '',
      createdAt: parseDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: parseDate(json['UpdatedAt'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'APIKey': apiKey,
      'Environment': environment,
      'Status': status,
      'OrganizationID': organizationId,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }

  Credential toEntity() {
    return Credential(
      id: id,
      apiKey: apiKey,
      environment: environment,
      status: status,
      organizationId: organizationId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
