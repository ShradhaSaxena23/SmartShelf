import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'repositories/mock_auth_repository.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(MockAuthRepository()),
        ),
      ],
      child: const SmartShelfApp(),
    ),
  );
}

class SmartShelfApp extends StatefulWidget {
  const SmartShelfApp({super.key});

  @override
  State<SmartShelfApp> createState() => _SmartShelfAppState();
}

class _SmartShelfAppState extends State<SmartShelfApp> {
  // App flow: Splash → Sign Up → Login → Dashboard
  String _currentRoute = 'splash';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShelf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Direct to HomeScreen on active login session
          if (authProvider.isAuthenticated) {
            return HomeScreen(
              onSignOut: () {
                setState(() {
                  _currentRoute = 'login';
                });
              },
            );
          }

          switch (_currentRoute) {
            case 'splash':
              return SplashScreen(
                onGetStarted: () {
                  setState(() {
                    _currentRoute = 'signup';
                  });
                },
              );
            case 'signup':
              return SignUpScreen(
                onNavigateToLogin: () {
                  authProvider.clearError();
                  setState(() {
                    _currentRoute = 'login';
                  });
                },
                onSignUpSuccess: () {
                  authProvider.clearError();
                  setState(() {
                    _currentRoute = 'login';
                  });
                },
              );
            case 'login':
              return LoginScreen(
                onNavigateToSignUp: () {
                  authProvider.clearError();
                  setState(() {
                    _currentRoute = 'signup';
                  });
                },
                onNavigateToForgotPassword: () {
                  authProvider.clearError();
                  setState(() {
                    _currentRoute = 'forgot_password';
                  });
                },
                onLoginSuccess: () {},
              );
            case 'forgot_password':
              return ForgotPasswordScreen(
                onBackToLogin: () {
                  authProvider.clearError();
                  setState(() {
                    _currentRoute = 'login';
                  });
                },
              );
            default:
              return SplashScreen(
                onGetStarted: () => setState(() => _currentRoute = 'signup'),
              );
          }
        },
      ),
    );
  }
}
