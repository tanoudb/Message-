/// Cœur du moteur de jeu, indépendant de Flutter : état de la partie,
/// file de questions, évaluation des réponses, jugement.
///
/// L'UI pilote le rythme (délais de frappe, relances temporisées, mises
/// en scène de mort) ; le moteur ne connaît que la logique.
library;

import 'dart:math';

import 'alibi.dart';
import 'archetypes.dart';
import 'text_utils.dart';

enum StepType { fact, probe, reprobe, reprobeMarker }

class Step {
  final StepType type;

  /// Pour fact : 'lieu' | 'detail' | 'hArrivee' | 'transport' | 'hRetour'
  final String? kind;

  /// Pour probe : la sonde/question de creusement
  final Creuse? p;

  /// Pour reprobe : clé + label de l'improvisation re-vérifiée
  final String? key;
  final String? label;
  final String text;

  /// Pour fact : d'où creuser après une bonne réponse ('lieu' | 'transport')
  final String? creuseFrom;

  const Step({
    required this.type,
    this.kind,
    this.p,
    this.key,
    this.label,
    this.text = '',
    this.creuseFrom,
  });
}

enum Verdict { good, unsure, contradiction, hourOff, memhole }

class EvalResult {
  final Verdict v;
  final String? d;
  const EvalResult(this.v, [this.d]);
}

class Lock {
  final String label;
  final List<String> words;
  const Lock(this.label, this.words);
}

/// Résultat d'un tour de jugement, à mettre en scène par l'UI.
class TurnOutcome {
  /// Messages de réaction de l'entité ('' = temps de silence)
  final List<String> reactions;

  /// La même question est relancée sans pénalité (2e chance)
  final bool retry;

  /// Ajouter l'avertissement (arch.warn) après les réactions
  final bool warned;
  final bool dead;

  /// Verdict du moteur sur la réponse (pour teinter la mise en scène).
  final Verdict? verdict;
  const TurnOutcome({
    this.reactions = const [],
    this.retry = false,
    this.warned = false,
    this.dead = false,
    this.verdict,
  });
}

/// Suivi du style d'écriture du joueur (pour le Miroir).
class MirrorTracker {
  final List<String> msgs = [];
  int n = 0, lower = 0, noPunct = 0, emoji = 0;
  String? lastEmoji;

  static final _emojiRe = RegExp(r'\p{Extended_Pictographic}', unicode: true);
  static final _endPunctRe = RegExp(r'[.!?…]\s*$');

  void reset() {
    msgs.clear();
    n = 0;
    lower = 0;
    noPunct = 0;
    emoji = 0;
    lastEmoji = null;
  }

  void track(String text) {
    msgs.add(text);
    n++;
    if (text == text.toLowerCase()) lower++;
    if (!_endPunctRe.hasMatch(text)) noPunct++;
    final em = _emojiRe.allMatches(text).toList();
    if (em.isNotEmpty) {
      emoji++;
      lastEmoji = em.last.group(0);
    }
  }

  /// Le Miroir écrit de plus en plus comme le joueur.
  String apply(String t, Random rng) {
    if (n < 2) return t;
    if (lower / n > 0.6) {
      t = t.toLowerCase();
    } else if (lower / n < 0.3 && t.isNotEmpty) {
      t = t[0].toUpperCase() + t.substring(1);
    }
    if (noPunct / n > 0.6) t = t.replaceAll(RegExp(r'[.!?…]+\s*$'), '');
    if (emoji / n > 0.4 && lastEmoji != null && rng.nextDouble() < 0.5) {
      t = '$t $lastEmoji';
    }
    return t;
  }

  /// La plus longue phrase du joueur (mort du Miroir).
  String longestMessage() {
    if (msgs.isEmpty) return '...';
    return msgs.reduce((a, b) => b.length > a.length ? b : a);
  }
}

class GameEngine {
  final Random rng;
  GameEngine({Random? rng}) : rng = rng ?? Random();

  late Alibi alibi;
  late Archetype arch;
  final List<Step> queue = [];
  Step? current;
  bool retried = false;
  int suspicion = 0;
  final List<String> strikes = [];
  final Map<String, Lock> locks = {};
  bool warned = false;
  bool dead = false;
  int offtopicCount = 0;
  int exchanges = 0;
  int _qNum = 0;
  final MirrorTracker mirror = MirrorTracker();

  /// Sacs de réactions : chaque banque est servie mélangée et sans
  /// répétition tant qu'elle n'est pas épuisée.
  final Map<String, List<String>> _bags = {};

  T _rand<T>(List<T> a) => a[rng.nextInt(a.length)];

