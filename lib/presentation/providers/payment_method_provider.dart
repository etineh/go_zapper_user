import 'package:flutter/foundation.dart';
import 'package:gozapper/data/models/payment_method_model.dart';
import 'package:gozapper/data/models/transaction_model.dart';
import 'package:gozapper/domain/repositories/payment_method_repository.dart';

enum PaymentMethodStatus { initial, saving, saved, error }

class PaymentMethodProvider extends ChangeNotifier {
  final PaymentMethodRepository paymentMethodRepository;

  PaymentMethodProvider({required this.paymentMethodRepository});

  PaymentMethodStatus _status = PaymentMethodStatus.initial;
  String? _errorMessage;
  bool _isSaving = false;
  List<TransactionModel> _transactions = [];
  bool _isLoadingTransactions = false;
  PaymentMethodDetailsModel? _paymentMethodDetails;
  bool _isLoadingDetails = false;

  // Getters
  PaymentMethodStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  bool get isSuccess => _status == PaymentMethodStatus.saved;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoadingTransactions => _isLoadingTransactions;
  PaymentMethodDetailsModel? get paymentMethodDetails => _paymentMethodDetails;
  bool get isLoadingDetails => _isLoadingDetails;

  // Save payment method
  Future<bool> savePaymentMethod(String paymentMethodToken) async {
    _setStatus(PaymentMethodStatus.saving);
    _setSaving(true);
    _clearError();

    final request = PaymentMethodRequestModel(
      paymentMethodToken: paymentMethodToken,
    );

    final result = await paymentMethodRepository.savePaymentMethod(request);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setStatus(PaymentMethodStatus.error);
        _setSaving(false);
        return false;
      },
      (response) {
        _setStatus(PaymentMethodStatus.saved);
        _setSaving(false);
        return response.success;
      },
    );
  }

  // Reset state
  void reset() {
    _setStatus(PaymentMethodStatus.initial);
    _clearError();
  }

  // Helper methods
  void _setStatus(PaymentMethodStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
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

  // Get payment method details
  Future<bool> getPaymentMethodDetails() async {
    _isLoadingDetails = true;
    _clearError();
    notifyListeners();

    final result = await paymentMethodRepository.getPaymentMethodDetails();

    _isLoadingDetails = false;

    return result.fold(
      (failure) {
        _setError(failure.message);
        notifyListeners();
        return false;
      },
      (response) {
        _paymentMethodDetails = response.paymentMethod;
        notifyListeners();
        return true;
      },
    );
  }

  // Get transactions
  Future<bool> getTransactions({
    String? transactionType,
    String? paymentIntentID,
    String? refundIntentID,
    String? startDate,
    String? endDate,
    String? currency,
    int? limit,
    int? page,
  }) async {
    _isLoadingTransactions = true;
    _clearError();
    notifyListeners();

    final result = await paymentMethodRepository.getTransactions(
      transactionType: transactionType,
      paymentIntentID: paymentIntentID,
      refundIntentID: refundIntentID,
      startDate: startDate,
      endDate: endDate,
      currency: currency,
      limit: limit ?? 20,
      page: page ?? 1,
    );

    _isLoadingTransactions = false;

    return result.fold(
      (failure) {
        _setError(failure.message);
        notifyListeners();
        return false;
      },
      (response) {
        _transactions = response.transactions;
        notifyListeners();
        return true;
      },
    );
  }

  // Clear all user-specific payment data on logout
  void clearUserData() {
    _transactions = [];
    _paymentMethodDetails = null;
    _status = PaymentMethodStatus.initial;
    _errorMessage = null;
    _isSaving = false;
    _isLoadingTransactions = false;
    _isLoadingDetails = false;
    notifyListeners();
  }
}
