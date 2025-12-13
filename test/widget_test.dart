import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_app/main.dart';

void main() {
  testWidgets('Tetris app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TetrisApp());

    expect(find.text('TETRIS'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
  });
}
