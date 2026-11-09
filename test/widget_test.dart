import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_ekzamen/main.dart';

void main() {
  testWidgets('Приложение открывается на стартовом экране', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ExamClientApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ExamHomeScreen), findsOneWidget);

    // Стартовый экран ждёт ответ сервера с таймаутом 3 с, даём таймеру завершиться.
    await tester.pump(const Duration(seconds: 4));
  });

  test('AntiPasteFormatter пропускает ввод до 2 символов за такт', () {
    final formatter = AntiPasteFormatter();
    const oldValue = TextEditingValue(text: 'abc');

    final typed = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(text: 'abcd'),
    );
    expect(typed.text, 'abcd');

    final pasted = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(text: 'abcdefgh'),
    );
    expect(pasted.text, 'abc');
  });
}
