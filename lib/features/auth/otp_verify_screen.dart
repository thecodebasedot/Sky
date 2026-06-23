import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../state/auth_store.dart';
import '../../theme/app_theme.dart';

/// Six-digit verification code entry.
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    final auth = context.read<AuthStore>();
    await auth.verifyCode(code);
    if (!mounted) return;
    if (auth.error != null) {
      // Surface the error inline and let the user retry.
      _controller.clear();
    } else {
      // Verified: drop the pushed auth routes so the AuthGate's next
      // destination (profile setup or home) becomes visible.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your number')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              'Enter the 6-digit code sent to',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 4),
            Text(
              auth.phoneNumber ?? '',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            TextField(
              key: const Key('otp_field'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 30,
                letterSpacing: 14,
                fontWeight: FontWeight.w600,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••••',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                if (auth.error != null) auth.clearError();
                if (v.length == 6) _verify(v);
              },
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            if (auth.busy)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: () {
                  final phone = auth.phoneNumber;
                  if (phone != null) auth.sendCode(phone);
                },
                child: const Text('Resend code'),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.skyBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppTheme.skyBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo mode: enter ${MockAuthService.demoCode} '
                      '(or any 6 digits) to continue.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