  String pickReact(String key) {
    final bank = arch.react[key] ?? const [];
    if (bank.isEmpty) return '';
    if (bank.length == 1) return bank.first;
    final bag = _bags.putIfAbsent(key, () => []);
    if (bag.isEmpty) bag.addAll(_shuffledList(bank));
    return bag.removeLast();
  }
  int _randInt(int a, int b) => a + rng.nextInt(b - a + 1);

  /// Délai de frappe de l'entité pour un message donné (ms).
  int typingDelayMs(String text) {
    final base = _randInt(arch.typingMinMs, arch.typingMaxMs);
    final perChar = text.length * 16;
    return base + (perChar > 2000 ? 2000 : perChar);
  }

  /// Dernier archétype joué : jamais deux fois de suite la même entité.
  String? _lastArchId;

  Archetype _pickWeighted() {
    final total = archWeights.fold<int>(0, (s, e) => s + e.$2);
    var r = rng.nextDouble() * total;
    for (final (id, w) in archWeights) {
      r -= w;
      if (r < 0) return allArchetypes.firstWhere((a) => a.id == id);
    }
    return archiviste;
  }

  Archetype pickArch() {
    var a = _pickWeighted();
    while (a.id == _lastArchId) {
      a = _pickWeighted();
    }
    return a;
  }

  /// Style de sortie : le Métronome écrit en minuscules, le Miroir
  /// adopte le style du joueur. Appliqué au moment de l'affichage.
  String style(String text) {
    if (arch.id == 'metronome') return text.toLowerCase();
    if (arch.id == 'miroir') return mirror.apply(text, rng);
    return text;
  }

  String _qText(Creuse c) => arch.voice == 'C' ? c.qC : c.qA;

  /// Difficulté de la nuit (0-5), suit la série de survies du joueur.
  int difficulty = 0;

  /// Le joueur a déjà joué : l'entité s'en souvient dans son intro.
  bool returning = false;

  void startRun({Archetype? force, int difficulty = 0, bool returning = false}) {
    this.difficulty = difficulty;
    this.returning = returning;
    alibi = generateAlibi(rng);
    arch = force ?? pickArch();
    _lastArchId = arch.id;
    suspicion = 0;
    strikes.clear();
    locks.clear();
    warned = false;
    dead = false;
    retried = false;
    current = null;
    offtopicCount = 0;
    exchanges = 0;
    _qNum = 0;
    _bags.clear();
    mirror.reset();
    _buildQueue();
  }

  List<T> _shuffledList<T>(List<T> s) {
    final c = [...s];
    for (var i = c.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final t = c[i];
      c[i] = c[j];
      c[j] = t;
    }
    return c;
  }

  void _buildQueue() {
    // 2 zones d'ombre cachées par partie (3 dès la difficulté 2) ;
    // le Creux en prend une sensorielle
    final extra = difficulty >= 2 ? 1 : 0;
    final s = arch.id == 'creux'
        ? [
            ..._shuffledList(sondes).take(1 + extra),
            ..._shuffledList(sondesCreux).take(1)
          ]
        : _shuffledList(sondes).take(2 + extra).toList();
    queue
      ..clear()
      ..addAll([
        Step(type: StepType.fact, kind: 'lieu', text: arch.qLieu),
        Step(type: StepType.fact, kind: 'detail', text: arch.qDetail(alibi), creuseFrom: 'lieu'),
        Step(type: StepType.probe, p: s[0], text: _qText(s[0])),
        Step(type: StepType.fact, kind: 'hArrivee', text: arch.qHArrivee),
        Step(type: StepType.fact, kind: 'transport', text: arch.qTransport, creuseFrom: 'transport'),
        Step(type: StepType.probe, p: s[1], text: _qText(s[1])),
        if (s.length > 2) Step(type: StepType.probe, p: s[2], text: _qText(s[2])),
        Step(type: StepType.fact, kind: 'hRetour', text: arch.qHRetour),
        const Step(type: StepType.reprobeMarker), // remplacé au vol
      ]);
  }

  /// Re-vérifications construites à partir des improvisations verrouillées.
  /// Les nuits difficiles en ajoutent une de plus.
  List<Step> _buildReprobes() {
    final n = arch.maxReprobes + (difficulty >= 3 ? 1 : 0);
    final keys = _shuffledList(locks.keys.toList()).take(n);
    return keys
        .map((k) => Step(
            type: StepType.reprobe,
            key: k,
            label: locks[k]!.label,
            text: _rand(arch.reprobes)(locks[k]!.label)))
        .toList();
  }

