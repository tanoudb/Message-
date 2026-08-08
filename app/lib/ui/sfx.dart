/// Effets sonores du jeu — WAV générés procéduralement (assets/sfx/).
/// Tout est optionnel et silencieux en cas d'erreur (tests, plateformes
/// sans plugin audio) : le jeu ne dépend jamais du son.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class Sfx {
  static bool enabled = true;
  static const _kPref = 'sound_enabled';

  static final Map<String, AudioPlayer> _players = {};

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool(_kPref) ?? true;
    } catch (_) {}
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kPref, v);
    } catch (_) {}
  }

  /// Joue un effet : 'receive', 'send', 'unlock', 'glitch', 'drone'.
  static Future<void> play(String name, {double volume = 1.0}) async {
    if (!enabled) return;
    try {
      final player = _players.putIfAbsent(name, AudioPlayer.new);
      await player.stop();
      await player.play(AssetSource('sfx/$name.wav'), volume: volume);
    } catch (_) {
      // pas de plugin audio (tests) ou asset manquant : on joue sans son
    }
  }

  static Future<void> dispose() async {
    for (final p in _players.values) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _players.clear();
  }
}
