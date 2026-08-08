import 'package:flutter_test/flutter_test.dart';
import 'package:messages/ai/entity_voice.dart';
import 'package:messages/ai/personas.dart';

void main() {
  group('personas', () {
    test('une fiche par archétype, style décrit en français', () {
      for (final id in ['archiviste', 'confidente', 'metronome', 'creux', 'miroir']) {
        expect(personas[id], isNotNull, reason: id);
        expect(personas[id]!.length, greaterThan(100), reason: id);
      }
    });
  });

  group('construction de prompt', () {
    test('le prompt de reformulation contient persona, base, intention et contexte', () {
      final p = buildRewritePrompt(
        archId: 'archiviste',
        base: 'Ce n\'est pas ce que tu as dit. Je note.',
        intent: 'fais-lui comprendre qu\'il se contredit',
        playerText: 'non j\'étais au bar en fait',
        history: const [
          VoiceTurn(false, 'Où étais-tu hier soir ?'),
          VoiceTurn(true, 'au cinéma'),
        ],
      );
      expect(p, contains('ARCHIVISTE'));
      expect(p, contains('Ce n\'est pas ce que tu as dit.'));
      expect(p, contains('il se contredit'));
      expect(p, contains('Joueur : au cinéma'));
      expect(p, contains('Toi : Où étais-tu hier soir ?'));
      expect(p, contains('non j\'étais au bar en fait'));
    });

    test('le prompt de réponse libre interdit de révéler la nature de l\'entité', () {
      final p = buildFreeReplyPrompt(
        archId: 'confidente',
        playerText: 't\'es qui en vrai ??',
        history: const [],
      );
      expect(p, contains('CONFIDENTE'));
      expect(p, contains('Ne révèle jamais qui tu es'));
      expect(p, contains('t\'es qui en vrai ??'));
    });
  });

  group('nettoyage de sortie du modèle', () {
    test('retire préfixes, guillemets et lignes surnuméraires', () {
      expect(cleanLlmOutput('Toi : « je note. »'), 'je note.');
      expect(cleanLlmOutput('"Consigné."\nVoici pourquoi : ...'), 'Consigné.');
      expect(cleanLlmOutput('  \n\n tic. tac. \n'), 'tic. tac.');
    });

    test('coupe les sorties trop longues à une fin de phrase', () {
      final long = '${'blabla ' * 20}fin. ${'encore ' * 30}';
      final out = cleanLlmOutput(long, maxChars: 160);
      expect(out.length, lessThanOrEqualTo(161));
      expect(out, endsWith('.'));
    });

    test('sortie vide → chaîne vide (le fallback prendra le relais)', () {
      expect(cleanLlmOutput('   \n  '), '');
    });
  });

  group('BankVoice (repli sans modèle)', () {
    test('render et freeReply renvoient la réplique de banque telle quelle', () async {
      const v = BankVoice();
      expect(
          await v.render(
              archId: 'creux', base: 'je vois.', intent: 'peu importe'),
          'je vois.');
      expect(
          await v.freeReply(
              archId: 'creux', base: 'pas ça.', playerText: 'hé ho ?'),
          'pas ça.');
    });
  });
}
