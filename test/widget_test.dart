import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helixtrace/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HelixTraceApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
