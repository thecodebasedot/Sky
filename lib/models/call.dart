import 'user.dart';

enum CallType { voice, video }

enum CallDirection { incoming, outgoing, missed }

/// An entry in the call history.
class CallLog {
  const CallLog({
    required this.id,
    required this.user,
    required this.type,
    required this.direction,
    required this.timestamp,
    this.durationSeconds,
  });

  final String id;
  final SkyUser user;
  final CallType type;
  final CallDirection direction;
  final DateTime timestamp;

  /// Null for missed calls.
  final int? durationSeconds;

  bool get isMissed => direction == CallDirection.missed;
}
