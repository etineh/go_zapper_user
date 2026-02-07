/// Model for creating a delivery quote request
class QuoteRequestModel {
  final String country;
  final String? tip;
  final List<QuoteItemModel> items;
  final bool contactlessDropOff;
  final bool signatureRequired;
  final double dropOffLatitude;
  final double dropOffLongitude;
  final String? dropOffInstruction;
  final ContactDetailsModel dropOffDetails;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? pickupInstruction;
  final ContactDetailsModel pickupDetails;
  final String actionIfUndeliverable;
  final String? requiredVehicleType;

  QuoteRequestModel({
    required this.country,
    this.tip,
    required this.items,
    this.contactlessDropOff = false,
    this.signatureRequired = false,
    required this.dropOffLatitude,
    required this.dropOffLongitude,
    this.dropOffInstruction,
    required this.dropOffDetails,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.pickupInstruction,
    required this.pickupDetails,
    this.actionIfUndeliverable = 'return_to_pickup',
    this.requiredVehicleType,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'country': country,
      'items': items.map((item) => item.toJson()).toList(),
      'contactlessDropOff': contactlessDropOff,
      'signatureRequired': signatureRequired,
      'dropOffLatitude': dropOffLatitude,
      'dropOffLongitude': dropOffLongitude,
      'dropOffDetails': dropOffDetails.toJson(),
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupDetails': pickupDetails.toJson(),
      'actionIfUndeliverable': actionIfUndeliverable,
    };

    if (tip != null && tip!.isNotEmpty) {
      map['tip'] = tip;
    }
    if (dropOffInstruction != null && dropOffInstruction!.isNotEmpty) {
      map['dropOffInstruction'] = dropOffInstruction;
    }
    if (pickupInstruction != null && pickupInstruction!.isNotEmpty) {
      map['pickupInstruction'] = pickupInstruction;
    }
    if (requiredVehicleType != null && requiredVehicleType!.isNotEmpty) {
      map['requiredVehicleType'] = requiredVehicleType;
    }

    return map;
  }
}

/// Model for contact details (used in both pickup and dropoff)
class ContactDetailsModel {
  final String address;
  final String name;
  final String phone;

  ContactDetailsModel({
    required this.address,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'phone': phone,
    };
  }
}

/// Model for items in the quote request
class QuoteItemModel {
  final String name;
  final String? description;
  final String? externalId;
  final String? imageUrl;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final int quantity;
  final String price;

  QuoteItemModel({
    required this.name,
    this.description,
    this.externalId,
    this.imageUrl,
    this.weight,
    this.length,
    this.width,
    this.height,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'price': price,
    };

    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (externalId != null && externalId!.isNotEmpty) {
      map['externalId'] = externalId;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    if (weight != null) map['weight'] = weight;
    if (length != null) map['length'] = length;
    if (width != null) map['width'] = width;
    if (height != null) map['height'] = height;

    return map;
  }
}

/// Model for quote response from the API
class QuoteResponseModel {
  final String id;
  final String trackingId;
  final String status;
  final String fee;
  final String tax;
  final String serviceFee;
  final String riderFee;
  final String currency;
  final DateTime expiresAt;

  QuoteResponseModel({
    required this.id,
    required this.trackingId,
    required this.status,
    required this.fee,
    required this.tax,
    required this.serviceFee,
    required this.riderFee,
    required this.currency,
    required this.expiresAt,
  });

