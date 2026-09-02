// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// import 'providers/auth_provider.dart';
// import 'providers/product_provider.dart';
// import 'repositories/mock_auth_repository.dart';
// import 'repositories/mock_product_repository.dart';
// import 'screens/forgot_password_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/main_shell.dart';
// import 'screens/signup_screen.dart';
// import 'screens/splash_screen.dart';
// import 'theme/app_theme.dart';

// void main() async {
//   // Ensure Flutter engine bindings are initialized before calling native code (Firebase)
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider<AuthProvider>(
//           create: (_) => AuthProvider(MockAuthRepository()),
//         ),
//         ChangeNotifierProvider<ProductProvider>(
//           create: (_) => ProductProvider(MockProductRepository()),
//         ),
//       ],
//       child: const SmartShelfApp(),
//     ),
//   );
// }

// class SmartShelfApp extends StatefulWidget {
//   const SmartShelfApp({super.key});

//   @override
//   State<SmartShelfApp> createState() => _SmartShelfAppState();
// }

// class _SmartShelfAppState extends State<SmartShelfApp> {
//   // App flow: Login → Dashboard (or Sign Up / Forgot Password)
//   String _currentRoute = 'login';

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SmartShelf',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: Consumer<AuthProvider>(
//         builder: (context, authProvider, _) {
//           // Direct to Dashboard on active login session
//           if (authProvider.isAuthenticated) {
//             return MainShell(
//               onSignOut: () {
//                 setState(() {
//                   _currentRoute = 'login';
//                 });
//               },
//             );
//           }

//           switch (_currentRoute) {
//             case 'splash':
//               return SplashScreen(
//                 onGetStarted: () {
//                   setState(() {
//                     _currentRoute = 'signup';
//                   });
//                 },
//               );
//             case 'signup':
//               return SignUpScreen(
//                 onNavigateToLogin: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//                 onSignUpSuccess: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//               );
//             case 'login':
//               return LoginScreen(
//                 onNavigateToSignUp: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'signup';
//                   });
//                 },
//                 onNavigateToForgotPassword: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'forgot_password';
//                   });
//                 },
//                 onLoginSuccess: () {},
//               );
//             case 'forgot_password':
//               return ForgotPasswordScreen(
//                 onBackToLogin: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//               );
//             default:
//               return SplashScreen(
//                 onGetStarted: () => setState(() => _currentRoute = 'signup'),
//               );
//           }
//         },
//       ),
//     );
//   }
// }

//version 2.0

// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// import 'providers/auth_provider.dart';
// import 'providers/product_provider.dart';
// import 'repositories/mock_auth_repository.dart';
// import 'repositories/mock_product_repository.dart';
// import 'screens/forgot_password_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/main_shell.dart';
// import 'screens/signup_screen.dart';
// import 'screens/splash_screen.dart';
// import 'theme/app_theme.dart';
// import 'screens/main_shell.dart';

// void main() async {
//   // Ensure Flutter engine bindings are initialized before calling native/Firebase code
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase with platform configuration
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // Activate App Check for Web
//   // Firebase Web SDK uses self.FIREBASE_APPCHECK_DEBUG_TOKEN set in web/index.html
//   await FirebaseAppCheck.instance.activate(
//     webProvider: ReCaptchaV3Provider('6LdXn4ItAAAAAH07fbK7tsyMSrqnm_jBjD56Tg96'),
//   );

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider<AuthProvider>(
//           create: (_) => AuthProvider(MockAuthRepository()),
//         ),
//         ChangeNotifierProvider<ProductProvider>(
//           create: (_) => ProductProvider(MockProductRepository()),
//         ),
//       ],
//       child: const SmartShelfApp(),
//     ),
//   );
// }

// class SmartShelfApp extends StatefulWidget {
//   const SmartShelfApp({super.key});

//   @override
//   State<SmartShelfApp> createState() => _SmartShelfAppState();
// }

// class _SmartShelfAppState extends State<SmartShelfApp> {
//   // Navigation State: 'splash', 'login', 'signup', 'forgot_password'
//   String _currentRoute = 'login';

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SmartShelf',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: Consumer<AuthProvider>(
//         builder: (context, authProvider, _) {
//           // If the user is authenticated, route directly to MainShell (Dashboard)
//           if (authProvider.isAuthenticated) {
//             return MainShell(
//               onSignOut: () {
//                 setState(() {
//                   _currentRoute = 'login';
//                 });
//               },
//             );
//           }

//           // Unauthenticated screen routing
//           switch (_currentRoute) {
//             case 'splash':
//               return SplashScreen(
//                 onGetStarted: () {
//                   setState(() {
//                     _currentRoute = 'signup';
//                   });
//                 },
//               );
//             case 'signup':
//               return SignUpScreen(
//                 onNavigateToLogin: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//                 onSignUpSuccess: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//               );
//             case 'login':
//               return LoginScreen(
//                 onNavigateToSignUp: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'signup';
//                   });
//                 },
//                 onNavigateToForgotPassword: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'forgot_password';
//                   });
//                 },
//                 onLoginSuccess: () {},
//               );
//             case 'forgot_password':
//               return ForgotPasswordScreen(
//                 onBackToLogin: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//               );
//             default:
//               return SplashScreen(
//                 onGetStarted: () => setState(() => _currentRoute = 'signup'),
//               );
//           }
//         },
//       ),
//     );
//   }
// }

//version 3.0- with firestore and ui 

// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

// import 'providers/auth_provider.dart';
// import 'providers/product_provider.dart';
// import 'repositories/mock_auth_repository.dart';
// //import 'repositories/mock_product_repository.dart';
// import 'repositories/firestore_product_repository.dart';
// import 'screens/forgot_password_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/main_shell.dart';
// import 'screens/signup_screen.dart';
// import 'screens/splash_screen.dart';
// import 'theme/app_theme.dart';

// void main() async {
//   // Ensure Flutter engine bindings are initialized before calling native/Firebase code
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase with platform configuration
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // Activate App Check for Web
//   // Firebase Web SDK uses self.FIREBASE_APPCHECK_DEBUG_TOKEN set in web/index.html
//   await FirebaseAppCheck.instance.activate(
//     webProvider: ReCaptchaV3Provider('6LdXn4ItAAAAAH07fbK7tsyMSrqnm_jBjD56Tg96'),
//   );

//   runApp(

//     MultiProvider(
//   providers: [
//     ChangeNotifierProvider<AuthProvider>(
//       create: (_) => AuthProvider(MockAuthRepository()),
//     ),

//     ChangeNotifierProvider<ProductProvider>(
//       create: (_) => ProductProvider(
//         FirestoreProductRepository(),
//       ),
//     ),
//   ],
//   child: const SmartShelfApp(),
// ),
//     // MultiProvider(
//     //   providers: [
//     //     ChangeNotifierProvider<AuthProvider>(
//     //       create: (_) => AuthProvider(MockAuthRepository()),
//     //     ),
//     //     ChangeNotifierProvider<ProductProvider>(
//     //       create: (_) => ProductProvider(MockProductRepository()),
//     //     ),
//     //   ],
//     //   child: const SmartShelfApp(),
//     // ),
//   );
// }

// class SmartShelfApp extends StatefulWidget {
//   const SmartShelfApp({super.key});

//   @override
//   State<SmartShelfApp> createState() => _SmartShelfAppState();
// }

// class _SmartShelfAppState extends State<SmartShelfApp> {
//   // Navigation State: 'splash', 'login', 'signup', 'forgot_password'
//   String _currentRoute = 'login';

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SmartShelf',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme,
//       home: Consumer<AuthProvider>(
//         builder: (context, authProvider, _) {
//           // If the user is authenticated, route directly to MainShell (Dashboard)
//           if (authProvider.isAuthenticated) {
//             return MainShell(
//               onSignOut: () {
//                 authProvider.signOut();
//                 setState(() {
//                   _currentRoute = 'login';
//                 });
//               },
//             );
//           }

//           // Unauthenticated screen routing
//           switch (_currentRoute) {
//             case 'splash':
//               return SplashScreen(
//                 onGetStarted: () {
//                   setState(() {
//                     _currentRoute = 'signup';
//                   });
//                 },
//               );
//             case 'signup':
//               return SignUpScreen(
//                 onNavigateToLogin: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//                 onSignUpSuccess: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//               );
//             case 'login':
//               return LoginScreen(
//                 onNavigateToSignUp: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'signup';
//                   });
//                 },
//                 onNavigateToForgotPassword: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'forgot_password';
//                   });
//                 },
//                 onLoginSuccess: () {},
//               );
//             case 'forgot_password':
//               return ForgotPasswordScreen(
//                 onBackToLogin: () {
//                   authProvider.clearError();
//                   setState(() {
//                     _currentRoute = 'login';
//                   });
//                 },
//               );
//             default:
//               return SplashScreen(
//                 onGetStarted: () => setState(() => _currentRoute = 'signup'),
//               );
//           }
//         },
//       ),
//     );
//   }
// }

// version 4 with authentication

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';

import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_product_repository.dart';

import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';

import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before
  // calling Firebase or other platform-specific code.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate Firebase App Check for Web.
  //
  // The reCAPTCHA site key is public and is safe to include
  // in the client application.
  //
  // For debug development, your existing debug token setup
  // in web/index.html can continue to be used.
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(
      '6Lc3XJQtAAAAADLZWA4N1J31lO8AUza06xn8K1da',
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // ----------------------------------------------------------
        // Firebase Authentication
        // ----------------------------------------------------------
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            FirebaseAuthRepository(),
          ),
        ),

        // ----------------------------------------------------------
        // Firestore Product Repository
        // ----------------------------------------------------------
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(
            FirestoreProductRepository(),
          ),
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
  // Navigation State:
  // 'splash'
  // 'login'
  // 'signup'
  // 'forgot_password'
  String _currentRoute = 'login';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShelf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // --------------------------------------------------------
          // AUTHENTICATED USER
          // --------------------------------------------------------
          //
          // FirebaseAuthRepository listens to Firebase's
          // authStateChanges() stream.
          //
          // If a Firebase user is already signed in,
          // AuthProvider.isAuthenticated becomes true and
          // MainShell is displayed automatically.
          //
          if (authProvider.isAuthenticated) {
            return MainShell(
              onSignOut: () async {
                await authProvider.signOut();

                if (mounted) {
                  setState(() {
                    _currentRoute = 'login';
                  });
                }
              },
            );
          }

          // --------------------------------------------------------
          // UNAUTHENTICATED USER
          // --------------------------------------------------------

          switch (_currentRoute) {
            // ------------------------------------------------------
            // SPLASH
            // ------------------------------------------------------
            case 'splash':
              return SplashScreen(
                onGetStarted: () {
                  setState(() {
                    _currentRoute = 'signup';
                  });
                },
              );

            // ------------------------------------------------------
            // SIGN UP
            // ------------------------------------------------------
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

            // ------------------------------------------------------
            // LOGIN
            // ------------------------------------------------------
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

                onLoginSuccess: () {
                  // Firebase authentication state automatically
                  // updates AuthProvider.
                  //
                  // Consumer<AuthProvider> will then rebuild and
                  // show MainShell.
                },
              );

            // ------------------------------------------------------
            // FORGOT PASSWORD
            // ------------------------------------------------------
            case 'forgot_password':
              return ForgotPasswordScreen(
                onBackToLogin: () {
                  authProvider.clearError();

                  setState(() {
                    _currentRoute = 'login';
                  });
                },
              );

            // ------------------------------------------------------
            // DEFAULT
            // ------------------------------------------------------
            default:
              return SplashScreen(
                onGetStarted: () {
                  setState(() {
                    _currentRoute = 'signup';
                  });
                },
              );
          }
        },
      ),
    );
  }
}