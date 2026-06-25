import 'package:flutter/material.dart';
import '../config/app_constants.dart';

class SipLogo extends StatelessWidget {
  final double size;
  final bool inverted;
  final bool showText;

  const SipLogo({
    super.key,
    this.size = 40,
    this.inverted = false,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoDecoration = BoxDecoration(
      gradient: inverted
          ? null
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.colorPrimary,
                Color(0xFFA30D25),
              ],
            ),
      color: inverted ? Colors.white : null,
      borderRadius: BorderRadius.circular(size * 0.25),
      boxShadow: [
        BoxShadow(
          color: (inverted ? Colors.black : AppConstants.colorPrimary).withOpacity(0.15),
          blurRadius: size * 0.15,
          offset: Offset(0, size * 0.08),
        ),
      ],
      border: inverted ? null : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
    );

    final logoWidget = Container(
      width: size,
      height: size,
      decoration: logoDecoration,
      alignment: Alignment.center,
      child: Text(
        'BN',
        style: TextStyle(
          color: inverted ? AppConstants.colorPrimary : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.45,
          letterSpacing: -0.8,
        ),
      ),
    );

    if (!showText) {
      return logoWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(width: 8),
        Text(
          'Banco de la Nación',
          style: TextStyle(
            color: inverted ? Colors.white : AppConstants.colorTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
