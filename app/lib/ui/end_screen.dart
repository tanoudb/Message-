import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'palette.dart';

class EndScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onReplay;
  final VoidCallback? onSettings;
  const EndScreen(
      {super.key, required this.result, required this.onReplay, this.onSettings});

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: TweenAnimationBuilder<double>(
        // le verdict apparaît lentement dans le noir
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOut,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(
              r.won ? 'Tu as survécu.' : r.deathTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: r.won ? Palette.ok : Palette.danger),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                r.won
                    ? 'Entité : ${r.entityLabel} · ${r.exchanges} réponses · Suspicion finale : ${r.suspicion}/100.'
                    : r.deathSub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: Palette.textDim, height: 1.5),
              ),
            ),
            if (!r.won && r.strikes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Palette.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ce qui t'a trahi :",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Palette.textDim)),
                    ...r.strikes.map((s) => Text('• $s',
                        style: const TextStyle(
                            fontSize: 13, color: Palette.textDim, height: 1.6))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.btn,
                    foregroundColor: Palette.text,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onReplay,
                  child: const Text('Nouvelle partie',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
              if (onSettings != null)
                TextButton(
                  onPressed: onSettings,
                  child: const Text('Réglages',
                      style: TextStyle(fontSize: 13, color: Palette.textDim)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
