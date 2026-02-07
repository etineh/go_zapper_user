import 'package:gozapper/domain/entities/delivery.dart';

class DeliveryModel extends Delivery {
  const DeliveryModel({
    required super.id,
    required super.trackingId,
    required super.country,
    required super.currency,
    required super.status,
    required super.fee,
    required super.tax,
    required super.tip,
    required super.riderFee,
    required super.serviceFee,
    required super.contactlessDropOff,
    required super.signatureRequired,
    required super.dropOffCode,
    required super.dropOffLatitude,
    required super.dropOffLongitude,
    required super.dropOffInstruction,
    required super.dropOffVerificationImageUrl,
    required super.dropOffSignatureImageUrl,
    required super.pickupCode,
    required super.pickupLatitude,
    required super.pickupLongitude,
    required super.pickupInstruction,
    required super.pickupVerificationImageUrl,
    required super.actionIfUndeliverable,
    required super.cancellationReason,
    required super.riderId,
    required super.riderName,
    required super.riderPhoneNumber,
    required super.riderVehicle,
    required super.riderLatitude,
    required super.riderLongitude,
    required super.organizationId,
    required super.environment,
    required super.createdAt,
    required super.updatedAt,
    required super.dropOffDetails,
    required super.pickupDetails,
    required super.dropOffWindow,
    required super.pickupWindow,
    super.items,
    super.requiredVehicleType,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null || date == '') return DateTime.now();
      if (date is String) {
        try {
          // Handle "0001-01-01T00:00:00Z" as default/empty date
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

    return DeliveryModel(
      id: json['ID'] ?? '',
      trackingId: json['TrackingID'] ?? '',
      country: json['Country'] ?? '',
      currency: json['Currency'] ?? '',
      status: json['Status'] ?? '',
      fee: json['Fee']?.toString() ?? '0',
      tax: json['Tax']?.toString() ?? '0',
      tip: json['Tip']?.toString() ?? '0',
      riderFee: json['RiderFee']?.toString() ?? '0',
      serviceFee: json['ServiceFee']?.toString() ?? '0',
      contactlessDropOff: json['ContactlessDropOff'] ?? false,
      signatureRequired: json['SignatureRequired'] ?? false,
      dropOffCode: json['DropOffCode'] ?? '',
      dropOffLatitude: (json['DropOffLatitude'] ?? 0.0).toDouble(),
      dropOffLongitude: (json['DropOffLongitude'] ?? 0.0).toDouble(),
      dropOffInstruction: json['DropOffInstruction'] ?? '',
      dropOffVerificationImageUrl: json['DropOffVerificationImageUrl'] ?? '',
      dropOffSignatureImageUrl: json['DropOffSignatureImageUrl'] ?? '',
      pickupCode: json['PickupCode'] ?? '',
      pickupLatitude: (json['PickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (json['PickupLongitude'] ?? 0.0).toDouble(),
      pickupInstruction: json['PickupInstruction'] ?? '',
      pickupVerificationImageUrl: json['PickupVerificationImageUrl'] ?? '',
      actionIfUndeliverable: json['ActionIfUndeliverable'] ?? '',
      cancellationReason: json['CancellationReason'] ?? '',
      riderId: json['RiderID'] ?? '',
      riderName: json['RiderName'] ?? '',
      riderPhoneNumber: json['RiderPhoneNumber'] ?? '',
      riderVehicle: json['RiderVehicle'] ?? '',
      riderLatitude: (json['RiderLatitude'] ?? 0.0).toDouble(),
      riderLongitude: (json['RiderLongitude'] ?? 0.0).toDouble(),
      organizationId: json['OrganizationID'] ?? '',
      environment: json['Environment'] ?? '',
      createdAt: parseDate(json['CreatedAt']),
      updatedAt: parseDate(json['UpdatedAt']),
      dropOffDetails: json['DropOffDetails'] != null
          ? DropOffDetailsModel.fromJson(json['DropOffDetails'])
          : const DropOffDetailsModel(address: '', name: '', phone: ''),
      pickupDetails: json['PickupDetails'] != null
          ? PickupDetailsModel.fromJson(json['PickupDetails'])
          : const PickupDetailsModel(address: '', name: '', phone: ''),
      dropOffWindow: json['DropOffWindow'] != null
          ? DeliveryWindowModel.fromJson(json['DropOffWindow'])
          : DeliveryWindowModel(
              startTime: DateTime.now(), endTime: DateTime.now()),
      pickupWindow: json['PickupWindow'] != null
          ? DeliveryWindowModel.fromJson(json['PickupWindow'])
          : DeliveryWindowModel(
              startTime: DateTime.now(), endTime: DateTime.now()),
      items: json['Items'] != null
          ? (json['Items'] as List)
              .map((item) => DeliveryItemModel.fromJson(item))
              .toList()
          : null,
      requiredVehicleType: json['RequiredVehicleType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'TrackingID': trackingId,
      'Country': country,
      'Currency': currency,
      'Status': status,
      'Fee': fee,
      'Tax': tax,
      'Tip': tip,
      'RiderFee': riderFee,
      'ServiceFee': serviceFee,
      'ContactlessDropOff': contactlessDropOff,
      'SignatureRequired': signatureRequired,
      'DropOffCode': dropOffCode,
      'DropOffLatitude': dropOffLatitude,
      'DropOffLongitude': dropOffLongitude,
      'DropOffInstruction': dropOffInstruction,
      'DropOffVerificationImageUrl': dropOffVerificationImageUrl,
      'DropOffSignatureImageUrl': dropOffSignatureImageUrl,
      'PickupCode': pickupCode,
      'PickupLatitude': pickupLatitude,
      'PickupLongitude': pickupLongitude,
      'PickupInstruction': pickupInstruction,
      'PickupVerificationImageUrl': pickupVerificationImageUrl,
      'ActionIfUndeliverable': actionIfUndeliverable,
      'CancellationReason': cancellationReason,
      'RiderID': riderId,
      'RiderName': riderName,
      'RiderPhoneNumber': riderPhoneNumber,
      'RiderVehicle': riderVehicle,
      'RiderLatitude': riderLatitude,
      'RiderLongitude': riderLongitude,
      'OrganizationID': organizationId,
      'Environment': environment,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'DropOffDetails': (dropOffDetails as DropOffDetailsModel).toJson(),
      'PickupDetails': (pickupDetails as PickupDetailsModel).toJson(),
      'DropOffWindow': (dropOffWindow as DeliveryWindowModel).toJson(),
      'PickupWindow': (pickupWindow as DeliveryWindowModel).toJson(),
      'Items': items?.map((item) => (item as DeliveryItemModel).toJson()).toList(),
      'RequiredVehicleType': requiredVehicleType,
    };
  }

  Delivery toEntity() {
    return Delivery(
      id: id,
      trackingId: trackingId,
      country: country,
      currency: currency,
      status: status,
      fee: fee,
      tax: tax,
      tip: tip,
      riderFee: riderFee,
      serviceFee: serviceFee,
      contactlessDropOff: contactlessDropOff,
      signatureRequired: signatureRequired,
      dropOffCode: dropOffCode,
      dropOffLatitude: dropOffLatitude,
      dropOffLongitude: dropOffLongitude,
      dropOffInstruction: dropOffInstruction,
      dropOffVerificationImageUrl: dropOffVerificationImageUrl,
      dropOffSignatureImageUrl: dropOffSignatureImageUrl,
      pickupCode: pickupCode,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      pickupInstruction: pickupInstruction,
      pickupVerificationImageUrl: pickupVerificationImageUrl,
      actionIfUndeliverable: actionIfUndeliverable,
      cancellationReason: cancellationReason,
      riderId: riderId,
      riderName: riderName,
      riderPhoneNumber: riderPhoneNumber,
      riderVehicle: riderVehicle,
      riderLatitude: riderLatitude,
      riderLongitude: riderLongitude,
      organizationId: organizationId,
      environment: environment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dropOffDetails: dropOffDetails,
      pickupDetails: pickupDetails,
      dropOffWindow: dropOffWindow,
      pickupWindow: pickupWindow,
      items: items,
      requiredVehicleType: requiredVehicleType,
    );
  }
}

class DropOffDetailsModel extends DropOffDetails {
  const DropOffDetailsModel({
    required super.address,
    required super.name,
    required super.phone,
  });

  factory DropOffDetailsModel.fromJson(Map<String, dynamic> json) {
    return DropOffDetailsModel(
      address: json['address'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'phone': phone,
    };
  }
}

class PickupDetailsModel extends PickupDetails {
  const PickupDetailsModel({
    required super.address,
    required super.name,
    required super.phone,
  });

  factory PickupDetailsModel.fromJson(Map<String, dynamic> json) {
    return PickupDetailsModel(
      address: json['address'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'phone': phone,
    };
  }
}

class DeliveryWindowModel extends DeliveryWindow {
  DeliveryWindowModel({
    required super.startTime,
    required super.endTime,
  });

  factory DeliveryWindowModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null || date == '') return DateTime.now();
      if (date is String) {
        try {
          // Handle "0001-01-01T00:00:00Z" as default/empty date
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

    return DeliveryWindowModel(
      startTime: parseDate(json['StartTime']),
      endTime: parseDate(json['EndTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StartTime': startTime.toIso8601String(),
      'EndTime': endTime.toIso8601String(),
    };
  }
}

class DeliveryItemModel extends DeliveryItem {
  const DeliveryItemModel({
    required super.name,
    required super.quantity,
    super.description,
    super.externalId,
    super.imageUrl,
    super.weight,
    super.length,
    super.width,
    super.height,
    super.price,
  });

  factory DeliveryItemModel.fromJson(Map<String, dynamic> json) {
    return DeliveryItemModel(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      description: json['description'],
      externalId: json['externalId'],
      imageUrl: json['imageUrl'],
      weight: json['weight']?.toDouble(),
      length: json['length']?.toDouble(),
      width: json['width']?.toDouble(),
      height: json['height']?.toDouble(),
      price: json['price']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'quantity': quantity,
    };
    if (description != null) map['description'] = description;
    if (externalId != null) map['externalId'] = externalId;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (weight != null) map['weight'] = weight;
    if (length != null) map['length'] = length;
    if (width != null) map['width'] = width;
    if (height != null) map['height'] = height;
    if (price != null) map['price'] = price;
    return map;
  }
}
