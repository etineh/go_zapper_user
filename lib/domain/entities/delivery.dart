import 'package:equatable/equatable.dart';

class Delivery extends Equatable {
  final String id;
  final String trackingId;
  final String country;
  final String currency;
  final String status;
  final String fee;
  final String tax;
  final String tip;
  final String riderFee;
  final String serviceFee;
  final bool contactlessDropOff;
  final bool signatureRequired;
  final String dropOffCode;
  final double dropOffLatitude;
  final double dropOffLongitude;
  final String dropOffInstruction;
  final String dropOffVerificationImageUrl;
  final String dropOffSignatureImageUrl;
  final String pickupCode;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupInstruction;
  final String pickupVerificationImageUrl;
  final String actionIfUndeliverable;
  final String cancellationReason;
  final String riderId;
  final String riderName;
  final String riderPhoneNumber;
  final String riderVehicle;
  final double riderLatitude;
  final double riderLongitude;
  final String organizationId;
  final String environment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DropOffDetails dropOffDetails;
  final PickupDetails pickupDetails;
  final DeliveryWindow dropOffWindow;
  final DeliveryWindow pickupWindow;
  final List<DeliveryItem>? items;
  final String? requiredVehicleType; // car, truck, etc
// https://gozapper-organization.onrender.com/api/v1/delivery/a73f0e21-869e-448f-b622-381641e2ffd9
// https://gozapper-organization.onrender.com/api/v1/delivery?startTime=2025-12-10T14%3A33%3A54.569172Z&endTime=2026-01-09T14%3A33%3A54.569172Z
  const Delivery({
    required this.id,
    required this.trackingId,
    required this.country,
    required this.currency,
    required this.status,
    required this.fee,
    required this.tax,
    required this.tip,
    required this.riderFee,
    required this.serviceFee,
    required this.contactlessDropOff,
    required this.signatureRequired,
    required this.dropOffCode,
    required this.dropOffLatitude,
    required this.dropOffLongitude,
    required this.dropOffInstruction,
    required this.dropOffVerificationImageUrl,
    required this.dropOffSignatureImageUrl,
    required this.pickupCode,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupInstruction,
    required this.pickupVerificationImageUrl,
    required this.actionIfUndeliverable,
    required this.cancellationReason,
    required this.riderId,
    required this.riderName,
    required this.riderPhoneNumber,
    required this.riderVehicle,
    required this.riderLatitude,
    required this.riderLongitude,
    required this.organizationId,
    required this.environment,
    required this.createdAt,
    required this.updatedAt,
    required this.dropOffDetails,
    required this.pickupDetails,
    required this.dropOffWindow,
    required this.pickupWindow,
    this.items,
    this.requiredVehicleType,
  });

