import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Bottom input bar: attachment menu, text field, and send / mic button.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    required this.onSendImage,
    required this.onSendFile,
    required this.onSendVoice,
    required this.onTyping,
  });

  /// Send a plain text message.
  final ValueChanged<String> onSend;

  /// Report whether the user is currently composing.
  final ValueChanged<bool> onTyping;

  /// Send an image (from gallery or camera).
  final VoidCallback onSendImage;

  /// Send a document/file.
  final VoidCallback onSendFile;

  /// Send a voice note of the given length in seconds.
  final ValueChanged<int> onSendVoice;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
        widget.onTyping(has);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    widget.onTyping(false);
  }

  Future<void> _openAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget option(IconData icon, String label, Color color, VoidCallback
            onTap) {
          return InkWell(
            onTap: () {
              Navigator.of(sheetContext).pop();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 20,
            children: [
              option(Icons.photo_rounded, 'Gallery', const Color(0xFF7E57C2),
                  widget.onSendImage),
              option(Icons.camera_alt_rounded, 'Camera',
                  const Color(0xFFD81B60), widget.onSendImage),
              option(Icons.insert_drive_file_rounded, 'Document',
                  const Color(0xFF1E88E5), widget.onSendFile),
              option(Icons.headset_rounded, 'Audio', const Color(0xFFEF6C00),
                  () => widget.onSendVoice(8)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      color: theme.colorScheme.outline,
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded),
                      color: theme.colorScheme.outline,
                      onPressed: _openAttachmentSheet,
                    ),
                    if (!_hasText)
                      IconButton(
                        icon: const Icon(Icons.camera_alt_rounded),
                        color: theme.colorScheme.outline,
                        onPressed: widget.onSendImage,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            FloatingActionButton(
              heroTag: 'composer-send',
              elevation: 0,
              backgroundColor: AppTheme.skyBlue,
              onPressed: _hasText ? _send : () => widget.onSendVoice(5),
              child: Icon(
                _hasText ? Icons.send_rounded : Icons.mic_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
