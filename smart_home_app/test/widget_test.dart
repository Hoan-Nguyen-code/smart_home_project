
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home_app/main.dart';

void main() {
  testWidgets('Smart Home app starts with login screen', (tester) async {
    await tester.pumpWidget(const SmartHomeApp());

    expect(find.text('Đăng nhập Smart Home'), findsOneWidget);
  });
}
