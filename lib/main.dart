// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // L'import magique est ici

// --- PROVIDERS ---
import 'providers/auth_provider.dart';

// --- CORE ---
import 'core/constants.dart';

// --- VIEWS ---
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/forgot_password_view.dart';
import 'views/reset_password_view.dart';
import 'views/dashboard_view.dart';

// Nouvelles vues intégrées
import 'views/add_view.dart';
import 'views/history_view.dart';
import 'views/goals_view.dart';
import 'views/loans_view.dart';
import 'views/settings_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CodeArcanumApp());
}

class CodeArcanumApp extends StatelessWidget {
  const CodeArcanumApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Code Arcanum',
        debugShowCheckedModeBanner: false,
        
        // 2. Design System Centralisé avec Google Fonts
        theme: ThemeData(
          // C'est ici que le package applique la police Inter à toute l'application
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.backgroundLight,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        
        initialRoute: '/',
        
        // 3. Routage Intelligent
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/reset_password')) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'] ?? '';
            return MaterialPageRoute(
              builder: (context) => ResetPasswordView(token: token),
            );
          }

          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (context) => const SplashScreen());
            case '/home':
              return MaterialPageRoute(builder: (context) => const HomeView());
            case '/login':
              return MaterialPageRoute(builder: (context) => const LoginView());
            case '/register':
              return MaterialPageRoute(builder: (context) => const RegisterView());
            case '/forgot_password':
              return MaterialPageRoute(builder: (context) => const ForgotPasswordView());
            case '/app/dashboard':
              return MaterialPageRoute(builder: (context) => const DashboardView());
              
            // --- Nouvelles routes ---
            case '/app/add':
              return MaterialPageRoute(builder: (context) => const AddView());
            case '/app/history':
              return MaterialPageRoute(builder: (context) => const HistoryView());
            case '/app/goals':
              return MaterialPageRoute(builder: (context) => const GoalsView());
            case '/app/loans':
              return MaterialPageRoute(builder: (context) => const LoansView());
            case '/app/settings':
              return MaterialPageRoute(builder: (context) => const SettingsView());
              
            default:
              return MaterialPageRoute(builder: (context) => const HomeView());
          }
        },
      ),
    );
  }
}

// ==========================================
// SPLASH SCREEN (Écran de démarrage & Auto-Login)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final isLoggedIn = await authProvider.checkAuthState();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/app/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: TweenAnimationBuilder(
          duration: const Duration(seconds: 1),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
            ),
            alignment: Alignment.center,
            child: const Text("A", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}