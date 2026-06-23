import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/user.dart';

/// Circular avatar that shows a network image when available, otherwise
/// the user's initials on a stable per-user color. Optional online dot.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.showOnlineDot = false,
  });

  final SkyUser user;
  final double radius;
  final bool showOnlineDot;

  @override
  Widget build(BuildContext context) {
    final color = MockData.colorFor(user.id);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      foregroundImage:
          user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
      child: Text(
        user.initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.7,
        ),
      ),
    );

    if (!showOnlineDot || !user.isOnline) return avatar;

    final dot = radius * 0.5;
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: const Color(0xFF31D158),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
