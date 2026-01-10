import 'package:flutter/material.dart';
import '../theme/colors.dart';

class StatBlockDecoration {
  static Widget taperedRule() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentGold,
        gradient: LinearGradient(
          colors: [
            AppColors.accentGold.withOpacity(0),
            AppColors.accentGold,
            AppColors.accentGold.withOpacity(0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  static Widget headerRule() {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: const BoxDecoration(color: AppColors.accentGold),
    );
  }
}
