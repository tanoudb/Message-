import 'package:flutter/material.dart';

/// Palette du prototype HTML, reprise à l'identique.
abstract final class Palette {
  static const bg = Color(0xFF0B0C0F);
  static const surface = Color(0xFF15171C);
  static const bubbleIn = Color(0xFF24262E);
  static const bubbleOut = Color(0xFF1C4FD6);
  static const text = Color(0xFFE8EAEF);
  static const textDim = Color(0xFF8B8F9A);
  static const danger = Color(0xFFFF5252);
  static const ok = Color(0xFF43D17A);
  static const border = Color(0xFF1D1F26);
  static const btn = Color(0xFF2A2D36);
  static const accent = Color(0xFFE8B64C);
}

String fmtTime([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
  'septembre', 'octobre', 'novembre', 'décembre'
];

String fmtDate([DateTime? d]) {
  final t = d ?? DateTime.now();
  final jour = _jours[t.weekday - 1];
  return '${jour[0].toUpperCase()}${jour.substring(1)} ${t.day} ${_mois[t.month - 1]}';
}
