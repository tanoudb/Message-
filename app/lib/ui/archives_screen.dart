import 'package:flutter/material.dart';

import '../meta/progress.dart';
import '../meta/story.dart';
import 'palette.dart';

/// Les Archives : ce que l'entité a laissé filtrer, nuit après nuit.
/// Les fragments non obtenus restent masqués — on voit ce qui manque.
class ArchivesScreen extends StatelessWidget {
  final Progress progress;
  final VoidCallback onClose;
  const ArchivesScreen({super.key, required this.progress, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final got = progress.fragments;
    return Container(
      color: Palette.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ARCHIVES',
                            style: TextStyle(
                                fontSize: 13,
                                color: Palette.accent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('$got / $storyLength fragments',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Palette.textDim),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Palette.border),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: storyFragments.length,
                itemBuilder: (context, i) {
                  final unlocked = i < got;
                  final f = storyFragments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unlocked ? f.titre : '${_roman(i + 1)}. ————',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: unlocked ? Palette.text : Palette.textDim,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (unlocked)
                          Text(
                            f.lignes.join('\n'),
                            style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.55,
                                color: Palette.textDim),
                          )
                        else
                          Text(
                            _masked(f),
                            style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.55,
                                color: Color(0xFF2A2D36),
                                letterSpacing: 1),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (got < storyLength)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  got == 0
                      ? "L'entité laisse échapper quelque chose à la fin de chaque nuit."
                      : 'Il reste ${storyLength - got} ${storyLength - got == 1 ? "fragment" : "fragments"}. Une nuit, un fragment.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Palette.textDim),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  'Le carnet est complet. Elle sait où te trouver.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Palette.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Le texte masqué garde la forme du fragment : on voit sa longueur.
  static String _masked(Fragment f) => f.lignes
      .map((l) => l.replaceAll(RegExp(r'\S'), '·'))
      .join('\n');

  static String _roman(int n) {
    const r = [
      'I', 'II', 'III', 'IV', 'V', 'VI',
      'VII', 'VIII', 'IX', 'X', 'XI', 'XII'
    ];
    return n >= 1 && n <= r.length ? r[n - 1] : '$n';
  }
}
