import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:money_manager/core/constants/indian_banks.dart';

/// Displays a bank's logo if an asset exists, otherwise falls back to the
/// standard [Icons.account_balance_rounded] icon tinted with [color].
class BankLogo extends StatelessWidget {
  const BankLogo({
    super.key,
    required this.bank,
    required this.color,
    required this.size,
    this.borderRadius,
  });

  final IndianBank? bank;
  final Color color;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final asset = bank?.logoAsset;

    if (asset != null) {
      final radius = borderRadius ?? BorderRadius.circular(size * 0.25);
      Widget image;
      if (asset.endsWith('.svg')) {
        image = SvgPicture.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      } else {
        image = Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(width: size, height: size, child: image),
      );
    }

    // Fallback: tinted icon
    return Icon(
      Icons.account_balance_rounded,
      color: color,
      size: size * 0.55,
    );
  }
}
