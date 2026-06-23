import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky/app.dart';

void main() {
  testWidgets('Sky boots into the Chats tab', (tester) async {
    await tester.pumpWidget(const SkyApp());
    await tester.pumpAndSettle();

    // App title is shown in the home app bar.
    expect(find.text('Sky'), findsOneWidget);

    // Bottom navigation destinations exist.
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Calls'), findsOneWidget);
  });

  testWidgets('A chat opens and a message can be sent', (tester) async {
    await tester.pumpWidget(const SkyApp());
    await tester.pumpAndSettle();

    // Open the first conversation.
    await tester.tap(find.text('Amara Okafor').first);
    await tester.pumpAndSettle();

    // Type and send.
    await tester.enterText(find.byType(TextField), 'Hello from a test');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Hello from a test'), findsOneWidget);
  });
}
