import 'package:flutter/foundation.dart';
import 'package:gozapper/data/models/quote_request_model.dart';
import 'package:gozapper/domain/entities/delivery.dart';
import 'package:gozapper/domain/repositories/delivery_repository.dart';

enum DeliveryStatus { initial, loading, loaded, error }

enum QuoteStatus { initial, generating, generated, accepting, accepted, error }

class DeliveryProvider extends ChangeNotifier {
  final DeliveryRepository deliveryRepository;

  DeliveryProvider({required this.deliveryRepository});

  DeliveryStatus _status = DeliveryStatus.initial;
  List<Delivery> _deliveries = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Quote state
  QuoteStatus _quoteStatus = QuoteStatus.initial;
  QuoteResponseModel? _currentQuote;
  Delivery? _createdDelivery;

  // Getters
  DeliveryStatus get status => _status;
  List<Delivery> get deliveries => _deliveries;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasDeliveries => _deliveries.isNotEmpty;

  // Quote getters
  QuoteStatus get quoteStatus => _quoteStatus;
  QuoteResponseModel? get currentQuote => _currentQuote;
  Delivery? get createdDelivery => _createdDelivery;
  bool get isGeneratingQuote => _quoteStatus == QuoteStatus.generating;
  bool get isAcceptingQuote => _quoteStatus == QuoteStatus.accepting;

