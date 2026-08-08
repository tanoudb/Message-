import 'dart:async';

import 'package:flutter/material.dart';

import '../ai/entity_voice.dart';
import '../engine/archetypes.dart';
import '../engine/game.dart';
import 'palette.dart';
import 'typing_indicator.dart';

/// Résultat d'une partie, transmis à l'écran de fin.
class GameResult {
  final bool won;
  final String entityLabel;
  final int exchanges;
  final int suspicion;
  final List<String> strikes;
  final String deathTitle;
  final String deathSub;
  const GameResult({
    required this.won,
    required this.entityLabel,
    required this.exchanges,
    required this.suspicion,
    required this.strikes,
    this.deathTitle = '',
    this.deathSub = '',
  });
}

enum _MsgKind { inn, out, sys, receipt }

class _Msg {
  final _MsgKind kind;
  final String text;
  const _Msg(this.kind, this.text);
}

class ChatScreen extends StatefulWidget {
  final GameEngine engine;

  /// Voix de l'entité : banques de répliques, ou LLM local qui les reformule.
  final EntityVoice voice;

  /// Batterie réelle au moment T (pour la mort du Creux), null si inconnue.
  final int? Function() batteryPct;
  final void Function(GameResult result) onFinished;

  /// Déclenche l'effet glitch plein écran (géré par le parent).
  final Future<void> Function() onGlitch;

