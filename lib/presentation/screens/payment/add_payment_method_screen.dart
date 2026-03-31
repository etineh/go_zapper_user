import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_constants.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/providers/payment_method_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final email = user?.email ?? '';
    final paymentID = user?.paymentId ?? ''; // Customer code from Paystack
    final reference =
        'gozapper_verify_${DateTime.now().millisecondsSinceEpoch}';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Failed to load payment page. Please check your internet connection.';
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'PaystackResult',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePaystackResult(message.message);
        },
      )
      ..loadHtmlString(_buildPaystackHtml(email, paymentID, reference));
  }

  String _buildPaystackHtml(String email, String paymentID, String reference) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    body {
      margin: 0;
      padding: 20px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      box-sizing: border-box;
    }
    .loading {
      text-align: center;
      color: #666;
      font-size: 16px;
    }
    .spinner {
      border: 3px solid #f3f3f3;
      border-top: 3px solid #0A2463;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
      margin: 0 auto 16px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div class="loading">
    <div class="spinner"></div>
    <p>Initializing secure payment...</p>
  </div>

  <script src="https://js.paystack.co/v2/inline.js"></script>
  <script>
    try {
      const popup = new PaystackPop();
      popup.newTransaction({
        key: '${AppConstants.paystackPublicKey}',
        email: '$email',
        amount: ${AppConstants.paystackVerificationAmountKobo},
        currency: 'NGN',
        ref: '$reference',
        channels: ['card'],
        label: 'Card Verification',
        onSuccess: function(transaction) {
          PaystackResult.postMessage(JSON.stringify({
            status: 'success',
            reference: transaction.reference
          }));
        },
        onCancel: function() {
          PaystackResult.postMessage(JSON.stringify({
            status: 'cancelled'
          }));
        }
      });
    } catch(e) {
      PaystackResult.postMessage(JSON.stringify({
        status: 'error',
        message: e.message || 'Failed to initialize payment'
      }));
    }
  </script>
</body>
</html>
''';
  }

  Future<void> _handlePaystackResult(String message) async {
    try {
      final result = jsonDecode(message);
      final status = result['status'];

      if (status == 'success') {
        if (!mounted) return;
        setState(() => _isProcessing = true);
        final reference = result['reference'] as String;

        // Send reference to backend — backend will verify with Paystack
        // and the authorization gets linked to the customer automatically
        final paymentProvider = context.read<PaymentMethodProvider>();
        final success = await paymentProvider.savePaymentMethod(reference);

        if (success && mounted) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.refreshProfile();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment method added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          }
        } else if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage =
                paymentProvider.errorMessage ?? 'Failed to save payment method';
          });
        }
      } else if (status == 'cancelled') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop(false);
        }
      } else if (status == 'error') {
        if (mounted) {
          setState(() {
            _errorMessage =
                result['message'] ?? 'Payment initialization failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Add Payment Method',
        titleColor: AppColors.white,
        backgroundColor: AppColors.primary,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Saving payment method...',
                    style:
                        TextStyle(fontSize: 16, color: AppColors.textPrimary),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    // if (_isLoading)
                    //   const Center(child: CircularProgressIndicator()),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initWebView();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
