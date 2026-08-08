/// Méta-progression persistante : les « nuits ».
/// Chaque partie est une nuit. Survivre allonge la série ; mourir la
/// casse. Le dossier des entités se remplit quand on survit à chacune.
/// La série courante définit la difficulté des nuits suivantes.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Progress {
  static const _kKey = 'progress_v1';

  int nights;
  int wins;
  int streak;
  int bestStreak;

  /// Nombre de fragments du récit déjà reçus.
  int fragments;

  /// Nombre de survies par archétype (id → victoires)
  final Map<String, int> survived;

  /// Archétypes déjà rencontrés (même sans survivre)
  final Set<String> seen;

  /// Ce que le joueur a improvisé la nuit précédente : l'entité s'en
  /// sert pour le confronter à ses propres inventions (label → mots).
  final Map<String, String> lastLies;

  Progress({
    this.nights = 0,
    this.wins = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.fragments = 0,
    Map<String, int>? survived,
    Set<String>? seen,
    Map<String, String>? lastLies,
  })  : survived = survived ?? {},
        seen = seen ?? {},
        lastLies = lastLies ?? {};

  /// La difficulté des prochaines nuits (0 à 5) suit la série courante.
  int get difficulty => streak > 5 ? 5 : streak;

  void recordRun({required String archId, required bool won}) {
    nights++;
    seen.add(archId);
    if (won) {
      wins++;
      streak++;
      if (streak > bestStreak) bestStreak = streak;
      survived[archId] = (survived[archId] ?? 0) + 1;
    } else {
      streak = 0;
    }
  }

  static Future<Progress> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kKey);
      if (raw == null) return Progress();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return Progress(
        nights: j['nights'] as int? ?? 0,
        wins: j['wins'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        bestStreak: j['bestStreak'] as int? ?? 0,
        fragments: j['fragments'] as int? ?? 0,
        survived: (j['survived'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
        seen: ((j['seen'] as List<dynamic>?) ?? []).cast<String>().toSet(),
        lastLies: (j['lastLies'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as String)),
      );
    } catch (_) {
      return Progress();
    }
  }

  Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _kKey,
          jsonEncode({
            'nights': nights,
            'wins': wins,
            'streak': streak,
            'bestStreak': bestStreak,
            'fragments': fragments,
            'survived': survived,
            'seen': seen.toList(),
            'lastLies': lastLies,
          }));
    } catch (_) {}
  }
}
