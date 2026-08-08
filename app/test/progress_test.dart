import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:messages/engine/archetypes.dart';
import 'package:messages/engine/game.dart';
import 'package:messages/meta/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('méta-progression', () {
    test('les nuits, séries et dossier des entités se mettent à jour', () {
      final p = Progress();
      p.recordRun(archId: 'archiviste', won: true);
      p.recordRun(archId: 'creux', won: true);
      expect(p.nights, 2);
      expect(p.streak, 2);
      expect(p.bestStreak, 2);
      expect(p.survived['archiviste'], 1);
      p.recordRun(archId: 'miroir', won: false);
      expect(p.streak, 0); // la mort casse la série
      expect(p.bestStreak, 2); // mais pas le record
      expect(p.seen, containsAll(['archiviste', 'creux', 'miroir']));
      expect(p.survived.containsKey('miroir'), isFalse);
    });

    test('la difficulté suit la série, plafonnée à 5', () {
      final p = Progress(streak: 0);
      expect(p.difficulty, 0);
      p.streak = 3;
      expect(p.difficulty, 3);
      p.streak = 9;
      expect(p.difficulty, 5);
    });

    test('sauvegarde et rechargement', () async {
      SharedPreferences.setMockInitialValues({});
      final p = Progress();
      p.recordRun(archId: 'confidente', won: true);
      await p.save();
      final p2 = await Progress.load();
      expect(p2.nights, 1);
      expect(p2.streak, 1);
      expect(p2.survived['confidente'], 1);
      expect(p2.seen, contains('confidente'));
    });
  });

  group('difficulté dans le moteur', () {
    test('difficulté 2 : une zone d\'ombre de plus (file de 9 étapes)', () {
      final e = GameEngine(rng: Random(51));
      e.startRun(force: archiviste, difficulty: 2);
      expect(e.queue.length, 9);
      expect(e.queue.where((s) => s.type == StepType.probe).length, 3);
    });

    test('difficulté 0 : file classique de 8 étapes', () {
      final e = GameEngine(rng: Random(51));
      e.startRun(force: archiviste);
      expect(e.queue.length, 8);
    });

    test("l'entité se souvient du joueur qui revient", () {
      final e = GameEngine(rng: Random(53));
      e.startRun(force: archiviste, returning: true);
      expect(e.introLines(), contains(archiviste.returnLine));
      final e2 = GameEngine(rng: Random(53));
      e2.startRun(force: archiviste);
      expect(e2.introLines(), isNot(contains(archiviste.returnLine)));
    });
  });
}
