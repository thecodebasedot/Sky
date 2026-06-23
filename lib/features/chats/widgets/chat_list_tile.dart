import 'package:flutter/material.dart';

import '../../../models/chat.dart';
import '../../../models/message.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/time_format.dart';
import '../../../widgets/avatar.dart';

/// One row in the chat list.
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.myId,
    required this.onTap,
  });

  final Chat chat;
  final String myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = chat.lastMessage;
    final other = chat.isGroup ? null : chat.otherParticipant(myId);

    return ListTile(
      onTap: onTap,
      leading: other != null
          ? Avatar(user: other, showOnlineDot: true)
          : CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.15),
              child: const Icon(Icons.groups_rounded, color: AppTheme.skyBlue),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.titleFor(myId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (last != null)
            Text(
              TimeFormat.relative(last.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: chat.unreadCount > 0
                    ? AppTheme.skyBlue
                    : theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Expanded(child: _preview(context, last)),
            const SizedBox(width: 8),
            _trailing(context),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, Message? last) {
    final theme = Theme.of(context);
    if (last == null) {
      return Text('Tap to start chatting',
          style: TextStyle(color: theme.colorScheme.outline));
    }

    IconData? icon;
    String text = last.text;
    switch (last.type) {
      case MessageType.image:
        icon = Icons.photo_rounded;
        text = last.text.isEmpty ? 'Photo' : last.text;
        break;
      case MessageType.voice:
        icon = Icons.mic_rounded;
        text = 'Voice message';
        break;
      case MessageType.file:
        icon = Icons.insert_drive_file_rounded;
        text = last.text.isEmpty ? 'File' : last.text;
        break;
      case MessageType.text:
      case MessageType.system:
        break;
    }

    final prefix = chat.isGroup && last.senderId != myId
        ? '${_senderName(last.senderId)}: '
        : '';

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            '$prefix$text',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }

  String _senderName(String senderId) {
    final user = chat.participants.firstWhere(
      (u) => u.id == senderId,
      orElse: () => chat.participants.first,
    );
    return user.name.split(' ').first;
  }

  Widget _trailing(BuildContext context) {
    final children = <Widget>[];
    if (chat.isMuted) {
      children.add(Icon(Icons.volume_off_rounded,
          size: 16, color: Theme.of(context).colorScheme.outline));
    }
    if (chat.isPinned) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.push_pin_rounded,
            size: 15, color: Theme.of(context).colorScheme.outline),
      ));
    }
    if (chat.unreadCount > 0) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: const BoxDecoration(
            color: AppTheme.skyBlue,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Text(
            '${chat.unreadCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}
