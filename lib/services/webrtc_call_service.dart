import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'call_service.dart';

/// Real voice/video via flutter_webrtc, with offer/answer/ICE exchanged over
/// Cloud Firestore.
///
/// Signaling layout:
/// ```
/// calls/{callId}
///   callerId, calleeId, isVideo, status
///   offer:  {sdp, type}
///   answer: {sdp, type}
///   calls/{callId}/callerCandidates/{auto}  // ICE from the caller
///   calls/{callId}/calleeCandidates/{auto}  // ICE from the callee
/// ```
///
/// NOTE: this is the device-bound media plane. It compiles and is wired behind
/// [CallService], but real audio/video + NAT traversal must be verified on
/// physical devices, and production use also needs TURN servers and the
/// incoming-call listener UI (see docs/FIREBASE_SETUP.md).
class WebRTCCallService extends CallService {
  WebRTCCallService({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required bool video,
    required this.isCaller,
    FirebaseFirestore? firestore,
  })  : _isVideo = video,
        _videoEnabled = video,
        _db = firestore ?? FirebaseFirestore.instance;

  final String callId;
  final String callerId;
  final String calleeId;
  final bool isCaller;
  final FirebaseFirestore _db;
  final bool _isVideo;

  static const Map<String, dynamic> _config = {
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302'],
      },
    ],
  };

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _localStream;

  final List<StreamSubscription<dynamic>> _subs = [];

  CallPhase _phase = CallPhase.dialing;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _muted = false;
  bool _videoEnabled;
  bool _speakerOn = false;
  bool _disposed = false;

  DocumentReference<Map<String, dynamic>> get _callDoc =>
      _db.collection('calls').doc(callId);

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
  Widget? get localView =>
      _isVideo ? RTCVideoView(_localRenderer, mirror: true) : null;
  @override
  Widget? get remoteView => _isVideo ? RTCVideoView(_remoteRenderer) : null;

  @override
  Future<void> start() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': _isVideo,
    });
    _localRenderer.srcObject = _localStream;

    final pc = await createPeerConnection(_config);
    _pc = pc;

    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        _notify();
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _setPhase(CallPhase.connecting);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _setPhase(CallPhase.connected, startTicker: true);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _setPhase(CallPhase.ended);
          break;
        default:
          break;
      }
    };

    if (isCaller) {
      await _runCaller(pc);
    } else {
      await _runCallee(pc);
    }
  }

  Future<void> _runCaller(RTCPeerConnection pc) async {
    final myCandidates = _callDoc.collection('callerCandidates');
    pc.onIceCandidate = (c) => myCandidates.add(c.toMap());

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    await _callDoc.set({
      'callerId': callerId,
      'calleeId': calleeId,
      'isVideo': _isVideo,
      'status': 'ringing',
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'createdAt': FieldValue.serverTimestamp(),
    });
    _setPhase(CallPhase.ringing);

    // Apply the answer once the callee posts it.
    _subs.add(_callDoc.snapshots().listen((snap) async {
      final data = snap.data();
      final answer = data?['answer'] as Map?;
      if (answer != null && (await pc.getRemoteDescription()) == null) {
        await pc.setRemoteDescription(
          RTCSessionDescription(answer['sdp'] as String?, answer['type'] as String?),
        );
      }
    }));

    _listenRemoteCandidates(pc, _callDoc.collection('calleeCandidates'));
  }

  Future<void> _runCallee(RTCPeerConnection pc) async {
    final myCandidates = _callDoc.collection('calleeCandidates');
    pc.onIceCandidate = (c) => myCandidates.add(c.toMap());

    final snap = await _callDoc.get();
    final offer = snap.data()?['offer'] as Map?;
    if (offer != null) {
      await pc.setRemoteDescription(
        RTCSessionDescription(offer['sdp'] as String?, offer['type'] as String?),
      );
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      await _callDoc.set({
        'answer': {'sdp': answer.sdp, 'type': answer.type},
        'status': 'connected',
      }, SetOptions(merge: true));
    }

    _listenRemoteCandidates(pc, _callDoc.collection('callerCandidates'));
  }

  void _listenRemoteCandidates(
    RTCPeerConnection pc,
    CollectionReference<Map<String, dynamic>> col,
  ) {
    _subs.add(col.snapshots().listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final c = change.doc.data();
          if (c == null) continue;
          pc.addCandidate(RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            (c['sdpMLineIndex'] as num?)?.toInt(),
          ));
        }
      }
    }));
  }

  @override
  void toggleMute() {
    _muted = !_muted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_muted);
    _notify();
  }

  @override
  void toggleVideo() {
    _videoEnabled = !_videoEnabled;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = _videoEnabled);
    _notify();
  }

  @override
  void toggleSpeaker() {
    _speakerOn = !_speakerOn;
    Helper.setSpeakerphoneOn(_speakerOn);
    _notify();
  }

  @override
  Future<void> hangUp() async {
    _setPhase(CallPhase.ended);
    await _cleanup();
  }

  void _setPhase(CallPhase next, {bool startTicker = false}) {
    if (_disposed || _phase == CallPhase.ended) return;
    _phase = next;
    if (startTicker && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsed += const Duration(seconds: 1);
        _notify();
      });
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _cleanup() async {
    _ticker?.cancel();
    _ticker = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _localStream?.dispose();
    await _pc?.close();
    _pc = null;
    await _callDoc.set({'status': 'ended'}, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _pc?.close();
    super.dispose();
  }
}
