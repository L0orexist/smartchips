import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/services.dart';
import 'ui/screens/screens.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Imposta la UI in modalità immersiva (fullscreen)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Imposta i colori della system bar per il tema scuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Blocca l'orientamento in verticale (opzionale, rimuovere se serve landscape)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const SmartChipsApp());
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP ROOT
// ═══════════════════════════════════════════════════════════════════════════════

class SmartChipsApp extends StatelessWidget {
  const SmartChipsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servizio di rete per comunicazione WebSocket
        ChangeNotifierProvider(create: (_) => NetworkService()),

        // Provider stato di gioco (dipende da NetworkService)
        ChangeNotifierProxyProvider<NetworkService, GameProvider>(
          create: (_) => GameProvider(),
          update: (_, network, game) => game!..updateNetworkService(network),
        ),
      ],
      child: MaterialApp(
        // ─────────────────────────────────────────────────────────────────────
        // CONFIGURAZIONE APP
        // ─────────────────────────────────────────────────────────────────────
        title: 'SmartChips - Blackjack Manager',
        debugShowCheckedModeBanner: false,

        // ─────────────────────────────────────────────────────────────────────
        // TEMA
        // ─────────────────────────────────────────────────────────────────────
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,

        // ─────────────────────────────────────────────────────────────────────
        // SCHERMATA INIZIALE
        // ─────────────────────────────────────────────────────────────────────
        home: const HomeScreen(),
      ),
    );
  }
}
