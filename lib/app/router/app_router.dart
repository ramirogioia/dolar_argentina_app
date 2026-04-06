import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../route_observer.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/calculator/pages/calculator_page.dart';
import '../../features/historicos/pages/historicos_page.dart';

// NavigatorKey global para acceso desde FCM Service
final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  observers: [appRouteObserver],
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          MaterialPage(key: state.pageKey, child: const HomePage()),
    ),
    GoRoute(
      path: '/historicos',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final initialType = extra is HistoricalDollarType
            ? extra
            : HistoricalDollarType.blue;
        return MaterialPage(
          key: ValueKey('historicos-${initialType.name}'),
          child: HistoricosPage(initialType: initialType),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/calculator',
      builder: (context, state) => const CalculatorPage(),
    ),
  ],
);
