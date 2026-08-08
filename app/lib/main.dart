import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai/ai_settings.dart';
import 'ai/entity_voice.dart';
import 'engine/game.dart';
import 'ui/ai_settings_sheet.dart';
import 'ui/alibi_screen.dart';
import 'ui/chat_screen.dart';
import 'ui/end_screen.dart';
import 'ui/lock_screen.dart';
import 'ui/palette.dart';
import 'ui/sfx.dart';
import 'ui/status_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Immersif : le jeu EST le téléphone, pas de vraie barre système
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  Sfx.load();
  runApp(const MessagesApp());
}

class MessagesApp extends StatelessWidget {
  const MessagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messages',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bg,
        colorScheme: const ColorScheme.dark(
          surface: Palette.bg,
          primary: Palette.bubbleOut,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Palette.text),
        ),
      ),
      home: const GamePage(),
    );
  }
}

enum Phase { lock, alibi, chat, end }

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GameEngine _engine = GameEngine();
  final Battery _battery = Battery();

  Phase _phase = Phase.lock;
  GameResult? _result;
  int? _batteryPct;
  Timer? _battTimer;
  Timer? _clock;
  bool _glitch = false;
  bool _dim = false;
  int _runId = 0; // invalide les ChatScreen des parties précédentes

  AiSettings? _aiSettings;
  EntityVoice _voice = const BankVoice();
  GemmaVoice? _gemma; // gardé chargé entre les parties (init coûteuse)

  @override
  void initState() {
    super.initState();
    _refreshBattery();
    _battTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refreshBattery());
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    _initAi();
  }

  Future<void> _initAi() async {
    final s = await AiSettings.load();
    _aiSettings = s;
    if (s.enabled && s.modelInstalled) {
      await _loadGemma(s);
    }
  }

  Future<void> _loadGemma(AiSettings s) async {
    try {
      // modèle installé par fichier : re-déclarer le chemin ; téléchargé
      // en interne par flutter_gemma : le modèle actif est déjà persisté
      if (s.modelPath != null) {
        await AiSettings.declareToGemma(s.modelPath!);
      }
      final g = GemmaVoice();
      if (await g.init()) {
        _gemma = g;
        _voice = g;
      }
    } catch (_) {
      // modèle illisible → banques ; le jeu reste jouable
      _voice = const BankVoice();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openAiSettings() async {
    final s = _aiSettings ?? await AiSettings.load();
    _aiSettings = s;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Palette.surface,
      isScrollControlled: true, // laisse la place au clavier (URL, jeton)
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AiSettingsSheet(settings: s),
    );
    // applique le choix au retour de la feuille
    if (s.enabled && s.modelInstalled) {
      if (_gemma == null) await _loadGemma(s);
    } else {
      await _gemma?.dispose();
      _gemma = null;
      _voice = const BankVoice();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _battTimer?.cancel();
    _clock?.cancel();
    _gemma?.dispose();
    super.dispose();
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryPct = level);
    } catch (_) {
      // pas de plugin (tests, desktop) : on n'affiche pas de valeur inventée
    }
  }

  void _startRun() {
    Sfx.play('unlock', volume: 0.5);
    _engine.startRun();
    setState(() {
      _runId++;
      _phase = Phase.alibi;
      _result = null;
    });
  }

  Future<void> _playGlitch() async {
    HapticFeedback.heavyImpact();
    Sfx.play('glitch', volume: 0.7);
    for (var i = 0; i < 7; i++) {
      if (!mounted) return;
      setState(() => _glitch = true);
      await Future.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      setState(() => _glitch = false);
      await Future.delayed(const Duration(milliseconds: 60));
      if (i == 3) HapticFeedback.heavyImpact();
    }
    if (!mounted) return;
    setState(() => _dim = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _dim = false);
  }

  void _onFinished(GameResult r) {
    if (!mounted) return;
    setState(() {
      _result = r;
      _phase = Phase.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = switch (_phase) {
      Phase.lock => LockScreen(onUnlock: _startRun, onSettings: _openAiSettings),
      Phase.alibi => AlibiScreen(
          alibi: _engine.alibi,
          onDone: () => setState(() => _phase = Phase.chat),
        ),
      Phase.chat => ChatScreen(
          key: ValueKey('chat$_runId'),
          engine: _engine,
          voice: _voice,
          batteryPct: () => _batteryPct,
          onFinished: _onFinished,
          onGlitch: _playGlitch,
        ),
      Phase.end => EndScreen(
          result: _result!, onReplay: _startRun, onSettings: _openAiSettings),
    };

    Widget phone = Column(children: [
      if (_phase != Phase.lock && _phase != Phase.end)
        StatusBar(batteryPct: _batteryPct),
      Expanded(child: screen),
    ]);

    // Effet glitch : inversion des couleurs + petit décalage horizontal
    if (_glitch) {
      phone = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: Transform.translate(offset: const Offset(3, 0), child: phone),
      );
    }
    if (_dim) {
      phone = AnimatedOpacity(
        opacity: 0.55,
        duration: const Duration(seconds: 1),
        child: phone,
      );
    }

    return Scaffold(body: phone);
  }
}
