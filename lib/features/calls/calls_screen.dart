import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/call.dart';
import '../../state/chat_store.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';
import 'call_screen.dart';

/// The "Calls" tab — recent call history.
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calls = context.watch<ChatStore>().calls;

    return ListView.separated(
      itemCount: calls.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 84,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final call = calls[index];
        return ListTile(
          leading: Avatar(user: call.user),
          title: Text(
            call.user.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: call.isMissed ? Colors.red : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(_directionIcon(call.direction),
                  size: 15, color: _directionColor(call.direction)),
              const SizedBox(width: 4),
              Text(
                TimeFormat.relative(call.timestamp),
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              call.type == CallType.video
                  ? Icons.videocam_rounded
                  : Icons.call_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    user: call.user,
                    isVideo: call.type == CallType.video,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _directionIcon(CallDirection d) {
    switch (d) {
      case CallDirection.incoming:
        return Icons.call_received_rounded;
      case CallDirection.outgoing:
        return Icons.call_made_rounded;
      case CallDirection.missed:
        return Icons.call_missed_rounded;
    }
  }

  Color _directionColor(CallDirection d) {
    return d == CallDirection.missed ? Colors.red : const Color(0xFF31D158);
  }
}