  factory QuoteResponseModel.fromJson(Map<String, dynamic> json) {
    // Extract data object
    final data = json['data'] ?? json;
    final quote = data['quote'] ?? data;

    return QuoteResponseModel(
      id: data['deliveryID'] ?? data['ID'] ?? '',
      trackingId: data['trackingID'] ?? data['TrackingID'] ?? '',
      status: data['status'] ?? data['Status'] ?? 'pending',
      fee: quote['Fee']?.toString() ?? '0',
      tax: quote['Tax']?.toString() ?? '0',
      serviceFee: quote['ServiceFee']?.toString() ?? '0',
      riderFee: quote['RiderFee']?.toString() ?? '0',
      currency: quote['Currency'] ?? 'NGN',
      expiresAt: data['expiresAt'] != null || data['ExpiresAt'] != null
          ? DateTime.parse(data['expiresAt'] ?? data['ExpiresAt'])
          : DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  double get totalFee {
    final feeValue = double.tryParse(fee) ?? 0;
    final taxValue = double.tryParse(tax) ?? 0;
    return feeValue + taxValue;
  }
}

/// Model for accept quote response from the API
class AcceptQuoteResponseModel {
  final String message;
  final Map<String, dynamic> delivery;

  AcceptQuoteResponseModel({
    required this.message,
    required this.delivery,
  });

  factory AcceptQuoteResponseModel.fromJson(Map<String, dynamic> json) {
    // Extract the delivery object from nested structure
    // Expected format: { "message": "...", "data": { "delivery": {...} } }
    final data = json['data'] ?? json;
    final deliveryData = data['delivery'] ?? data;

    return AcceptQuoteResponseModel(
      message: json['message'] ?? '',
      delivery: deliveryData as Map<String, dynamic>,
    );
  }
}

/*
{
    "country": "us",
    "tip": 2,
    "items": [
        {
            "name": "Bread",
            "description": "Jendor Fresh Butter Bread",
            "externalId": "jendor_567890-9876567890",
            "weight": 2, // kg
            "length": 5,
            "width": 5,
            "height": 5,
            "quantity": 1, // would multiply quantity by weght and price
            "price": 1500
        },
        {
            "name": "Milk",
            "description": "Peak Milk",
            "externalId": "jendor_567890-987659990",
            "weight": 0.02, // kg
            // "length": 0,
            // "width": 0,
            // "height": 5,
            "quantity": 4, // would multiply quantity by weght and price
            "price": 1200
        },
        {
            "name": "Milo",
            "description": "Milo Sachet",
            "externalId": "jendor_567890-987659990",
            "weight": 0.02, // kg
            // "length": 0,
            // "width": 0,
            // "height": 5,
            "quantity": 2, // would multiply quantity by weght and price
            "price": 600
        }
    ],
    "contactlessDropOff": true,
    "signatureRequired": false,
    "dropOffLatitude": 6.629374,
    "dropOffLongitude": 3.504741,
    "dropOffInstruction": "",
    "dropOffDetails": {
        "address": "MG49+PRC, Lagos NG, Imam Muhammed Adewunmi St, Ikorodu 114232",
        "name": "Jendor",
        "phone": "+23407068211063"
    },
    "pickupLatitude": 6.656594,
    "pickupLongitude": 3.519601,
    "pickupInstruction": "This a delivery with an instruction for the rider, hoepfully it makes the deliery a little better for the rider",
    "pickupDetails": {
        "address": "Gani Odusanya Ave, Ikorodu, 104101, Lagos",
        "name": "Vikky B",
        "phone": "+23407033432123"
    },
    "actionIfUndeliverable": "dispose"
}

Error:
 DioError ║ Status: 401 Unauthorized ║ Time: 4206 ms
I/flutter ( 5968): ║  https://gozapper-delivery.onrender.com/api/v1/quote
I/flutter ( 5968): ╚══════════════════════════════════════════════════════════════════════════════════════════╝
I/flutter ( 5968): ╔ DioExceptionType.badResponse
I/flutter ( 5968): ║    {
I/flutter ( 5968): ║         "error": "authorization token missing",
I/flutter ( 5968): ║         "message": "unauthorized"
I/flutter ( 5968): ║    }

//cancel delivery
delivery api/v1/cancel/:id
expecting -
 {
    "reason": "no fundz"
}
returns {
    "message": "Delivery Canceled"
}
 */
