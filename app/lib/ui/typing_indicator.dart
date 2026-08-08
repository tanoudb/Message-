import 'package:flutter/material.dart';

import 'palette.dart';

/// Bulle "en train d'écrire…" : trois points qui dansent.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: const BoxDecoration(
        color: Palette.bubbleIn,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(5),
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              // même chorégraphie que le CSS : décalage de 0.15s par point
              final t = (_c.value - i * 0.125) % 1.0;
              final up = t >= 0 && t < 0.6 ? (0.3 - (t - 0.3).abs()).clamp(0.0, 0.3) / 0.3 : 0.0;
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Transform.translate(
                  offset: Offset(0, -4 * up),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Palette.textDim.withValues(alpha: 0.4 + 0.6 * up),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
