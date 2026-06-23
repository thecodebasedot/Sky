import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';
import 'otp_verify_screen.dart';

/// Collects the user's phone number and requests a verification code.
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _controller = TextEditingController();
  final _dialCodeController = TextEditingController(text: '+1');
  bool _valid = false;

  String get _dialCode => _dialCodeController.text.trim();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final v = _controller.text.replaceAll(RegExp(r'\D'), '').length >= 7;
      if (v != _valid) setState(() => _valid = v);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dialCodeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final auth = context.read<AuthStore>();
    final phone = '$_dialCode ${_controller.text.trim()}';
    await auth.sendCode(phone);
    if (!mounted) return;
    if (auth.status == AuthStatus.codeSent) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerifyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = context.watch<AuthStore>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter your number')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              'Sky will send an SMS to verify your phone number.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 76,
                  child: TextField(
                    controller: _dialCodeController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '555 0100',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.skyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (_valid && !busy) ? _continue : null,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
