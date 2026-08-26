import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuangan/app/app.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: KuanganApp()));

    // Verify that our app starts.
    // Since we redirected to login, we should see 'Kuangan'
    expect(find.text('Kuangan'), findsOneWidget);
  });
}
