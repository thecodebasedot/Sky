import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'phone_input_screen.dart';

/// First screen for signed-out users: branding + entry to phone sign-in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.skyBlue, AppTheme.skyAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.cloud_rounded,
                    size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('Welcome to Sky',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Simple, secure messaging and calling for everyone, '
                'everywhere.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const Spacer(flex: 4),
              Text(
                'By continuing you agree to our Terms of Service and '
                'Privacy Policy.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.skyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PhoneInputScreen(),
                      ),
                    );
                  },
                  child: const Text('Agree & continue',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
