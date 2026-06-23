import 'package:flutter_test/flutter_test.dart';
import 'package:estuaire_achats/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const EstuaireAchatsApp());
    expect(find.text('EstuaireAchats'), findsOneWidget);
  });
}
