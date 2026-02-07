import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/core/constants/app_routes.dart';
import 'package:gozapper/data/models/transaction_model.dart';
import 'package:gozapper/presentation/providers/auth_provider.dart';
import 'package:gozapper/presentation/providers/credential_provider.dart';
import 'package:gozapper/presentation/providers/payment_method_provider.dart';
import 'package:gozapper/presentation/widgets/custom_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentBillingScreen extends StatefulWidget {
  const PaymentBillingScreen({super.key});

  @override
  State<PaymentBillingScreen> createState() => _PaymentBillingScreenState();
}

class _PaymentBillingScreenState extends State<PaymentBillingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final paymentProvider = context.read<PaymentMethodProvider>();

    // Only fetch payment method details if user has payment ID
    if (user != null && user.paymentId != null && user.paymentId!.isNotEmpty) {
      await paymentProvider.getPaymentMethodDetails();
    }

    // Always try to fetch transactions
    await paymentProvider.getTransactions(limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentMethodProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Billing & Payments',
        titleColor: AppColors.white,
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Method Section
              _buildSectionHeader('💳 Payment Method'),
              const SizedBox(height: 12),
              _buildPaymentMethodCard(user),
              const SizedBox(height: 24),

              // Billing Summary Section
              _buildSectionHeader('📊 Billing Summary'),
              const SizedBox(height: 12),
              _buildBillingSummaryCard(paymentProvider.transactions),
              const SizedBox(height: 24),

              // Recent Transactions Section
              _buildSectionHeader('📜 Recent Transactions'),
              const SizedBox(height: 12),
              _buildTransactionsList(paymentProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPaymentMethodCard(user) {
    final hasPaymentMethod =
        user?.paymentId != null && user!.paymentId!.isNotEmpty;
    final paymentProvider = context.watch<PaymentMethodProvider>();
    final paymentDetails = paymentProvider.paymentMethodDetails;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasPaymentMethod
          ? paymentProvider.isLoadingDetails
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (paymentDetails != null) ...[
                      Row(
                        children: [
                          Icon(
                            _getCardIcon(paymentDetails.brand),
                            size: 32,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${paymentDetails.brand.toUpperCase()} •••• ${paymentDetails.last4}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expires: ${paymentDetails.expMonth}/${paymentDetails.expYear}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final result = await context
                                    .push(AppRoutes.addPaymentMethod);
                                if (result == true && mounted) {
                                  _loadData();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                              child: const Text('Change Method'),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Column(
                        children: [
                          Icon(Icons.credit_card_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No Payment Method Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a payment method to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await context
                                  .push(AppRoutes.addPaymentMethod);
                              if (result == true && mounted) {
                                _loadData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add Payment Method'),
                          ),
                        ],
                      ),
                  ],
                )
          : Column(
              children: [
                Icon(Icons.credit_card_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No Payment Method Added',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a payment method to start creating deliveries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final result =
                        await context.push(AppRoutes.addPaymentMethod);
                    if (result == true && mounted) {
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Payment Method'),
                ),
              ],
            ),
    );
  }

  IconData _getCardIcon(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  Widget _buildBillingSummaryCard(List<TransactionModel> transactions) {
    final thisMonthTotal = _calculateMonthlyTotal(transactions);
    final lastCharge =
        transactions.isNotEmpty ? transactions.first.amount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'This Month', '\$${thisMonthTotal.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildSummaryRow('Last Charge', '\$${lastCharge.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  double _calculateMonthlyTotal(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);

    return transactions
        .where((t) =>
            t.createdAt.isAfter(thisMonthStart) &&
            t.transactionType == 'charge')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Widget _buildTransactionsList(PaymentMethodProvider provider) {
    if (provider.isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = provider.transactions[index];
          return _buildTransactionTile(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isCharge = transaction.transactionType == 'charge';
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isCharge
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        child: Icon(
          isCharge ? Icons.arrow_upward : Icons.arrow_downward,
          color: isCharge ? Colors.red : Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        transaction.transactionType.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        dateFormat.format(transaction.createdAt),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        '${isCharge ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isCharge ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}