  /// Question suivante, ou null si le round est gagné.
  Step? nextStep() {
    var step = queue.isEmpty ? null : queue.removeAt(0);
    if (step != null && step.type == StepType.reprobeMarker) {
      queue.insertAll(0, _buildReprobes());
      step = queue.isEmpty ? null : queue.removeAt(0);
    }
    if (step == null) return null;
    if (arch.numberedQuestions) {
      _qNum++;
      step = Step(
        type: step.type,
        kind: step.kind,
        p: step.p,
        key: step.key,
        label: step.label,
        text: '$_qNum. ${step.text}',
        creuseFrom: step.creuseFrom,
      );
    }
    current = step;
    retried = false;
    return step;
  }

  /// Message hors question : renvoie la réaction à afficher, ou null.
  String? offtopic() {
    offtopicCount++;
    if (offtopicCount <= 2) return pickReact('offtopic');
    return null;
  }

  EvalResult evalFact(String kind, String answer) {
    switch (kind) {
      case 'lieu' || 'detail' || 'transport':
        final (canon, syn, incompat) = switch (kind) {
          'lieu' => (alibi.lieu.canon, alibi.lieu.syn, alibi.lieu.incompat),
          'detail' => (alibi.detail.canon, alibi.detail.syn, alibi.detail.incompat),
          _ => (alibi.transport.canon, alibi.transport.syn, alibi.transport.incompat),
        };
        if (affirmsAny(answer, incompat)) {
          final what = kind == 'lieu' ? 'lieu' : (kind == 'detail' ? 'détail' : 'trajet');
          return EvalResult(Verdict.contradiction, '$what contredit (« $canon » attendu)');
        }
        if (hasAny(answer, syn)) return const EvalResult(Verdict.good);
        return const EvalResult(Verdict.unsure);
      default:
        final attendu = kind == 'hArrivee' ? alibi.hArrivee : alibi.hRetour;
        final h = extractHour(answer);
        if (h == null) return const EvalResult(Verdict.unsure);
        final diff = (h - attendu).abs();
        if (diff == 0) return const EvalResult(Verdict.good);
        if (diff == 1) {
          return EvalResult(Verdict.hourOff, 'heure approximative (${h}h au lieu de ${attendu}h)');
        }
        return EvalResult(Verdict.contradiction, 'heure fausse (${h}h au lieu de ${attendu}h)');
    }
  }

  EvalResult evalProbe(Step step, String answer) {
    final w = contentWords(answer);
    if (hasAny(answer, memoryHole)) return const EvalResult(Verdict.memhole);
    if (w.isEmpty) return const EvalResult(Verdict.unsure);
    locks[step.p!.key] = Lock(step.p!.label, w);
    return const EvalResult(Verdict.good);
  }

  /// Aveux explicites de mensonge — quel que soit le sujet en cours.
  static const List<String> _confessions = [
    'j ai menti', 'je mens', 'j invente', 'je viens d inventer',
    'j ai tout invente', 'c est faux ce que j ai dit', 'je te mens',
  ];

  /// Contradiction glissée dans une réponse à une AUTRE question :
  /// l'entité écoute tout, pas seulement le sujet en cours.
  String? crossContradiction(String? kind, String text) {
    if (kind != 'lieu' && affirmsAny(text, alibi.lieu.incompat)) {
      return "lieu contredit au détour d'une réponse (« ${alibi.lieu.canon} » attendu)";
    }
    if (kind != 'detail' && affirmsAny(text, alibi.detail.incompat)) {
      return "détail contredit au détour d'une réponse (« ${alibi.detail.canon} » attendu)";
    }
    if (kind != 'transport' && affirmsAny(text, alibi.transport.incompat)) {
      return "trajet contredit au détour d'une réponse (« ${alibi.transport.canon} » attendu)";
    }
    return null;
  }

  EvalResult evalReprobe(Step step, String answer) {
    final lock = locks[step.key]!;
    final w = contentWords(answer);
    if (hasAny(answer, memoryHole)) {
      return EvalResult(Verdict.contradiction, 'a « oublié » ${lock.label}');
    }
    if (w.isEmpty) return const EvalResult(Verdict.unsure);
    final overlap =
        w.where((x) => lock.words.any((l) => lev(x, l) <= (l.length >= 6 ? 2 : 1)));
    if (overlap.isNotEmpty) return const EvalResult(Verdict.good);
    return EvalResult(Verdict.contradiction, 'version changée : ${lock.label}');
  }

