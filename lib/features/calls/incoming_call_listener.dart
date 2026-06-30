import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/incoming_call_service.dart';
import '../../state/auth_store.dart';
import 'incoming_call_screen.dart';

/// Wraps the app while signed in and presents [IncomingCallScreen] whenever an
/// incoming call arrives. On the mock backend the stream never emits, so this
/// is a transparent pass-through.
class IncomingCallListener extends StatefulWidget {
  const IncomingCallListener({super.key, required this.child});

  final Widget child;

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  StreamSubscription<IncomingCall>? _sub;
  bool _presenting = false;

  @override
  void initState() {
    super.initState();
    final myId = context.read<AuthStore>().user?.id;
    if (myId == null) return;
    _sub = context.read<IncomingCallService>().watch(myId).listen(_onIncoming);
  }

  Future<void> _onIncoming(IncomingCall call) async {
    if (_presenting || !mounted) return;
    _presenting = true;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingCallScreen(call: call),
      ),
    );
    _presenting = false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
