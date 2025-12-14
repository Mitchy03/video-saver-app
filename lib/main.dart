import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/ad_screen.dart';
import 'screens/download_progress_screen.dart';
import 'screens/home_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.bootstrap();
  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: '4SNS Video Saver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: AppLocalizations.globalDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: SplashScreen.routeName,
        routes: {
          SplashScreen.routeName: (_) => const SplashScreen(),
          HomeScreen.routeName: (_) => const HomeScreen(),
          PremiumScreen.routeName: (_) => const PremiumScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          AdScreen.routeName: (_) => const AdScreen(),
          DownloadProgressScreen.routeName: (_) => const DownloadProgressScreen(),
        },
      ),
    );
  }
}