  // Mock data for when API returns empty
  List<Delivery> get mockDeliveries => [
        Delivery(
          id: '1',
          trackingId: 'ORD-74ESW4',
          country: 'nigeria',
          currency: 'ngn',
          status: 'in_delivery',
          fee: '21870.71',
          tax: '0',
          tip: '300',
          riderFee: '0',
          serviceFee: '0',
          contactlessDropOff: true,
          signatureRequired: false,
          dropOffCode: '785245',
          dropOffLatitude: 6.60405,
          dropOffLongitude: 3.347751,
          dropOffInstruction: '',
          dropOffVerificationImageUrl: '',
          dropOffSignatureImageUrl: '',
          pickupCode: '2141',
          pickupLatitude: 6.656756,
          pickupLongitude: 3.519653,
          pickupInstruction: '',
          pickupVerificationImageUrl: '',
          actionIfUndeliverable: 'dispose',
          cancellationReason: '',
          riderId: 'e3a8b2c4-cbee-47a6-a619-2129379265b0',
          riderName: 'john doe',
          riderPhoneNumber: '',
          riderVehicle: 'blue toyota camry 2008',
          riderLatitude: 6.661113,
          riderLongitude: 3.519488,
          organizationId: '15f8d4ce-5974-407b-b9b4-8ef18b8643b6',
          environment: 'sandbox',
          createdAt: DateTime(2025, 10, 16),
          updatedAt: DateTime(2025, 10, 16),
          dropOffDetails: const DropOffDetails(
            address: 'Jos, NG',
            name: 'Jendor',
            phone: '+23407068211063',
          ),
          pickupDetails: const PickupDetails(
            address: 'Abuja, NG',
            name: 'Vikky B',
            phone: '+23407033432123',
          ),
          dropOffWindow: DeliveryWindow(
            startTime: DateTime(2025, 10, 12),
            endTime: DateTime(2025, 10, 12),
          ),
          pickupWindow: DeliveryWindow(
            startTime: DateTime(2025, 10, 16),
            endTime: DateTime(2025, 10, 16),
          ),
        ),
        Delivery(
          id: '2',
          trackingId: 'ORD-3EW5G6',
          country: 'nigeria',
          currency: 'ngn',
          status: 'delivered',
          fee: '18500.00',
          tax: '0',
          tip: '200',
          riderFee: '0',
          serviceFee: '0',
          contactlessDropOff: true,
          signatureRequired: false,
          dropOffCode: '123456',
          dropOffLatitude: 6.5244,
          dropOffLongitude: 3.3792,
          dropOffInstruction: '',
          dropOffVerificationImageUrl: '',
          dropOffSignatureImageUrl: '',
          pickupCode: '654321',
          pickupLatitude: 6.4541,
          pickupLongitude: 3.3947,
          pickupInstruction: '',
          pickupVerificationImageUrl: '',
          actionIfUndeliverable: 'return',
          cancellationReason: '',
          riderId: 'a1b2c3d4-e5f6-47a6-a619-1234567890ab',
          riderName: 'jane smith',
          riderPhoneNumber: '',
          riderVehicle: 'red honda civic 2010',
          riderLatitude: 6.5244,
          riderLongitude: 3.3792,
          organizationId: '15f8d4ce-5974-407b-b9b4-8ef18b8643b6',
          environment: 'sandbox',
          createdAt: DateTime(2025, 9, 18),
          updatedAt: DateTime(2025, 9, 18),
          dropOffDetails: const DropOffDetails(
            address: 'Lagos, NG',
            name: 'Customer Name',
            phone: '+23407012345678',
          ),
          pickupDetails: const PickupDetails(
            address: 'Enugu, NG',
            name: 'Sender Name',
            phone: '+23407087654321',
          ),
          dropOffWindow: DeliveryWindow(
            startTime: DateTime(2025, 9, 12),
            endTime: DateTime(2025, 9, 12),
          ),
          pickupWindow: DeliveryWindow(
            startTime: DateTime(2025, 9, 18),
            endTime: DateTime(2025, 9, 18),
          ),
        ),
        Delivery(
          id: '3',
          trackingId: 'ORD-25ER34',
          country: 'nigeria',
          currency: 'ngn',
          status: 'delivered',
          fee: '25000.00',
          tax: '0',
          tip: '500',
          riderFee: '0',
          serviceFee: '0',
          contactlessDropOff: false,
          signatureRequired: true,
          dropOffCode: '789012',
          dropOffLatitude: 6.661113,
          dropOffLongitude: 3.519488,
          dropOffInstruction: '',
          dropOffVerificationImageUrl: '',
          dropOffSignatureImageUrl: '',
          pickupCode: '210987',
          pickupLatitude: 12.0022,
          pickupLongitude: 8.5920,
          pickupInstruction: '',
          pickupVerificationImageUrl: '',
          actionIfUndeliverable: 'hold',
          cancellationReason: '',
          riderId: 'x9y8z7w6-v5u4-47a6-a619-9876543210xy',
          riderName: 'mike johnson',
          riderPhoneNumber: '',
          riderVehicle: 'green toyota corolla 2012',
          riderLatitude: 6.661113,
          riderLongitude: 3.519488,
          organizationId: '15f8d4ce-5974-407b-b9b4-8ef18b8643b6',
          environment: 'sandbox',
          createdAt: DateTime(2025, 8, 19),
          updatedAt: DateTime(2025, 9, 20),
          dropOffDetails: const DropOffDetails(
            address: 'Jos, NG',
            name: 'Recipient',
            phone: '+23407098765432',
          ),
          pickupDetails: const PickupDetails(
            address: 'Kano, NG',
            name: 'Shipper',
            phone: '+23407023456789',
          ),
          dropOffWindow: DeliveryWindow(
            startTime: DateTime(2025, 9, 20),
            endTime: DateTime(2025, 9, 20),
          ),
          pickupWindow: DeliveryWindow(
            startTime: DateTime(2025, 8, 19),
            endTime: DateTime(2025, 8, 19),
          ),
        ),
        Delivery(
          id: '4',
          trackingId: 'ORD-10TG25',
          country: 'nigeria',
          currency: 'ngn',
          status: 'delivered',
          fee: '19500.00',
          tax: '0',
          tip: '250',
          riderFee: '0',
          serviceFee: '0',
          contactlessDropOff: true,
          signatureRequired: false,
          dropOffCode: '456789',
          dropOffLatitude: 6.661113,
          dropOffLongitude: 3.519488,
          dropOffInstruction: '',
          dropOffVerificationImageUrl: '',
          dropOffSignatureImageUrl: '',
          pickupCode: '987654',
          pickupLatitude: 12.0022,
          pickupLongitude: 8.5920,
          pickupInstruction: '',
          pickupVerificationImageUrl: '',
          actionIfUndeliverable: 'dispose',
          cancellationReason: '',
          riderId: 'p9o8i7u6-y5t4-47a6-a619-1234567890pq',
          riderName: 'sarah williams',
          riderPhoneNumber: '',
          riderVehicle: 'black nissan sentra 2015',
          riderLatitude: 6.661113,
          riderLongitude: 3.519488,
          organizationId: '15f8d4ce-5974-407b-b9b4-8ef18b8643b6',
          environment: 'sandbox',
          createdAt: DateTime(2025, 8, 19),
          updatedAt: DateTime(2025, 9, 20),
          dropOffDetails: const DropOffDetails(
            address: 'Jos, NG',
            name: 'Final Customer',
            phone: '+23407056789012',
          ),
          pickupDetails: const PickupDetails(
            address: 'Kano, NG',
            name: 'Original Sender',
            phone: '+23407034567890',
          ),
          dropOffWindow: DeliveryWindow(
            startTime: DateTime(2025, 9, 20),
            endTime: DateTime(2025, 9, 20),
          ),
          pickupWindow: DeliveryWindow(
            startTime: DateTime(2025, 8, 19),
            endTime: DateTime(2025, 8, 19),
          ),
        ),
      ];

