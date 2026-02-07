import 'package:gozapper/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    super.phoneNumber,
    super.photoUrl,
    super.paymentId,
    required super.emailVerified,
    super.refreshTokenVersion,
    super.sandboxCredential,
    super.productionCredential,
    super.webhook,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse dates - backend uses Go's time.Time format
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return UserModel(
      id: json['ID']?.toString() ?? json['id']?.toString() ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      firstName: json['FirstName'] ?? json['firstName'] ?? '',
      lastName: json['LastName'] ?? json['lastName'] ?? '',
      fullName: json['FullName'] ?? json['fullName'] ?? '',
      phoneNumber: json['PhoneNumber'] ?? json['phoneNumber'],
      photoUrl: json['PhotoURL'] ?? json['photoUrl'],
      paymentId: json['PaymentID'] ?? json['paymentId'],
      emailVerified: json['EmailVerified'] ?? json['emailVerified'] ?? false,
      refreshTokenVersion: json['RefreshTokenVersion'] ?? json['refreshTokenVersion'],
      sandboxCredential: json['SandboxCredential'] ?? json['sandboxCredential'],
      productionCredential: json['ProductionCredential'] ?? json['productionCredential'],
      webhook: json['Webhook'] ?? json['webhook'],
      createdAt: parseDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: parseDate(json['UpdatedAt'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'paymentId': paymentId,
      'emailVerified': emailVerified,
      'refreshTokenVersion': refreshTokenVersion,
      'sandboxCredential': sandboxCredential,
      'productionCredential': productionCredential,
      'webhook': webhook,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      paymentId: paymentId,
      emailVerified: emailVerified,
      refreshTokenVersion: refreshTokenVersion,
      sandboxCredential: sandboxCredential,
      productionCredential: productionCredential,
      webhook: webhook,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
