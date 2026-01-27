import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ocultar el splash nativo inmediatamente cuando Flutter esté listo
  // Esto permite que solo se vea el splash de Flutter (el grande)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(
    const ProviderScope(
      child: DolarArgentinaApp(),
    ),
  );
}

class DolarArgentinaApp extends StatelessWidget {
  const DolarArgentinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dólar Argentina',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
