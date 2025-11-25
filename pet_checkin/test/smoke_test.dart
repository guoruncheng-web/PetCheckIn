import 'package:flutter_test/flutter_test.dart';
import 'package:pet_checkin/main.dart';

void main() {
  testWidgets('启动页冒烟测试', (WidgetTester tester) async {
    await tester.pumpWidget(const PetCheckinApp());
    expect(find.text('宠物打卡'), findsOneWidget);
  });
}