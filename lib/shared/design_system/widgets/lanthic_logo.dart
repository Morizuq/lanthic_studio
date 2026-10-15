import 'package:flutter/material.dart';

class LanthicLogo extends StatelessWidget {
  const LanthicLogo({
    super.key,
    this.size = 28,
    this.showText = true,
    this.textSize = 15,
  });

  final double size;
  final bool showText;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Lantern Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF00B8FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B8FF).withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/lanthic_lantern_icon.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              Icons.wb_incandescent_rounded,
              size: size * 0.65,
              color: const Color(0xFF00B8FF),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 9),
          Text.rich(
            TextSpan(
              text: 'Lanthic ',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: const Color(0xFF00B8FF),
              ),
              children: [
                TextSpan(
                  text: 'Studio',
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
