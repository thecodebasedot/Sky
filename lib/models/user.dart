/// A person on Sky.
class SkyUser {
  const SkyUser({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.avatarUrl,
    this.about = 'Hey there! I am using Sky.',
    this.isOnline = false,
    this.lastSeen,
  });

  final String id;
  final String name;
  final String? phoneNumber;

  /// Remote avatar URL. When null the UI falls back to initials.
  final String? avatarUrl;

  final String about;
  final bool isOnline;
  final DateTime? lastSeen;

  /// Up to two initials used by the avatar placeholder.
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
