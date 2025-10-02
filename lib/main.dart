// Fichier: main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/merchant_form_screen.dart';
import 'screens/agent_dashboard_screen.dart';
import 'screens/merchant_list_screen.dart';
import 'screens/agent_performance_dashboard_screen.dart';
import 'screens/supervisor_dashboard_screen.dart';
import 'locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moov Money Agent App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Personnalisation des boutons pour un meilleur style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Personnalisation de l'apparence des champs de texte
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
      ),
      // Le splash screen est maintenant la route initiale
      initialRoute: kIsWeb ? '/' : '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/': (context) => LoginScreen(),
        '/merchant-form': (context) => MerchantFormScreen(),
        '/agent-dashboard': (context) => AgentDashboardScreen(),
        '/merchant-list': (context) => MerchantListScreen(),
        '/agent-performance': (context) => AgentPerformanceDashboardScreen(),
        '/supervisor-dashboard': (context) => SupervisorDashboardScreen(),
      },
    );
  }
}
