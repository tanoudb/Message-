import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:messages/engine/alibi.dart';
import 'package:messages/engine/archetypes.dart';
import 'package:messages/engine/game.dart';
import 'package:messages/engine/text_utils.dart';

void main() {
  group('utilitaires texte', () {
    test('normalisation : accents, ponctuation, casse', () {
      expect(norm('Éтé—Ça VA ?!'), isNot(contains('É')));
      expect(norm('Cinéma !'), 'cinema');
      expect(norm("j'étais   au   BAR"), 'j etais au bar');
    });

    test('Levenshtein et fuzzy', () {
      expect(lev('cinema', 'cinema'), 0);
      expect(lev('cinema', 'cinemma'), 1);
      expect(findFuzzy(tokens('au cinemma hier'), 'cinema'), 1);
      expect(findFuzzy(tokens('au bar hier'), 'cinema'), -1);
    });

    test('négation : "pas au bar" ne compte pas comme affirmation', () {
      expect(affirms("j'étais au bar", 'bar'), isTrue);
      expect(affirms("j'étais pas au bar", 'bar'), isFalse);
      expect(affirms('jamais allé au bar', 'bar'), isFalse);
    });

    test('extraction d\'heure', () {
      expect(extractHour('vers 19h'), 19);
      expect(extractHour('à 19 heures'), 19);
      expect(extractHour('vers minuit'), 0);
      expect(extractHour('aucune idée'), null);
    });

    test('mots pleins : stopwords filtrés', () {
      expect(contentWords('je crois que c était bien'), isEmpty);
      expect(contentWords('avec ma copine Marie'), contains('marie'));
    });
  });

  group('génération et file de questions', () {
    for (final arch in allArchetypes) {
      test('${arch.id} : file de 8 étapes, textes valides', () {
        final e = GameEngine(rng: Random(42));
        e.startRun(force: arch);
        expect(e.queue.length, 8);
        for (final s in e.queue.take(7)) {
          expect(s.text, isNotEmpty);
        }
        expect(e.queue.last.type, StepType.reprobeMarker);
        expect(e.introLines(), isNotEmpty);
        expect(e.winLines(), isNotEmpty);
        for (final variant in arch.introVariants(e.alibi)) {
          expect(variant, isNotEmpty);
        }
        for (final variant in arch.winVariants(e.alibi)) {
          expect(variant, isNotEmpty);
        }
        for (final tpl in arch.reprobes) {
          expect(tpl('le nom du bar').toLowerCase(), contains('le nom du bar'));
        }
        // death peut être vide (le Creux ne parle pas avant sa mise en scène)
        arch.death(e.alibi, const ['x'], '23:00');
      });
    }

    test("l'Archiviste numérote ses questions, les autres non", () {
      final e = GameEngine(rng: Random(21));
      e.startRun(force: archiviste);
      expect(e.nextStep()!.text, startsWith('1. '));
      expect(e.nextStep()!.text, startsWith('2. '));
      final e2 = GameEngine(rng: Random(21));
      e2.startRun(force: confidente);
      expect(e2.nextStep()!.text, isNot(startsWith('1. ')));
    });

    test('les réactions ne se répètent pas avant épuisement de la banque', () {
      final e = GameEngine(rng: Random(17));
      e.startRun(force: archiviste);
      final bank = archiviste.react['good']!;
      final drawn = List.generate(bank.length, (_) => e.pickReact('good'));
      expect(drawn.toSet().length, bank.length);
      expect(drawn.toSet(), bank.toSet());
    });

    test('le Creux reçoit une sonde sensorielle', () {
      final e = GameEngine(rng: Random(7));
      e.startRun(force: creux);
      final probeKeys = e.queue
          .where((s) => s.type == StepType.probe)
          .map((s) => s.p!.key)
          .toList();
      final sensoryKeys = sondesCreux.map((c) => c.key).toSet();
      expect(probeKeys.any(sensoryKeys.contains), isTrue);
    });

    test('jamais deux fois de suite le même archétype', () {
      final e = GameEngine(rng: Random(33));
      String? last;
      for (var i = 0; i < 100; i++) {
        e.startRun();
        expect(e.arch.id, isNot(last), reason: 'partie $i');
        last = e.arch.id;
      }
    });

    test('tirage pondéré : les 5 sortent, le Miroir est rare', () {
      final e = GameEngine(rng: Random(1));
      final counts = <String, int>{};
      for (var i = 0; i < 5000; i++) {
        final a = e.pickArch();
        counts[a.id] = (counts[a.id] ?? 0) + 1;
      }
      expect(counts.keys.length, 5);
      expect(counts['miroir']!, lessThan(counts['archiviste']!));
      expect(counts['miroir']! / 5000, lessThan(0.16));
    });
  });

  group('évaluation factuelle sur toutes les banques', () {
    test('lieux, détails, transports : synonyme = good, incompatible = contradiction',
        () {
      final e = GameEngine(rng: Random(3));
      e.startRun(force: archiviste);
      for (final lieu in lieux) {
        for (final det in lieu.details) {
          e.alibi = Alibi(
              prenom: 'Test',
              metier: 'test',
              lieu: lieu,
              detail: det,
              transport: transports[0],
              hArrivee: 19,
              hRetour: 22);
          expect(e.evalFact('lieu', "j'étais ${lieu.syn[0]}").v, Verdict.good,
              reason: 'lieu good: ${lieu.canon}');
          expect(e.evalFact('lieu', lieu.incompat[0]).v, Verdict.contradiction,
              reason: 'lieu contra: ${lieu.canon}');
          expect(e.evalFact('detail', det.syn[0]).v, Verdict.good,
              reason: 'détail good: ${det.canon}');
          expect(e.evalFact('detail', det.incompat[0]).v, Verdict.contradiction,
              reason: 'détail contra: ${det.canon}');
        }
      }
      for (final tr in transports) {
        e.alibi = Alibi(
            prenom: 'Test',
            metier: 'test',
            lieu: lieux[0],
            detail: lieux[0].details[0],
            transport: tr,
            hArrivee: 19,
            hRetour: 22);
        expect(e.evalFact('transport', tr.syn[0]).v, Verdict.good,
            reason: 'transport good: ${tr.canon}');
        expect(e.evalFact('transport', tr.incompat[0]).v, Verdict.contradiction,
            reason: 'transport contra: ${tr.canon}');
      }
    });

    test('négation gérée, heures exactes/approx/fausses', () {
      final e = GameEngine(rng: Random(3));
      e.startRun(force: archiviste);
      e.alibi = Alibi(
          prenom: 'Test',
          metier: 'test',
          lieu: lieux[0], // cinéma
          detail: lieux[0].details[0],
          transport: transports[0],
          hArrivee: 19,
          hRetour: 22);
      expect(e.evalFact('lieu', "j'étais pas au bar, j'étais au ciné").v, Verdict.good);
      expect(e.evalFact('hArrivee', 'vers 19h').v, Verdict.good);
      expect(e.evalFact('hArrivee', 'vers 20h').v, Verdict.hourOff);
      expect(e.evalFact('hArrivee', 'à 22h').v, Verdict.contradiction);
    });
  });

  group('improvisations verrouillées', () {
    test('probe verrouille, reprobe cohérente/contradictoire', () {
      final e = GameEngine(rng: Random(5));
      e.startRun(force: archiviste);
      const sonde = Creuse('compagnie', 'qui était avec toi', 'Q ?', 'q ?');
      const probe = Step(type: StepType.probe, p: sonde, text: 'Q ?');
      expect(e.evalProbe(probe, 'avec ma copine Marie').v, Verdict.good);
      expect(e.locks, contains('compagnie'));
      const reprobe = Step(type: StepType.reprobe, key: 'compagnie', text: 'R ?');
      expect(e.evalReprobe(reprobe, 'avec Marie ma copine').v, Verdict.good);
      expect(e.evalReprobe(reprobe, 'avec mon frère Paul').v, Verdict.contradiction);
      expect(e.evalReprobe(reprobe, 'je sais plus').v, Verdict.contradiction);
    });
  });

  group('miroir de style', () {
    test('adopte minuscules et absence de ponctuation', () {
      final m = MirrorTracker();
      for (final t in ['salut ca va', 'je rentre chez moi la', 'ouais tranquille']) {
        m.track(t);
      }
      expect(m.apply('Je Te Vois.', Random(1)), 'je te vois');
    });

    test('plus longue phrase pour la mort', () {
      final m = MirrorTracker();
      m.track('oui');
      m.track('je suis rentré vers 22h en métro');
      m.track('non');
      expect(m.longestMessage(), 'je suis rentré vers 22h en métro');
    });
  });

  group('parties complètes simulées', () {
    /// Répond correctement à une étape à partir de l'alibi.
    String goodAnswer(GameEngine e, Step s) {
      if (s.type == StepType.probe) return 'réponse improvisée topaze durable';
      if (s.type == StepType.reprobe) return 'réponse improvisée topaze durable';
      return switch (s.kind!) {
        'lieu' => "j'étais ${e.alibi.lieu.syn[0]}",
        'detail' => 'c était ${e.alibi.detail.syn[0]}',
        'transport' => 'en ${e.alibi.transport.syn[0]}',
        'hArrivee' => 'vers ${e.alibi.hArrivee}h',
        _ => 'vers ${e.alibi.hRetour}h',
      };
    }

    test('bien répondre → victoire (tous archétypes)', () {
      for (final arch in allArchetypes) {
        for (var seed = 0; seed < 20; seed++) {
          final e = GameEngine(rng: Random(seed));
          e.startRun(force: arch);
          var guard = 0;
          Step? s;
          while ((s = e.nextStep()) != null) {
            expect(++guard, lessThan(40), reason: 'boucle infinie (${arch.id})');
            var out = e.submitAnswer(goodAnswer(e, s!),
                elapsedMs: 5000); // ni lent ni rapide
            if (out.retry) {
              out = e.submitAnswer(goodAnswer(e, e.current!), elapsedMs: 5000);
            }
            expect(out.dead, isFalse,
                reason: '${arch.id} seed=$seed mort avec de bonnes réponses '
                    '(suspicion=${e.suspicion}, strikes=${e.strikes})');
          }
          expect(e.dead, isFalse);
        }
      }
    });

    test('se contredire → mort', () {
      final e = GameEngine(rng: Random(9));
      e.startRun(force: archiviste);
      var deaths = false;
      Step? s;
      var guard = 0;
      while ((s = e.nextStep()) != null && guard++ < 40) {
        // toujours affirmer un incompatible ou une heure fausse
        final bad = switch (s!.type) {
          StepType.fact => switch (s.kind!) {
              'lieu' => e.alibi.lieu.incompat[0],
              'detail' => e.alibi.detail.incompat[0],
              'transport' => e.alibi.transport.incompat[0],
              _ => 'vers 3h du matin',
            },
          _ => 'improvisation quelconque radis',
        };
        final out = e.submitAnswer(bad, elapsedMs: 5000);
        if (out.retry) continue;
        if (out.dead) {
          deaths = true;
          break;
        }
      }
      expect(deaths, isTrue);
      expect(e.strikes.length, greaterThanOrEqualTo(3));
    });

    test('relance sans pénalité sur réponse incomprise', () {
      final e = GameEngine(rng: Random(11));
      e.startRun(force: archiviste);
      e.nextStep(); // question lieu
      final before = e.suspicion;
      final out = e.submitAnswer('hmm', elapsedMs: 5000);
      expect(out.retry, isTrue);
      expect(e.suspicion, before);
      expect(e.current, isNotNull); // même question toujours en cours
    });

    test('style : le Métronome écrit en minuscules', () {
      final e = GameEngine(rng: Random(13));
      e.startRun(force: metronome);
      expect(e.style('RÉPONDS Maintenant.'), 'réponds maintenant.');
    });
  });
}
