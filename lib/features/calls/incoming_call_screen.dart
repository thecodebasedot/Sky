import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/incoming_call_service.dart';
import '../../widgets/avatar.dart';
import 'call_screen.dart';

/// Full-screen ringing UI for an incoming call, with accept / decline.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key, required this.call});

  final IncomingCall call;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Avatar(user: call.caller, radius: 56),
            const SizedBox(height: 20),
            Text(
              call.caller.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              call.isVideo ? 'Incoming video call…' : 'Incoming voice call…',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const Spacer(flex: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(
                  context,
                  icon: Icons.call_end_rounded,
                  color: Colors.red,
                  label: 'Decline',
                  onTap: () => _decline(context),
                ),
                _action(
                  context,
                  icon: Icons.call_rounded,
                  color: const Color(0xFF31D158),
                  label: 'Accept',
                  onTap: () => _accept(context),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _decline(BuildContext context) {
    context.read<IncomingCallService>().decline(call.callId);
    Navigator.of(context).maybePop();
  }

  void _accept(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          user: call.caller,
          isVideo: call.isVideo,
          callId: call.callId,
          incoming: true,
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkResponse(
          onTap: onTap,
          child: CircleAvatar(
            radius: 34,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
