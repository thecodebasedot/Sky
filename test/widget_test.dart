import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky/app.dart';

/// Drives the sign-in flow: welcome → phone → OTP → profile setup → home.
Future<void> _signIn(WidgetTester tester) async {
  await tester.pumpWidget(const SkyApp());
  await tester.pumpAndSettle();

  // Welcome screen.
  await tester.tap(find.text('Agree & continue'));
  await tester.pumpAndSettle();

  // Phone entry.
  await tester.enterText(find.byType(TextField).last, '555 0100');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // OTP entry (mock accepts any 6 digits).
  await tester.enterText(find.byType(TextField).first, '123456');
  await tester.pumpAndSettle();

  // Profile setup.
  await tester.enterText(find.byType(TextField).first, 'Test User');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Signed-out users see the welcome screen', (tester) async {
    await tester.pumpWidget(const SkyApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Sky'), findsOneWidget);
    expect(find.text('Agree & continue'), findsOneWidget);
  });

  testWidgets('Full sign-in lands on the Chats home', (tester) async {
    await _signIn(tester);

    expect(find.text('Sky'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Calls'), findsOneWidget);
  });

  testWidgets('A chat opens and a message can be sent', (tester) async {
    await _signIn(tester);

    await tester.tap(find.text('Amara Okafor').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello from a test');
    await tester.pump(); // let the composer swap mic → send
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Hello from a test'), findsOneWidget);
  });

  testWidgets('New-chat picker creates and opens a conversation',
      (tester) async {
    await _signIn(tester);

    // Open the contact picker from the Chats FAB.
    await tester.tap(find.byIcon(Icons.add_comment_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Select contact'), findsOneWidget);

    // Noah has no existing direct chat — this exercises chat creation.
    await tester.tap(find.text('Noah Kim'));
    await tester.pumpAndSettle();

    // We land in the conversation with Noah.
    expect(find.text('Noah Kim'), findsWidgets);
    expect(find.text('Select contact'), findsNothing);
  });
}
