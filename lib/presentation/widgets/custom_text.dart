import 'package:flutter/material.dart';
import 'package:gozapper/core/constants/app_colors.dart';

class CustomText extends StatelessWidget {
  final String text;
  final bool shouldBold;
  final bool italic;
  final double size;
  final Color? color;
  final bool underline;
  final VoidCallback? onTap;
  final Color? splashColor;
  final int? maxLines;
  final TextOverflow overflow;

  const CustomText({
    super.key,
    required this.text,
    this.shouldBold = false,
    this.italic = false,
    this.size = 16,
    this.color,
    this.underline = false,
    this.onTap,
    this.splashColor,
    this.maxLines = 10,
    this.overflow = TextOverflow.ellipsis, // default to ellipsis
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: size,
        fontWeight: shouldBold ? FontWeight.w600 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? AppColors.white,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
        decorationColor: color ?? AppColors.textSecondary,
        decorationThickness: 1.5,
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            splashColor:
                splashColor ?? Theme.of(context).primaryColor.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: textWidget,
            ),
          )
        : textWidget;
  }
}
