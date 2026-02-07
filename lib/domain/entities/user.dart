import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phoneNumber;
  final String? photoUrl;
  final String? paymentId;
  final bool emailVerified;
  final int? refreshTokenVersion;
  final bool? sandboxCredential;
  final bool? productionCredential;
  final bool? webhook;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phoneNumber,
    this.photoUrl,
    this.paymentId,
    required this.emailVerified,
    this.refreshTokenVersion,
    this.sandboxCredential,
    this.productionCredential,
    this.webhook,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        fullName,
        phoneNumber,
        photoUrl,
        paymentId,
        emailVerified,
        refreshTokenVersion,
        sandboxCredential,
        productionCredential,
        webhook,
        createdAt,
        updatedAt,
      ];
}
