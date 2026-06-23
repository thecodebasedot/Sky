import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/home/home_screen.dart';
import 'state/chat_store.dart';
import 'theme/app_theme.dart';

/// Root widget: provides app-wide state and theming.
class SkyApp extends StatelessWidget {
  const SkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatStore(),
      child: MaterialApp(
        title: 'Sky',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
