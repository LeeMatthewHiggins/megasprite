import 'package:flutter_test/flutter_test.dart';
import 'package:megasprite_example/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MegaSpriteExampleApp());
    expect(find.text('Megasprite Example'), findsOneWidget);
  });
}
