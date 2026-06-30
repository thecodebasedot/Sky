import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import '../../models/user.dart';
import '../../services/call_service.dart';
import '../../services/webrtc_call_service.dart';
import '../../state/auth_store.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar.dart';

/// In-call screen, driven by a [CallService]. Today it runs on
/// [MockCallService] (simulated lifecycle); a flutter_webrtc implementation
/// drops into the same interface next.
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.user,
    required this.isVideo,
    this.callId,
    this.incoming = false,
  });

  final SkyUser user;
  final bool isVideo;

  /// For an incoming call: the existing signaling call id to answer.
  final String? callId;

  /// True when answering a call (callee) rather than placing one (caller).
  final bool incoming;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final CallService _call;

  @override
  void initState() {
    super.initState();
    _call = _createService();
    _call.addListener(_onCallChanged);
    _call.start();
  }

  CallService _createService() {
    if (AppConfig.useFirebase) {
      final myId = context.read<AuthStore>().user?.id ?? 'me';
      if (widget.incoming && widget.callId != null) {
        // Answering: we are the callee; widget.user is the caller.
        return WebRTCCallService(
          callId: widget.callId!,
          callerId: widget.user.id,
          calleeId: myId,
          video: widget.isVideo,
          isCaller: false,
        );
      }
      return WebRTCCallService(
        callId: const Uuid().v4(),
        callerId: myId,
        calleeId: widget.user.id,
        video: widget.isVideo,
        isCaller: true,
      );
    }
    return MockCallService(video: widget.isVideo);
  }

  void _onCallChanged() {
    if (!mounted) return;
    // Dismiss when the call ends; otherwise repaint for the new state.
    if (_call.phase == CallPhase.ended) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _call.removeListener(_onCallChanged);
    _call.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (_call.phase) {
      case CallPhase.dialing:
        return widget.isVideo ? 'Video calling…' : 'Calling…';
      case CallPhase.ringing:
        return 'Ringing…';
      case CallPhase.connecting:
        return 'Connecting…';
      case CallPhase.connected:
        return TimeFormat.duration(_call.elapsed.inSeconds);
      case CallPhase.ended:
        return 'Call ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _call.phase == CallPhase.connected;
    final showVideo = widget.isVideo && _call.videoEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      body: Stack(
        children: [
          if (showVideo)
            Positioned.fill(child: _call.remoteView ?? _videoPlaceholder()),
          if (showVideo && _call.localView != null)
            Positioned(
              top: 48,
              right: 16,
              width: 104,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _call.localView!,
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                if (!showVideo) ...[
                  Avatar(user: widget.user, radius: 56),
                  const SizedBox(height: 20),
                ],
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    color: connected
                        ? const Color(0xFF31D158)
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _controls(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder() {
    // Stand-in for the remote video feed until WebRTC media lands.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B2A3A), Color(0xFF0E1621)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.videocam_rounded,
        size: 64,
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          _call.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          _call.muted ? Colors.white : Colors.white24,
          _call.toggleMute,
          iconColor: _call.muted ? Colors.black : Colors.white,
        ),
        const SizedBox(width: 18),
        if (widget.isVideo) ...[
          _circleButton(
            _call.videoEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            Colors.white24,
            _call.toggleVideo,
          ),
          const SizedBox(width: 18),
        ],
        _circleButton(
          _call.speakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
          _call.speakerOn ? Colors.white : Colors.white24,
          _call.toggleSpeaker,
          iconColor: _call.speakerOn ? Colors.black : Colors.white,
        ),
        const SizedBox(width: 18),
        _circleButton(
          Icons.call_end_rounded,
          Colors.red,
          () => _call.hangUp(),
        ),
      ],
    );
  }

  Widget _circleButton(
    IconData icon,
    Color bg,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) {
    return InkResponse(
      onTap: onTap,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: bg,
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }
}
