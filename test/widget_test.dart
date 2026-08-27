import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_florestal/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const InventarioFlorestalApp());
  });
}
