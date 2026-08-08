/// La « voix » de l'entité : ce qui transforme une intention de jeu en
/// message affiché.
///
/// Deux implémentations :
///  - [BankVoice]  : renvoie la réplique de banque telle quelle (toujours
///    disponible, comportement historique) ;
///  - [GemmaVoice] : LLM local sur l'appareil (MediaPipe / flutter_gemma).
///    Le moteur de règles reste le juge — le modèle ne fait que REFORMULER
///    une réplique de référence dans le style du personnage, ou répondre
///    à un message hors interrogatoire. Toute erreur ou lenteur retombe
///    sur la réplique de banque : le jeu ne casse jamais.
library;

import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';

import 'personas.dart';

/// Un échange affiché, pour donner du contexte au modèle.
class VoiceTurn {
  final bool fromPlayer;
  final String text;
  const VoiceTurn(this.fromPlayer, this.text);
}

abstract class EntityVoice {
  bool get ready;

  /// Reformule [base] (réplique de référence, sens à conserver) dans le
  /// style de l'archétype [archId]. [intent] décrit ce que le message doit
  /// exprimer, [playerText] est le dernier message du joueur, [history]
  /// les derniers échanges affichés.
  Future<String> render({
    required String archId,
    required String base,
    required String intent,
    String playerText = '',
    List<VoiceTurn> history = const [],
  });

  /// Réponse libre à un message hors interrogatoire (pas de réplique de
  /// référence imposée ; [base] sert de repli).
  Future<String> freeReply({
    required String archId,
    required String base,
    required String playerText,
    List<VoiceTurn> history = const [],
  });

  Future<void> dispose();
}

/// Voix « banques » : comportement historique, zéro dépendance.
class BankVoice implements EntityVoice {
  const BankVoice();

  @override
  bool get ready => true;

  @override
  Future<String> render({
    required String archId,
    required String base,
    required String intent,
    String playerText = '',
    List<VoiceTurn> history = const [],
  }) async =>
      base;

  @override
  Future<String> freeReply({
    required String archId,
    required String base,
    required String playerText,
    List<VoiceTurn> history = const [],
  }) async =>
      base;

  @override
  Future<void> dispose() async {}
}

/* =====================================================================
   Construction de prompt et nettoyage de sortie — fonctions pures,
   testables sans modèle.
   ===================================================================== */

String buildRewritePrompt({
  required String archId,
  required String base,
  required String intent,
  required String playerText,
  required List<VoiceTurn> history,
}) {
  final persona = personas[archId] ?? '';
  final h = history
      .map((t) => t.fromPlayer ? 'Joueur : ${t.text}' : 'Toi : ${t.text}')
      .join('\n');
  return '''
$persona

Tu interroges quelqu'un par SMS sur sa soirée d'hier, dans un jeu d'horreur.
Derniers échanges :
$h
${playerText.isNotEmpty ? 'Dernier message du joueur : $playerText' : ''}

Ce que ton prochain SMS doit exprimer : $intent
Réplique de référence (garde exactement ce sens) : $base

Écris UNIQUEMENT ton prochain SMS, en français, dans ton style.
Maximum 2 phrases courtes. Pas de guillemets, pas de préfixe, pas d'explication.''';
}

String buildFreeReplyPrompt({
  required String archId,
  required String playerText,
  required List<VoiceTurn> history,
}) {
  final persona = personas[archId] ?? '';
  final h = history
      .map((t) => t.fromPlayer ? 'Joueur : ${t.text}' : 'Toi : ${t.text}')
      .join('\n');
  return '''
$persona

Tu interroges quelqu'un par SMS sur sa soirée d'hier, dans un jeu d'horreur.
Le joueur vient d'écrire un message qui sort de ton interrogatoire.
Derniers échanges :
$h
Message du joueur : $playerText

Réponds-lui en une phrase dans ton style, puis ramène-le à ton interrogatoire.
Ne révèle jamais qui tu es, ne réponds à aucune question sur ta nature.
Écris UNIQUEMENT ton SMS, en français. Pas de guillemets, pas de préfixe.''';
}

/// Nettoie une sortie de modèle pour qu'elle ressemble à un SMS de l'entité.
String cleanLlmOutput(String raw, {int maxChars = 160}) {
  var t = raw.trim();
  // retire un éventuel préfixe de rôle
  t = t.replaceFirst(RegExp(r'^(Toi|Entité|SMS|Réponse)\s*:\s*', caseSensitive: false), '');
  // première ligne non vide seulement (un SMS = une bulle)
  final lines = t.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return '';
  t = lines.first.trim();
  // retire les guillemets d'encadrement
  t = t.replaceAll(RegExp(r'^[«"\s]+|[»"\s]+$'), '');
  // coupe proprement si trop long
  if (t.length > maxChars) {
    final cut = t.substring(0, maxChars);
    final lastStop = cut.lastIndexOf(RegExp(r'[.!?…]'));
    t = lastStop > 40 ? cut.substring(0, lastStop + 1) : '$cut…';
  }
  return t;
}

/// Voix LLM locale (Gemma via MediaPipe). Modèle .task fourni par
/// l'utilisateur (voir l'écran de réglages IA).
class GemmaVoice implements EntityVoice {
  InferenceModel? _model;
  bool _initFailed = false;

  /// Budget temps par génération : au-delà, on rend la réplique de banque.
  final Duration timeout;

  GemmaVoice({this.timeout = const Duration(seconds: 8)});

  @override
  bool get ready => _model != null;

  Future<bool> init() async {
    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );
      return true;
    } catch (_) {
      // GPU indisponible → tentative CPU, sinon repli banques
      try {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 1024,
          preferredBackend: PreferredBackend.cpu,
        );
        return true;
      } catch (_) {
        _initFailed = true;
        return false;
      }
    }
  }

  Future<String> _generate(String prompt, String fallback) async {
    final model = _model;
    if (model == null || _initFailed) return fallback;
    InferenceModelSession? session;
    try {
      session = await model.createSession(temperature: 0.7, topK: 40, topP: 0.9);
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      final raw = await session.getResponse().timeout(timeout);
      final cleaned = cleanLlmOutput(raw);
      return cleaned.isEmpty ? fallback : cleaned;
    } catch (_) {
      return fallback;
    } finally {
      try {
        await session?.close();
      } catch (_) {}
    }
  }

  @override
  Future<String> render({
    required String archId,
    required String base,
    required String intent,
    String playerText = '',
    List<VoiceTurn> history = const [],
  }) {
    if (base.isEmpty) return Future.value(base); // silence voulu : on le garde
    return _generate(
      buildRewritePrompt(
          archId: archId,
          base: base,
          intent: intent,
          playerText: playerText,
          history: history),
      base,
    );
  }

  @override
  Future<String> freeReply({
    required String archId,
    required String base,
    required String playerText,
    List<VoiceTurn> history = const [],
  }) {
    return _generate(
      buildFreeReplyPrompt(archId: archId, playerText: playerText, history: history),
      base,
    );
  }

  @override
  Future<void> dispose() async {
    try {
      await _model?.close();
    } catch (_) {}
    _model = null;
  }
}
