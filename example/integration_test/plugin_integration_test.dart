import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jl_signals_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example shows privacy consent entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('同意隐私政策并初始化'), findsOneWidget);
    expect(find.text('获取 ClickId'), findsOneWidget);
    expect(find.text('获取设备标识'), findsOneWidget);

    await tester.tap(find.text('同意隐私政策并初始化'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('已初始化并上报启动事件'), findsOneWidget);
  });
}
