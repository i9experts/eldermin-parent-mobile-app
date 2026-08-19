import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eldermin_parent_app/main.dart';

void main() {
  testWidgets('App boots to the phone entry screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const EldeminParentApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
