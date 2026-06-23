import 'package:flutter/material.dart';

import '../../../models/message.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/time_format.dart';

/// A single chat bubble. Outgoing bubbles align right and carry status ticks.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSender = false,
    this.senderName,
  });

  final Message message;
  final bool isMine;
  final bool showSender;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isMine
        ? (isDark ? AppTheme.bubbleOutgoingDark : AppTheme.bubbleOutgoing)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSender && !isMine && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.skyBlue,
                  ),
                ),
              ),
            _content(context),
            const SizedBox(height: 2),
            _meta(context),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (message.type) {
      case MessageType.voice:
        return _voiceNote(context);
      case MessageType.image:
        return _imagePlaceholder(context);
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, size: 28),
            const SizedBox(width: 8),
            Text(message.text.isEmpty ? 'Attachment' : message.text),
          ],
        );
      case MessageType.text:
      case MessageType.system:
        return Text(message.text, style: const TextStyle(fontSize: 15.5));
    }
  }

  Widget _voiceNote(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow_rounded, size: 28),
        const SizedBox(width: 6),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: 0,
            minHeight: 3,
            backgroundColor: Colors.black.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(width: 8),
        Text(TimeFormat.duration(message.durationSeconds ?? 0)),
      ],
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.image_rounded, size: 48, color: Colors.grey),
        ),
        if (message.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(message.text, style: const TextStyle(fontSize: 15.5)),
          ),
      ],
    );
  }

  Widget _meta(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          TimeFormat.clock(message.timestamp),
          style: TextStyle(fontSize: 11, color: color),
        ),
        if (isMine) ...[
          const SizedBox(width: 3),
          _statusIcon(),
        ],
      ],
    );
  }

  Widget _statusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time_rounded, size: 13);
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 14);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 14);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: AppTheme.skyBlue);
    }
  }
}
