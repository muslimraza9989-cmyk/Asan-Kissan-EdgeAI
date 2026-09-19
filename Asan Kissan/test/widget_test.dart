import 'package:flutter_test/flutter_test.dart';
import 'package:asan_kissan/main.dart';

void main() {
  testWidgets('Asan Kissan App Smoke Test', (WidgetTester tester) async {
    // Build app widget
    await tester.pumpWidget(const AsanKissanApp());
    await tester.pump();

    // Verify key titles and action buttons render cleanly
    expect(find.text('Asan Kissan AI'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('From Gallery'), findsOneWidget);
    expect(find.text('Single Leaf'), findsOneWidget);
    expect(find.text('Canopy (Multi-Leaf)'), findsOneWidget);
  });
}