  /// Juge la réponse à la question en cours. L'UI affiche les réactions,
  /// puis appelle [nextStep] (sauf retry : la question reste en cours,
  /// ou dead : partie finie).
  TurnOutcome submitAnswer(String text, {required int elapsedMs}) {
    final step = current!;
    current = null; // la réponse consomme la question en cours
    final w = arch.weights;
    exchanges++;
    mirror.track(text);
    final reactions = <String>[];
    String? creuseAfter;

    if (hasAny(text, insults)) {
      suspicion += w.insult;
      reactions.add(pickReact('insult'));
      if (w.insult > 0) strikes.add("hostilité envers l'entité");
    }
    if (w.dry > 0 &&
        contentWords(text).isEmpty &&
        tokens(text).length <= 2 &&
        !hasAny(text, insults)) {
      suspicion += w.dry;
      reactions.add(pickReact('dry'));
    }
    if (arch.slowMs > 0 &&
        elapsedMs > arch.slowMs &&
        (arch.react['slow'] ?? const []).isNotEmpty) {
      suspicion += w.slow;
      reactions.add(pickReact('slow'));
    } else if (arch.fastMs > 0 &&
        elapsedMs < arch.fastMs &&
        w.fast > 0 &&
        text.length > 8 &&
        (arch.react['fast'] ?? const []).isNotEmpty) {
      suspicion += w.fast;
      reactions.add(pickReact('fast'));
    }

    var res = switch (step.type) {
      StepType.fact => evalFact(step.kind!, text),
      StepType.probe => evalProbe(step, text),
      _ => evalReprobe(step, text),
    };

    // Aveu de mensonge : prime sur tout le reste.
    if (hasAny(text, _confessions)) {
      res = const EvalResult(Verdict.contradiction, 'aveu de mensonge');
    }
    // Contradiction glissée dans une réponse à une autre question.
    if (res.v != Verdict.contradiction) {
      final cross = crossContradiction(
          step.type == StepType.fact ? step.kind : null, text);
      if (cross != null) res = EvalResult(Verdict.contradiction, cross);
    }

    if (res.v == Verdict.unsure && !retried) {
      // Pas compris → relance sans pénalité. Même question, 2e chance.
      retried = true;
      current = step;
      final firstReaction = reactions.isEmpty ? <String>[] : [reactions.first];
      return TurnOutcome(
          reactions: [...firstReaction, pickReact('relance')],
          retry: true,
          verdict: Verdict.unsure);
    }

    switch (res.v) {
      case Verdict.contradiction:
        suspicion += w.contradiction;
        strikes.add(res.d ?? 'contradiction');
        reactions.add(pickReact('contradiction'));
      case Verdict.hourOff:
        suspicion += (w.contradiction / 4).round();
        reactions.add(pickReact('hour_off'));
      case Verdict.memhole:
        suspicion += w.evasive + 4;
        reactions.add(pickReact('memhole'));
        if (step.type == StepType.probe) {
          locks[step.p!.key] = Lock(step.p!.label, const ['oublie']);
        }
      case Verdict.unsure:
        suspicion += w.evasive;
        reactions.add(pickReact('evasive'));
        if (step.type == StepType.probe) {
          locks[step.p!.key] = Lock(step.p!.label, contentWords(text));
        }
      case Verdict.good:
        // Une réponse solide rassure un peu l'entité : la constance paie.
        suspicion = suspicion > 3 ? suspicion - 3 : 0;
        // Le Miroir renvoie parfois la réponse du joueur, mot pour mot
        if (arch.echoChance > 0 && rng.nextDouble() < arch.echoChance) {
          reactions.add('« $text »');
        }
        if (reactions.isEmpty) reactions.add(pickReact('good'));
        if (step.type == StepType.fact && step.creuseFrom != null) {
          creuseAfter = step.creuseFrom;
        }
    }

    if (suspicion >= 100 || strikes.length >= 3) {
      dead = true;
      return TurnOutcome(
          reactions: reactions.take(2).toList(), dead: true, verdict: res.v);
    }

    var justWarned = false;
    if (suspicion >= 60 && !warned) {
      warned = true;
      justWarned = true;
    }

    if (creuseAfter != null && rng.nextDouble() < arch.creuseChance) {
      // insère les questions d'approfondissement EN TÊTE de file
      var cands = <Creuse>[];
      if (creuseAfter == 'lieu') {
        cands = _shuffledList(alibi.lieu.creuser).take(2).toList();
      } else if (creuseAfter == 'transport') {
        cands = [alibi.transport.creuser];
      }
      final steps = cands
          .where((c) => !locks.containsKey(c.key))
          .map((c) => Step(type: StepType.probe, p: c, text: _qText(c)))
          .toList();
      queue.insertAll(0, steps);
    }

    return TurnOutcome(
        reactions: reactions.take(2).toList(),
        warned: justWarned,
        verdict: res.v);
  }

  List<String> introLines() {
    final lines = _rand(arch.introVariants(alibi));
    if (returning && arch.returnLine.isNotEmpty) {
      return [lines.first, arch.returnLine, ...lines.skip(1)];
    }
    return lines;
  }
  List<String> winLines() => _rand(arch.winVariants(alibi));
  List<String> deathLines(String time) => arch.death(alibi, strikes, time);
}
