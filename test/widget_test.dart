import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TutorOS App initialization smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TutorOSApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TutorOSApp), findsOneWidget);
  });
}


