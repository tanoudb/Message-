import 'package:flutter/material.dart';

import '../engine/archetypes.dart';
import '../meta/progress.dart';
import '../meta/story.dart';
import 'chat_screen.dart';
import 'palette.dart';

class EndScreen extends StatelessWidget {
  final GameResult result;
  final Progress? progress;
  final VoidCallback onReplay;
  final VoidCallback? onSettings;
  final VoidCallback? onArchives;
  const EndScreen({
    super.key,
    required this.result,
    this.progress,
    required this.onReplay,
    this.onSettings,
    this.onArchives,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final p = progress;
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
          child: SingleChildScrollView(
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
                                fontSize: 13,
                                color: Palette.textDim,
                                height: 1.6))),
                      ],
                    ),
                  ),
                ],
                if (p != null) ...[
                  const SizedBox(height: 18),
                  _NightStats(progress: p, won: r.won),
                  if (onArchives != null) ...[
                    const SizedBox(height: 12),
                    _ArchivesTeaser(progress: p, onTap: onArchives!),
                  ],
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
                      child: Text(
                          r.won && p != null && p.streak > 0
                              ? 'Nuit suivante'
                              : 'Nouvelle nuit',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                if (onSettings != null)
                  TextButton(
                    onPressed: onSettings,
                    child: const Text('Réglages',
                        style:
                            TextStyle(fontSize: 13, color: Palette.textDim)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L'accroche des Archives : ce qui vient d'être obtenu, et ce qui manque.
class _ArchivesTeaser extends StatelessWidget {
  final Progress progress;
  final VoidCallback onTap;
  const _ArchivesTeaser({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final got = progress.fragments;
    final reste = storyLength - got;
    final dernier = got > 0 ? storyFragments[got - 1].titre : null;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.surface,
              border: Border.all(color: Palette.accent.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_outlined,
                        size: 16, color: Palette.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dernier == null
                            ? 'Archives'
                            : 'Fragment obtenu — $dernier',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Palette.accent),
                      ),
                    ),
                    Text('$got/$storyLength',
                        style: const TextStyle(
                            fontSize: 12, color: Palette.textDim)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reste > 0
                      ? "Elle n'a pas fini de parler. $reste ${reste == 1 ? 'fragment' : 'fragments'} restants."
                      : 'Le carnet est complet.',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Palette.textDim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc de progression : nuit, série, record, dossier des entités.
class _NightStats extends StatelessWidget {
  final Progress progress;
  final bool won;
  const _NightStats({required this.progress, required this.won});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final unseen = allArchetypes.where((a) => !p.seen.contains(a.id)).length;
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Nuit n°${p.nights} · Série : ${p.streak} · Record : ${p.bestStreak}',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Palette.text),
          ),
          if (p.streak >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Les nuits se durcissent. Niveau ${p.difficulty}.',
                style: const TextStyle(fontSize: 12, color: Palette.accent),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final a in allArchetypes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _EntityDot(
                    avatar: a.avatar,
                    seen: p.seen.contains(a.id),
                    beaten: (p.survived[a.id] ?? 0) > 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            unseen > 0
                ? (unseen == 1
                    ? "Quelque chose ne t'a pas encore parlé."
                    : '$unseen entités ne se sont pas encore montrées.')
                : ((p.survived.length) >= allArchetypes.length
                    ? 'Tu as survécu aux cinq. Elles le savent.'
                    : 'Tu les as toutes rencontrées. Pas toutes vaincues.'),
            style: const TextStyle(
                fontSize: 12, fontStyle: FontStyle.italic, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}

class _EntityDot extends StatelessWidget {
  final String avatar;
  final bool seen;
  final bool beaten;
  const _EntityDot({required this.avatar, required this.seen, required this.beaten});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C2F38),
        border: Border.all(
          color: beaten
              ? Palette.ok
              : (seen ? Palette.textDim : const Color(0xFF23252C)),
          width: beaten ? 1.6 : 1,
        ),
      ),
      child: Text(
        seen ? avatar : '?',
        style: TextStyle(
            fontSize: 15,
            color: beaten
                ? Palette.text
                : (seen ? Palette.textDim : const Color(0xFF3A3D46))),
      ),
    );
  }
}
