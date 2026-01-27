import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/splash/pages/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const SplashPage()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const HomePage()),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
