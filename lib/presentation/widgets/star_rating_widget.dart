import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final void Function(int) onRatingChanged;
  final double size;
  final Color filledColor;
  final Color emptyColor;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
    this.filledColor = Colors.amber,
    this.emptyColor = const Color(0xFFD0D0D0),
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starIndex = index + 1;
          final isFilled = starIndex <= _currentRating;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentRating = starIndex;
              });
              widget.onRatingChanged(starIndex);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: isFilled ? widget.filledColor : widget.emptyColor,
                size: widget.size,
              ),
            ),
          );
        }),
      ),
    );
  }
}