  Delivery copyWith({
    String? id,
    String? trackingId,
    String? country,
    String? currency,
    String? status,
    String? fee,
    String? tax,
    String? tip,
    String? riderFee,
    String? serviceFee,
    bool? contactlessDropOff,
    bool? signatureRequired,
    String? dropOffCode,
    double? dropOffLatitude,
    double? dropOffLongitude,
    String? dropOffInstruction,
    String? dropOffVerificationImageUrl,
    String? dropOffSignatureImageUrl,
    String? pickupCode,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupInstruction,
    String? pickupVerificationImageUrl,
    String? actionIfUndeliverable,
    String? cancellationReason,
    String? riderId,
    String? riderName,
    String? riderPhoneNumber,
    String? riderVehicle,
    double? riderLatitude,
    double? riderLongitude,
    String? organizationId,
    String? environment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DropOffDetails? dropOffDetails,
    PickupDetails? pickupDetails,
    DeliveryWindow? dropOffWindow,
    DeliveryWindow? pickupWindow,
    List<DeliveryItem>? items,
    String? requiredVehicleType,
  }) {
    return Delivery(
      id: id ?? this.id,
      trackingId: trackingId ?? this.trackingId,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      fee: fee ?? this.fee,
      tax: tax ?? this.tax,
      tip: tip ?? this.tip,
      riderFee: riderFee ?? this.riderFee,
      serviceFee: serviceFee ?? this.serviceFee,
      contactlessDropOff: contactlessDropOff ?? this.contactlessDropOff,
      signatureRequired: signatureRequired ?? this.signatureRequired,
      dropOffCode: dropOffCode ?? this.dropOffCode,
      dropOffLatitude: dropOffLatitude ?? this.dropOffLatitude,
      dropOffLongitude: dropOffLongitude ?? this.dropOffLongitude,
      dropOffInstruction: dropOffInstruction ?? this.dropOffInstruction,
      dropOffVerificationImageUrl:
          dropOffVerificationImageUrl ?? this.dropOffVerificationImageUrl,
      dropOffSignatureImageUrl:
          dropOffSignatureImageUrl ?? this.dropOffSignatureImageUrl,
      pickupCode: pickupCode ?? this.pickupCode,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupInstruction: pickupInstruction ?? this.pickupInstruction,
      pickupVerificationImageUrl:
          pickupVerificationImageUrl ?? this.pickupVerificationImageUrl,
      actionIfUndeliverable:
          actionIfUndeliverable ?? this.actionIfUndeliverable,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhoneNumber: riderPhoneNumber ?? this.riderPhoneNumber,
      riderVehicle: riderVehicle ?? this.riderVehicle,
      riderLatitude: riderLatitude ?? this.riderLatitude,
      riderLongitude: riderLongitude ?? this.riderLongitude,
      organizationId: organizationId ?? this.organizationId,
      environment: environment ?? this.environment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dropOffDetails: dropOffDetails ?? this.dropOffDetails,
      pickupDetails: pickupDetails ?? this.pickupDetails,
      dropOffWindow: dropOffWindow ?? this.dropOffWindow,
      pickupWindow: pickupWindow ?? this.pickupWindow,
      items: items ?? this.items,
      requiredVehicleType: requiredVehicleType ?? this.requiredVehicleType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trackingId,
        country,
        currency,
        status,
        fee,
        tax,
        tip,
        riderFee,
        serviceFee,
        contactlessDropOff,
        signatureRequired,
        dropOffCode,
        dropOffLatitude,
        dropOffLongitude,
        dropOffInstruction,
        dropOffVerificationImageUrl,
        dropOffSignatureImageUrl,
        pickupCode,
        pickupLatitude,
        pickupLongitude,
        pickupInstruction,
        pickupVerificationImageUrl,
        actionIfUndeliverable,
        cancellationReason,
        riderId,
        riderName,
        riderPhoneNumber,
        riderVehicle,
        riderLatitude,
        riderLongitude,
        organizationId,
        environment,
        createdAt,
        updatedAt,
        dropOffDetails,
        pickupDetails,
        dropOffWindow,
        pickupWindow,
        items,
        requiredVehicleType,
      ];
}

class DropOffDetails extends Equatable {
  final String address;
  final String name;
  final String phone;

  const DropOffDetails({
    required this.address,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [address, name, phone];
}

class PickupDetails extends Equatable {
  final String address;
  final String name;
  final String phone;

  const PickupDetails({
    required this.address,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [address, name, phone];
}

class DeliveryWindow extends Equatable {
  final DateTime startTime;
  final DateTime endTime;

  const DeliveryWindow({
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [startTime, endTime];
}

class DeliveryItem extends Equatable {
  final String name;
  final int quantity;
  final String? description;
  final String? externalId;
  final String? imageUrl;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final String? price;

  const DeliveryItem({
    required this.name,
    required this.quantity,
    this.description,
    this.externalId,
    this.imageUrl,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.price,
  });

  @override
  List<Object?> get props => [
        name,
        quantity,
        description,
        externalId,
        imageUrl,
        weight,
        length,
        width,
        height,
        price,
      ];
}
