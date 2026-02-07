import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';
import 'package:gozapper/presentation/widgets/star_rating_widget.dart';

class DriverRatingDialog extends StatefulWidget {
  final String driverName;
  final String deliveryId;

  const DriverRatingDialog({
    super.key,
    required this.driverName,
    required this.deliveryId,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String driverName,
    required String deliveryId,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DriverRatingDialog(
        driverName: driverName,
        deliveryId: deliveryId,
      ),
    );
  }

  @override
  State<DriverRatingDialog> createState() => _DriverRatingDialogState();
}

class _DriverRatingDialogState extends State<DriverRatingDialog> {
  late TextEditingController _feedbackController;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitRating() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating before submitting'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = {
      'rating': _selectedRating,
      'comment': _feedbackController.text.trim(),
      'deliveryId': widget.deliveryId,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Rate Your Driver',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            const Text(
              'How was your delivery experience?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Star rating widget
            StarRatingWidget(
              initialRating: _selectedRating,
              onRatingChanged: (rating) {
                setState(() {
                  _selectedRating = rating;
                });
              },
              size: 40,
              filledColor: Colors.amber,
              emptyColor: const Color(0xFFD0D0D0),
            ),

            const SizedBox(height: 24),

            // Feedback text field
            const Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _feedbackController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Share your experience with this driver...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(12),
                counterText: '', // Hide character counter
              ),
            ),

            const SizedBox(height: 12),

            // Driver name reference
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rating ${widget.driverName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Skip',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Submit Rating'),
        ),
      ],
    );
  }
}
