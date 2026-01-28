import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/settings/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Inicializar AdMob (con manejo de errores)
  try {
    await MobileAds.instance.initialize();
    print('✅ AdMob inicializado correctamente');
  } catch (e) {
    print('⚠️ Error al inicializar AdMob: $e');
    // Continuar aunque falle AdMob para que la app arranque
  }

  runApp(
    const ProviderScope(
      child: DolarArgentinaApp(),
    ),
  );
}

class DolarArgentinaApp extends ConsumerWidget {
  const DolarArgentinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == 'dark';

    return MaterialApp.router(
      title: 'Dólar Argentina',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
