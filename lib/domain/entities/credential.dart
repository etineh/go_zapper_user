import 'package:equatable/equatable.dart';

class Credential extends Equatable {
  final String id;
  final String apiKey;
  final String environment; // 'sandbox' or 'production'
  final bool status;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Credential({
    required this.id,
    required this.apiKey,
    required this.environment,
    required this.status,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        apiKey,
        environment,
        status,
        organizationId,
        createdAt,
        updatedAt,
      ];
}