  // Fetch deliveries
  Future<void> fetchDeliveries({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    _setLoading(true);
    _clearError();
    _setStatus(DeliveryStatus.loading);

    // Default to last 30 days if no dates provided
    final end = endTime ?? DateTime.now();
    final start = startTime ?? end.subtract(const Duration(days: 30));

    final result = await deliveryRepository.getDeliveries(
      startTime: start,
      endTime: end,
    );

    result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(DeliveryStatus.error);
        // Use mock data on error
        // _deliveries = mockDeliveries;
      },
      (deliveries) {
        _deliveries = deliveries;
        _setStatus(DeliveryStatus.loaded);
      },
    );

    _setLoading(false);
  }

  // Refresh deliveries
  Future<void> refreshDeliveries() async {
    await fetchDeliveries();
  }

  // Get delivery by tracking ID
  Delivery? getDeliveryByTrackingId(String trackingId) {
    try {
      return _deliveries.firstWhere((d) => d.trackingId == trackingId);
    } catch (e) {
      return null;
    }
  }

  // Get deliveries by status
  List<Delivery> getDeliveriesByStatus(String status) {
    return _deliveries
        .where((d) => d.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  // Helper methods
  void _setStatus(DeliveryStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Generate a quote for delivery
  Future<bool> generateQuote(QuoteRequestModel request) async {
    _setQuoteStatus(QuoteStatus.generating);
    _clearError();

    final result = await deliveryRepository.generateQuote(request);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setQuoteStatus(QuoteStatus.error);
        return false;
      },
      (quote) {
        _currentQuote = quote;
        _setQuoteStatus(QuoteStatus.generated);
        return true;
      },
    );
  }

  // Accept the current quote
  Future<bool> acceptQuote() async {
    if (_currentQuote == null) {
      _setError('No quote available to accept');
      return false;
    }

    _setQuoteStatus(QuoteStatus.accepting);
    _clearError();

    final result = await deliveryRepository.acceptQuote(_currentQuote!.id);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setQuoteStatus(QuoteStatus.error);
        return false;
      },
      (delivery) {
        _createdDelivery = delivery;
        _deliveries.insert(0, delivery);
        _setQuoteStatus(QuoteStatus.accepted);
        return true;
      },
    );
  }

  // Accept a quote by delivery ID
  Future<bool> acceptQuoteById(String deliveryId) async {
    _setQuoteStatus(QuoteStatus.accepting);
    _clearError();

    final result = await deliveryRepository.acceptQuote(deliveryId);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setQuoteStatus(QuoteStatus.error);
        return false;
      },
      (delivery) {
        _createdDelivery = delivery;
        // Update the delivery in the list if it exists
        final index = _deliveries.indexWhere((d) => d.id == deliveryId);
        if (index != -1) {
          _deliveries[index] = delivery;
        } else {
          _deliveries.insert(0, delivery);
        }
        _setQuoteStatus(QuoteStatus.accepted);
        notifyListeners();
        return true;
      },
    );
  }

  // Reset quote state
  void resetQuote() {
    _currentQuote = null;
    _createdDelivery = null;
    _setQuoteStatus(QuoteStatus.initial);
  }

  // Clear all user-specific delivery data on logout
  void clearUserData() {
    _deliveries = [];
    _currentQuote = null;
    _createdDelivery = null;
    _status = DeliveryStatus.initial;
    _quoteStatus = QuoteStatus.initial;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setQuoteStatus(QuoteStatus status) {
    _quoteStatus = status;
    notifyListeners();
  }

  // Track a single delivery by ID
  Future<Delivery?> trackDelivery(String deliveryId, {bool updateList = false}) async {
    final result = await deliveryRepository.getDeliveryById(deliveryId);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return null;
      },
      (delivery) {
        // Update the delivery in the list if it exists and updateList is true
        if (updateList) {
          final index = _deliveries.indexWhere((d) => d.id == deliveryId);
          if (index != -1) {
            _deliveries[index] = delivery;
            notifyListeners();
          }
        }
        return delivery;
      },
    );
  }

  // Cancel a delivery
  Future<bool> cancelDelivery(String deliveryId, String reason) async {
    _setLoading(true);
    _clearError();

    final result = await deliveryRepository.cancelDelivery(deliveryId, reason);

    _setLoading(false);

    return result.fold(
      (failure) {
        _setError(failure.message);
        return false;
      },
      (success) {
        // Update the delivery status in the list if it exists
        final index = _deliveries.indexWhere((d) => d.id == deliveryId);
        if (index != -1) {
          _deliveries[index] = _deliveries[index].copyWith(status: 'cancelled');
          notifyListeners();
        }
        return true;
      },
    );
  }
}
