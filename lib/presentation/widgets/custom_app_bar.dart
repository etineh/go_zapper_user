import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gozapper/core/extension/inbuilt_ext.dart';

import '../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? titleColor;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.onBack,
    this.backgroundColor,
    this.titleColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Platform.isAndroid ? Icons.arrow_back : Icons.arrow_back_ios,
            color: titleColor ?? AppColors.textPrimary),
        onPressed: onBack ?? () => context.goBack(),
      ),
      title: Text(
        title ?? "",
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
