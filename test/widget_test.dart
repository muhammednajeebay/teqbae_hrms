import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teqbae_hrms/app.dart';

void main() {
  testWidgets('shows the application bootstrap state', (WidgetTester tester) async {
    await tester.pumpWidget(const RebsHrmsApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
