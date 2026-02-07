import '../constants/app_enums.dart';

extension DeliveryStatusProgress on DeliveryPickUpStatusStep {
  bool reached(DeliveryPickUpStatusStep target) => step >= target.step;
}
