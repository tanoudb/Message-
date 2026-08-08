import 'package:flutter_test/flutter_test.dart';
import 'package:messages/main.dart';

void main() {
  testWidgets("l'app démarre sur l'écran verrouillé", (tester) async {
    await tester.pumpWidget(const MessagesApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Appuie pour déverrouiller'), findsOneWidget);
    expect(find.text('Numéro inconnu'), findsOneWidget);
  });

  testWidgets("déverrouiller affiche la note d'alibi", (tester) async {
    await tester.pumpWidget(const MessagesApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Appuie pour déverrouiller'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Ce soir, tu es quelqu'un d'autre."), findsOneWidget);
    expect(find.text("J'ai mémorisé"), findsOneWidget);
  });
}
