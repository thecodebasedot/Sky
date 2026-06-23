import 'dart:async';

import 'package:flutter/widgets.dart';

/// Lifecycle of a call.
enum CallPhase { dialing, ringing, connecting, connected, ended }

/// Drives a single call. The UI ([CallScreen]) listens and renders from this;
/// it never talks to the media/signaling layer directly.
///
/// Implementations: [MockCallService] (simulated lifecycle, no media) and —
/// next — a flutter_webrtc + Firestore-signaling implementation behind the
/// same interface.
abstract class CallService extends ChangeNotifier {
  CallPhase get phase;
  Duration get elapsed;
  bool get isVideo;
  bool get muted;
  bool get videoEnabled;
  bool get speakerOn;

  /// Local/remote video widgets, when the implementation has real media.
  /// Null falls back to a placeholder in the UI.
  Widget? get localView => null;
  Widget? get remoteView => null;

  /// Begin placing/connecting the call.
  Future<void> start();

  void toggleMute();
  void toggleVideo();
  void toggleSpeaker();

  /// End the call and release resources.
  Future<void> hangUp();
}

/// Simulated call with no real media — walks through the phases on timers and
/// ticks a duration once "connected". Lets the in-call UX be built and demoed
/// without WebRTC.
class MockCallService extends CallService {
  MockCallService({required bool video})
      : _isVideo = video,
        _videoEnabled = video;

  final bool _isVideo;

  CallPhase _phase = CallPhase.dialing;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _videoEnabled;
  bool _speakerOn = false;

  final List<Timer> _timers = [];
  Timer? _ticker;
  bool _disposed = false;

  @override
  CallPhase get phase => _phase;
  @override
  Duration get elapsed => _elapsed;
  @override
  bool get isVideo => _isVideo;
  @override
  bool get muted => _muted;
  @override
  bool get videoEnabled => _videoEnabled;
  @override
  bool get speakerOn => _speakerOn;

  @override
  Future<void> start() async {
    _schedulePhase(const Duration(milliseconds: 1200), CallPhase.ringing);
    _schedulePhase(const Duration(milliseconds: 3000), CallPhase.connecting);
    _schedulePhase(
      const Duration(milliseconds: 4200),
      CallPhase.connected,
      startTicker: true,
    );
  }

  void _schedulePhase(
    Duration delay,
    CallPhase next, {
    bool startTicker = false,
  }) {
    _timers.add(Timer(delay, () {
      if (_disposed || _phase == CallPhase.ended) return;
      _phase = next;
      if (startTicker) _startTicker();
      notifyListeners();
    }));
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  @override
  void toggleMute() {
    _muted = !_muted;
    notifyListeners();
  }

  @override
  void toggleVideo() {
    _videoEnabled = !_videoEnabled;
    notifyListeners();
  }

  @override
  void toggleSpeaker() {
    _speakerOn = !_speakerOn;
    notifyListeners();
  }

  @override
  Future<void> hangUp() async {
    _phase = CallPhase.ended;
    _cancelTimers();
    notifyListeners();
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}
