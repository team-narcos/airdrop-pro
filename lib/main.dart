import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/ios18_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/services_providers.dart';
import 'screens/home_screen.dart';
import 'screens/ultra_premium_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/premium_splash_screen.dart';
import 'screens/telegram_splash_screen.dart';
import 'services/error_logger_service.dart';
import 'services/notification_service.dart';
import 'providers/p2p_manager_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error logger
  await errorLogger.initialize();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ProviderScope(child: AirDropApp()));
}

class AirDropApp extends ConsumerWidget {
  const AirDropApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notification service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize(context);
    });
    
    // Initialize TCP transfer server for receiving files
    ref.watch(tcpTransferServiceProvider);
    
    // Watch settings for theme mode
    final settingsAsync = ref.watch(appSettingsProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (settings) => settings.themeMode,
      orElse: () => ThemeMode.system,
    );
    
    // Determine actual brightness based on theme mode
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && platformBrightness == Brightness.dark);
    
    return CupertinoApp(
      title: 'AirDrop',
      debugShowCheckedModeBanner: false,
      theme: isDark ? iOS18Theme.darkTheme : iOS18Theme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const TelegramSplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child!,
        );
      },
    );
  }
}
