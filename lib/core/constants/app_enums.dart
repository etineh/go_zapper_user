// enum VechicleType{
//   motorcycle("Motorcycle",AppSvgs.motorcycle),
//   car("Car", AppSvgs.car),
//   van("Van", AppSvgs.van),
//   truck("Truck",AppSvgs.truck);
//
//   final String text;
//   final String asset;
//
//   const VechicleType(this.text, this.asset);
// }

enum TransactionType {
  debit("Debit"),
  credit("Credit");

  final String text;
  const TransactionType(this.text);
}

enum DeliveryType {
  dropOff("Drop-off"),
  inPerson("In-person");

  final String text;
  const DeliveryType(this.text);
}

enum DeliveryStatus {
  accepted("Accepted"),
  completed("Completed"),
  available("Available");

  final String text;
  const DeliveryStatus(this.text);
}

enum Gender {
  male("male"),
  female("female"),
  none(null);

  final String? text;

  const Gender(this.text);
  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.text?.toLowerCase() == value.toLowerCase(),
      orElse: () => none,
    );
  }
}

enum Weight { kg, lb }

enum DeliveryPickUpStatus {
  cancelled("cancelled"),
  none("none"),
  toPickUp("en_route_to_pickup"),
  atPickUp("arrived_at_pickup"),
  pickedUp("picked_up"),
  toDropOff("en_route_to_drop_off"),
  atDropOff("arrived_at_drop_off"),
  confirmed("confirmed"),
  delivered("delivered");

  final String apiValue;
  const DeliveryPickUpStatus(this.apiValue);

  static DeliveryPickUpStatus fromString(String value) {
    return DeliveryPickUpStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => DeliveryPickUpStatus.none,
    );
  }

  String get displayText {
    switch (this) {
      case DeliveryPickUpStatus.toPickUp:
        return "To Pickup";
      case DeliveryPickUpStatus.atPickUp:
        return "At Pickup";
      case DeliveryPickUpStatus.pickedUp:
        return "Item Picked";
      case DeliveryPickUpStatus.toDropOff:
        return "To Drop-off";
      case DeliveryPickUpStatus.atDropOff:
        return "At Drop-off";
      case DeliveryPickUpStatus.confirmed:
        return "Confirmed";
      case DeliveryPickUpStatus.delivered:
        return "Delivered";
      case DeliveryPickUpStatus.none:
        return apiValue;
      default:
        return apiValue;
    }
  }
}

enum DeliveryPickUpStatusStep {
  none(0),
  toPickUp(1),
  atPickUp(2),
  pickedUp(3),
  toDropOff(4),
  atDropOff(5),
  delivered(6);

  final int step;
  const DeliveryPickUpStatusStep(this.step);

  static DeliveryPickUpStatusStep fromString(String? value) {
    if (value == null) return DeliveryPickUpStatusStep.none;

    switch (value.toLowerCase()) {
      case "en_route_to_pickup":
        return DeliveryPickUpStatusStep.toPickUp;
      case "arrived_at_pickup":
        return DeliveryPickUpStatusStep.atPickUp;
      case "picked_up":
        return DeliveryPickUpStatusStep.pickedUp;
      case "en_route_to_drop_off":
        return DeliveryPickUpStatusStep.toDropOff;
      case "arrived_at_drop_off":
        return DeliveryPickUpStatusStep.atDropOff;
      // case "confirmed":
      case "delivered":
        return DeliveryPickUpStatusStep.delivered;
      default:
        return DeliveryPickUpStatusStep.none;
    }
  }
}

enum OrderStatus {
  quote,
  pending,
  confirmed,
  cancelled,
  delivered;

  // String get value {
  //   switch (this) {
  //     case OrderStatus.quote:
  //       return 'quote';
  //     case OrderStatus.pending:
  //       return 'pending';
  //     case OrderStatus.confirmed:
  //       return 'confirmed';
  //     case OrderStatus.cancelled:
  //       return 'cancelled';
  //     case OrderStatus.delivered:
  //       return 'delivered';
  //   }
  // }
}

enum PaymentMethod {
  card("Card"),
  cash("Cash"),
  wallet("Wallet");

  final String text;
  const PaymentMethod(this.text);
}
