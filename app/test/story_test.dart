import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:messages/engine/alibi.dart';
import 'package:messages/engine/archetypes.dart';
import 'package:messages/engine/game.dart';
import 'package:messages/meta/progress.dart';
import 'package:messages/meta/story.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('récit', () {
    test('12 fragments, tous non vides et titrés', () {
      expect(storyLength, 12);
      for (final f in storyFragments) {
        expect(f.titre, isNotEmpty);
        expect(f.lignes, isNotEmpty);
        for (final l in f.lignes) {
          expect(l.trim(), isNotEmpty);
        }
      }
    });

    test('un fragment par nuit, puis plus rien', () {
      expect(fragmentFor(0), storyFragments.first);
      expect(fragmentFor(11), storyFragments.last);
      expect(fragmentFor(12), isNull);
      expect(fragmentFor(-1), isNull);
    });

    test('le compteur de fragments progresse et se sauvegarde', () async {
      SharedPreferences.setMockInitialValues({});
      final p = Progress();
      expect(fragmentFor(p.fragments), storyFragments[0]);
      p.fragments++;
      await p.save();
      final p2 = await Progress.load();
      expect(p2.fragments, 1);
      expect(fragmentFor(p2.fragments), storyFragments[1]);
    });
  });

  group('mémoire entre les nuits', () {
    test('une invention de la nuit passée est ressortie', () {
      final e = GameEngine(rng: Random(61));
      e.startRun(
          force: archiviste,
          pastLies: {'le nom de ton ami': 'kevin appart colocataire'});
      final past = e.queue.where((s) => s.type == StepType.pastLie).toList();
      expect(past.length, 1);
      expect(past.single.text, contains('le nom de ton ami'));
    });

    test('rester cohérent passe, changer de version est une contradiction', () {
      final e = GameEngine(rng: Random(63));
      e.startRun(force: archiviste, pastLies: {'le nom de ton ami': 'kevin'});
      const step = Step(type: StepType.pastLie, key: 'le nom de ton ami', text: 'q');
      expect(e.evalPastLie(step, "c'était Kevin").v, Verdict.good);
      expect(e.evalPastLie(step, "c'était Mathieu").v, Verdict.contradiction);
      expect(e.evalPastLie(step, 'je sais plus').v, Verdict.contradiction);
    });

    test('sans nuit précédente, aucune question de mémoire', () {
      final e = GameEngine(rng: Random(65));
      e.startRun(force: archiviste);
      expect(e.queue.where((s) => s.type == StepType.pastLie), isEmpty);
    });

    test('les improvisations de la nuit sont conservées pour la suivante', () {
      final e = GameEngine(rng: Random(67));
      e.startRun(force: archiviste);
      final step = e.nextStep()!;
      e.submitAnswer("j'étais ${e.alibi.lieu.syn[0]}", elapsedMs: 5000);
      // force une improvisation verrouillée
      const sonde = Step(
          type: StepType.probe,
          p: Creuse('compagnie', 'qui était avec toi', 'q', 'q'),
          text: 'q');
      e.evalProbe(sonde, 'avec ma cousine Sofia');
      final lies = e.liesToRemember();
      expect(lies['qui était avec toi'], contains('sofia'));
      expect(step.text, isNotEmpty);
    });
  });
}
