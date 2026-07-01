import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../services/media_service.dart';
import '../../state/auth_store.dart';
import '../../state/status_store.dart';

/// Compose a status update: a colored text card, or a photo.
class StatusComposerScreen extends StatefulWidget {
  const StatusComposerScreen({super.key});

  @override
  State<StatusComposerScreen> createState() => _StatusComposerScreenState();
}

class _StatusComposerScreenState extends State<StatusComposerScreen> {
  static const _palette = [
    0xFF1E88E5,
    0xFF26C6DA,
    0xFF7E57C2,
    0xFFEF6C00,
    0xFF2E7D32,
    0xFFD81B60,
  ];

  final _controller = TextEditingController();
  int _colorIndex = 0;
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _postText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);

    final store = context.read<StatusStore>();
    final me = context.read<AuthStore>().user ?? MockData.me;
    final navigator = Navigator.of(context);

    await store.postText(me, text, _palette[_colorIndex]);
    if (mounted) navigator.pop();
  }

  Future<void> _postPhoto() async {
    if (_posting) return;
    setState(() => _posting = true);

    final store = context.read<StatusStore>();
    final media = context.read<MediaService>();
    final me = context.read<AuthStore>().user ?? MockData.me;
    final navigator = Navigator.of(context);

    final url = await media.pickAndUploadImage(
      chatId: 'status_${me.id}',
      fromCamera: false,
    );
    if (url == null) {
      if (mounted) setState(() => _posting = false);
      return;
    }
    final caption = _controller.text.trim();
    await store.postImage(me, url, caption: caption.isEmpty ? null : caption);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Color(_palette[_colorIndex]);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: const Text('New status'),
        actions: [
          IconButton(
            tooltip: 'Change color',
            icon: const Icon(Icons.palette_rounded),
            onPressed: () => setState(
              () => _colorIndex = (_colorIndex + 1) % _palette.length,
            ),
          ),
          IconButton(
            tooltip: 'Add photo',
            icon: const Icon(Icons.image_rounded),
            onPressed: _posting ? null : _postPhoto,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textAlign: TextAlign.center,
            maxLines: null,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Type a status…',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _posting ? null : _postText,
        child: _posting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.send_rounded, color: bg),
      ),
    );
  }
}
