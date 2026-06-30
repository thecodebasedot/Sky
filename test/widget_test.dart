import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sky/app.dart';
import 'package:sky/features/calls/incoming_call_screen.dart';
import 'package:sky/models/user.dart';
import 'package:sky/services/incoming_call_service.dart';
import 'package:sky/services/notification_service.dart';

/// Drives the sign-in flow: welcome → phone → OTP → profile setup → home.
Future<void> _signIn(WidgetTester tester) async {
  await tester.pumpWidget(const SkyApp());
  await tester.pumpAndSettle();

  // Welcome screen.
  await tester.tap(find.text('Agree & continue'));
  await tester.pumpAndSettle();

  // Phone entry. Pump so the field's listener enables the Continue button
  // before we tap it.
  await tester.enterText(find.byKey(const Key('phone_field')), '555 0100');
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();

  // OTP entry (mock accepts any 6 digits).
  await tester.enterText(find.byKey(const Key('otp_field')), '123456');
  await tester.pumpAndSettle();

  // Profile setup.
  await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

/// Advance past the mock backend's simulated delays (delivery acks + the
/// other participant's typing/auto-reply), then settle. Without this, those
/// pending timers trip the "Timer still pending after dispose" check.
Future<void> _settleMock(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
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
    await _settleMock(tester);

    expect(find.text('Hello from a test'), findsOneWidget);
  });

  testWidgets('Sending a message triggers an auto-reply', (tester) async {
    await _signIn(tester);

    await tester.tap(find.text('Amara Okafor').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hi Amara');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _settleMock(tester);

    // The mock "other participant" types, then replies.
    expect(find.text('Got it 👍'), findsOneWidget);
  });

  testWidgets('Attachment menu can send a document', (tester) async {
    await _signIn(tester);

    await tester.tap(find.text('Amara Okafor').first);
    await tester.pumpAndSettle();

    // Open the attachment sheet and pick Document.
    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Gallery'), findsOneWidget);

    await tester.tap(find.text('Document'));
    await _settleMock(tester);

    expect(find.text('Document.pdf'), findsOneWidget);
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

  testWidgets('Incoming call screen shows the caller with accept/decline',
      (tester) async {
    const caller = SkyUser(id: 'u_caller', name: 'Ada Lovelace');
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<IncomingCallService>(
          create: (_) => MockIncomingCallService(),
          child: const IncomingCallScreen(
            call: IncomingCall(
              callId: 'call_1',
              caller: caller,
              isVideo: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Incoming video call…'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('Posting a text status updates My status', (tester) async {
    await _signIn(tester);

    // Switch to the Status tab.
    await tester.tap(find.text('Status'));
    await tester.pumpAndSettle();
    expect(find.text('Tap to add status update'), findsOneWidget);

    // Open the composer, type, and post.
    await tester.tap(find.text('My status'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hello status');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    // Back on the Status tab, my status now has an update.
    expect(find.text('My status'), findsOneWidget);
    expect(find.text('Tap to add status update'), findsNothing);
  });

  test('MockNotificationService init/clear are safe no-ops', () async {
    final notifications = MockNotificationService();
    await notifications.init('u_test');
    await notifications.clear('u_test');
  });
}