  const ChatScreen({
    super.key,
    required this.engine,
    this.voice = const BankVoice(),
    required this.batteryPct,
    required this.onFinished,
    required this.onGlitch,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  GameEngine get engine => widget.engine;

  final List<_Msg> _msgs = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _typing = false;
  String _sub = 'en ligne';
  bool _handling = false;
  bool _ended = false;
  DateTime _qShownAt = DateTime.now();
  Timer? _nudgeTimer;
  String _lastPlayerText = '';

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(_MsgKind.sys, "Aujourd'hui ${fmtTime()}"));
    _runIntro();
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /* ---------- primitives de conversation ---------- */

  Future<void> _sleep(int ms) => Future.delayed(Duration(milliseconds: ms));
  int _randInt(int a, int b) => a + engine.rng.nextInt(b - a + 1);

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _addMsg(_MsgKind kind, String text) {
    if (!mounted) return;
    setState(() => _msgs.add(_Msg(kind, text)));
    _scrollDown();
  }

  Future<void> _entitySay(String text) async {
    if (_ended || !mounted) return;
    setState(() {
      _sub = "en train d'écrire…";
      _typing = true;
    });
    _scrollDown();
    await _sleep(engine.typingDelayMs(text));
    if (!mounted) return;
    setState(() {
      _typing = false;
      _sub = 'en ligne';
    });
    _addMsg(_MsgKind.inn, engine.style(text));
    await _sleep(_randInt(300, 700));
  }

  /// Une chaîne vide = un temps de silence (le Creux s'en sert).
  Future<void> _entitySayAll(List<String> list) async {
    for (final t in list) {
      if (t.isNotEmpty) {
        await _entitySay(t);
      } else {
        await _sleep(_randInt(900, 1600));
      }
    }
  }

  /* ---------- voix (IA locale ou banques) ---------- */

  /// Derniers échanges affichés, pour donner du contexte au modèle.
  List<VoiceTurn> _history([int n = 6]) => _msgs
      .where((m) => m.kind == _MsgKind.inn || m.kind == _MsgKind.out)
      .toList()
      .reversed
      .take(n)
      .toList()
      .reversed
      .map((m) => VoiceTurn(m.kind == _MsgKind.out, m.text))
      .toList();

  static String _intentFor(Verdict? v) => switch (v) {
        Verdict.contradiction =>
          "fais-lui comprendre qu'il vient de se contredire, sans détailler ce que tu sais",
        Verdict.hourOff => "note que son horaire ne colle pas tout à fait",
        Verdict.memhole =>
          'relève son trou de mémoire : on n\'oublie pas ce qu\'on a vécu hier',
        Verdict.unsure =>
          'sa réponse est floue : pousse-le à répondre vraiment, sans l\'aider',
        Verdict.good => 'accuse réception à ta manière avant de passer à la suite',
        null => 'réagis à son message à ta manière',
      };

  /// Fait parler l'entité via la voix : la génération du modèle se fait
  /// PENDANT que l'indicateur « en train d'écrire… » est affiché, donc la
  /// latence de l'IA devient du temps de frappe crédible.
  Future<void> _sayVoiced(String base, {required String intent}) async {
    if (_ended || !mounted) return;
    if (base.isEmpty) {
      await _sleep(_randInt(900, 1600));
      return;
    }
    setState(() {
      _sub = "en train d'écrire…";
      _typing = true;
    });
    _scrollDown();
    final generation = widget.voice.render(
      archId: engine.arch.id,
      base: base,
      intent: intent,
      playerText: _lastPlayerText,
      history: _history(),
    );
    final minDelay = _sleep(engine.typingDelayMs(base));
    final text = await generation;
    await minDelay;
    if (!mounted) return;
    await _showBubbles(text);
  }

  /// Affiche un texte comme 1 ou 2 bulles (les messages longs se coupent
  /// à une fin de phrase, comme quelqu'un qui envoie deux SMS).
  Future<void> _showBubbles(String text) async {
    var parts = <String>[text];
    if (text.length > 90) {
      final m = RegExp(r'^(.{40,110}[.!?…])\s+(.+)$').firstMatch(text);
      if (m != null) parts = [m.group(1)!, m.group(2)!];
    }
    setState(() {
      _typing = false;
      _sub = 'en ligne';
    });
    _addMsg(_MsgKind.inn, engine.style(parts.first));
    for (final p in parts.skip(1)) {
      await _sleep(_randInt(250, 500));
      if (!mounted) return;
      setState(() => _typing = true);
      _scrollDown();
      await _sleep(engine.typingDelayMs(p) ~/ 2);
      if (!mounted) return;
      setState(() => _typing = false);
      _addMsg(_MsgKind.inn, engine.style(p));
    }
    await _sleep(_randInt(300, 700));
  }

  /// Comme [_entitySayAll], mais à travers la voix.
  Future<void> _sayVoicedAll(List<String> list, {required String intent}) async {
    for (final t in list) {
      await _sayVoiced(t, intent: intent);
    }
  }

  /* ---------- relance temporisée ---------- */

  void _clearNudge() {
    _nudgeTimer?.cancel();
    _nudgeTimer = null;
  }

  void _armNudge() {
    _clearNudge();
    final n = engine.arch.nudge;
    if (n == null) return;
    _nudgeTimer = Timer(Duration(milliseconds: n.afterMs), () async {
      if (_ended || _handling || engine.current == null || !mounted) return;
      engine.suspicion += n.susp;
      await _entitySay(n.texts[engine.rng.nextInt(n.texts.length)]);
    });
  }

  /* ---------- déroulé ---------- */

  Future<void> _runIntro() async {
    await _sleep(1000);
    await _entitySayAll(engine.introLines());
    await _askNext();
  }

  Future<void> _askNext() async {
    if (_ended) return;
    final step = engine.nextStep();
    if (step == null) return _win();
    await _entitySay(step.text);
    _qShownAt = DateTime.now();
    _armNudge();
  }

  Future<void> _submit() async {
    if (_ended) return;
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    _clearNudge();
    _addMsg(_MsgKind.out, text);
    _lastPlayerText = text;
    await _sleep(_randInt(350, 800));
    _addMsg(_MsgKind.receipt, 'Lu à ${fmtTime()}');

    if (_handling || engine.current == null) {
      // message hors question (ou entité en train de réagir) : avec l'IA
      // locale, l'entité répond au contenu puis ramène à l'interrogatoire
      final r = engine.offtopic();
      if (r != null && !_handling) {
        setState(() {
          _sub = "en train d'écrire…";
          _typing = true;
        });
        _scrollDown();
        final generation = widget.voice.freeReply(
          archId: engine.arch.id,
          base: r,
          playerText: text,
          history: _history(),
        );
        final minDelay = _sleep(engine.typingDelayMs(r));
        final reply = await generation;
        await minDelay;
        if (!mounted) return;
        await _showBubbles(reply);
      }
      return;
    }

    _handling = true;
    try {
      final elapsed = DateTime.now().difference(_qShownAt).inMilliseconds;
      final outcome = engine.submitAnswer(text, elapsedMs: elapsed);

      if (outcome.dead) return await _death();

      if (outcome.retry) {
        await _sayVoicedAll(outcome.reactions, intent: _intentFor(outcome.verdict));
        _qShownAt = DateTime.now();
        _armNudge();
        return;
      }

      await _sayVoicedAll(outcome.reactions, intent: _intentFor(outcome.verdict));
      if (outcome.warned) await _entitySay(engine.arch.warn);
      await _askNext();
    } finally {
      _handling = false;
    }
  }

  /* ---------- fins ---------- */

  Future<void> _win() async {
    await _entitySayAll(engine.winLines());
    await _sleep(1500);
    _ended = true;
    widget.onFinished(GameResult(
      won: true,
      entityLabel: engine.arch.label,
      exchanges: engine.exchanges,
      suspicion: engine.suspicion,
      strikes: const [],
    ));
  }

  Future<void> _death() async {
    _clearNudge();
    await _entitySayAll(engine.deathLines(fmtTime()));
    switch (engine.arch.deathStyle) {
      case DeathStyle.flood:
        await _deathFlood();
      case DeathStyle.silence:
        await _deathSilence();
      case DeathStyle.echo:
        await _deathEcho();
      case DeathStyle.glitch:
        if (mounted) {
          setState(() =>
              _sub = engine.arch.id == 'confidente' ? 'position : proche' : 'hors ligne');
        }
    }
    _ended = true;
    await widget.onGlitch();
    widget.onFinished(GameResult(
      won: false,
      entityLabel: engine.arch.label,
      exchanges: engine.exchanges,
      suspicion: engine.suspicion,
      strikes: List.of(engine.strikes),
      deathTitle: engine.arch.deathTitle,
      deathSub: engine.arch.deathSub,
    ));
  }

  /// Métronome : flood illisible, l'indicateur de frappe ne s'arrête plus.
  Future<void> _deathFlood() async {
    for (var i = 0; i < 16; i++) {
      _addMsg(_MsgKind.inn, metronomeFlood[engine.rng.nextInt(metronomeFlood.length)]);
      await _sleep(_randInt(60, 180));
    }
    if (mounted) {
      setState(() {
        _sub = "en train d'écrire…";
        _typing = true;
      });
    }
    _scrollDown();
    await _sleep(2600);
  }

  /// Creux : silence, faux départs de frappe, puis les vraies données du téléphone.
  Future<void> _deathSilence() async {
    if (mounted) setState(() => _sub = '…');
    await _sleep(2500);
    if (mounted) setState(() => _typing = true);
    _scrollDown();
    await _sleep(2200);
    if (mounted) setState(() => _typing = false);
    await _sleep(3000);
    if (mounted) setState(() => _typing = true);
    await _sleep(1500);
    if (mounted) setState(() => _typing = false);
    await _sleep(2600);
    final batt = widget.batteryPct();
    _addMsg(_MsgKind.inn,
        'il est ${fmtTime()}.${batt != null ? ' ta batterie est à $batt%.' : ''}');
    await _sleep(2400);
    _addMsg(_MsgKind.inn, "je n'ai plus de questions.");
    await _sleep(1800);
    if (mounted) setState(() => _sub = 'à proximité');
    await _sleep(2200);
  }

  /// Miroir : renvoie mot pour mot la plus longue phrase du joueur.
  Future<void> _deathEcho() async {
    await _sleep(1600);
    _addMsg(_MsgKind.inn, engine.mirror.longestMessage());
    await _sleep(2400);
    _addMsg(_MsgKind.inn, "c'est toi qui l'as écrit.");
    await _sleep(1400);
    _addMsg(_MsgKind.inn, "ou c'est moi.");
    await _sleep(1400);
    _addMsg(_MsgKind.inn, 'on ne sait plus, hein ?');
    await _sleep(1800);
  }

  /* ---------- rendu ---------- */

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 34),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Palette.border))),
        child: Row(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFF2C2F38),
            child: Text(engine.arch.avatar,
                style: const TextStyle(fontSize: 17, color: Palette.textDim)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(engine.arch.nom,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(_sub, style: const TextStyle(fontSize: 12, color: Palette.textDim)),
          ]),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          itemCount: _msgs.length + (_typing ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _msgs.length) {
              return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                      padding: EdgeInsets.only(top: 3), child: TypingIndicator()));
            }
            return _bubble(_msgs[i]);
          },
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Palette.surface,
                  border: Border.all(color: const Color(0xFF23252C)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  enabled: !_ended,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(fontSize: 15.5),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Palette.textDim),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder(
              valueListenable: _inputCtrl,
              builder: (context, v, _) {
                final canSend = !_ended && v.text.trim().isNotEmpty;
                return SizedBox(
                  width: 42,
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.bubbleOut,
                      disabledBackgroundColor: Palette.bubbleOut.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: canSend ? _submit : null,
                    child: const Text('➤',
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _bubble(_Msg m) {
    switch (m.kind) {
      case _MsgKind.sys:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
              child: Text(m.text,
                  style: const TextStyle(fontSize: 12, color: Palette.textDim))),
        );
      case _MsgKind.receipt:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6, right: 6),
          child: Align(
              alignment: Alignment.centerRight,
              child: Text(m.text,
                  style: const TextStyle(fontSize: 11, color: Palette.textDim))),
        );
      case _MsgKind.inn || _MsgKind.out:
        final isIn = m.kind == _MsgKind.inn;
        return Align(
          alignment: isIn ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: isIn ? Palette.bubbleIn : Palette.bubbleOut,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isIn ? 5 : 18),
                bottomRight: Radius.circular(isIn ? 18 : 5),
              ),
            ),
            child: Text(m.text, style: const TextStyle(fontSize: 15.5, height: 1.35)),
          ),
        );
    }
  }
}
