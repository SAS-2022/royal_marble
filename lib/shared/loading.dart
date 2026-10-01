import 'package:flutter/material.dart';
import 'package:royal_marble/core/app_theme.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
              strokeWidth: 3, color: AppColors.gold),
        ),
      ),
    );
  }
}
