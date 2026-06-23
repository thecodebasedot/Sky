import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../widgets/avatar.dart';

/// In-call screen. UI scaffold only — real audio/video (WebRTC) wires in later.
class CallScreen extends StatelessWidget {
  const CallScreen({super.key, required this.user, required this.isVideo});

  final SkyUser user;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Avatar(user: user, radius: 56),
            const SizedBox(height: 20),
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVideo ? 'Video calling…' : 'Calling…',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const Spacer(),
            _controls(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(Icons.mic_off_rounded, Colors.white24, () {}),
        const SizedBox(width: 20),
        if (isVideo)
          _circleButton(Icons.videocam_off_rounded, Colors.white24, () {}),
        if (isVideo) const SizedBox(width: 20),
        _circleButton(Icons.volume_up_rounded, Colors.white24, () {}),
        const SizedBox(width: 20),
        _circleButton(
          Icons.call_end_rounded,
          Colors.red,
          () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, Color bg, VoidCallback onTap) {
    return InkResponse(
      onTap: onTap,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: bg,
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
