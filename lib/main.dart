import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/auth0_service.dart';
import 'utils/app_router.dart';
import 'utils/theme_config.dart';

/// Main entry point for the Bipolar Clarity application
/// Initializes Firebase, providers, and routes to the initial screen
void main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with default configuration
  // This requires google-services.json (Android) and GoogleService-Info.plist (iOS)
  await Firebase.initializeApp();

  // Run the app with providers for global state management
  runApp(
    MultiProvider(
      providers: [
        // Authentication service - manages user authentication state
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Auth0 service - handles Auth0-specific authentication
        ChangeNotifierProvider(create: (_) => Auth0Service()),
        // Firestore service - manages database operations
        ChangeNotifierProvider(create: (_) => FirestoreService()),
      ],
      child: const BipolarClarityApp(),
    ),
  );
}

/// Root widget of the application
/// Configures Material 3 theming and sets up routing
class BipolarClarityApp extends StatelessWidget {
  const BipolarClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return MaterialApp.router(
          // Application title shown in task switcher
          title: 'Bipolar Clarity',
          // Use Material 3 design system
          theme: ThemeConfig.lightTheme,
          darkTheme: ThemeConfig.darkTheme,
          // Use system theme mode (follows device settings)
          themeMode: ThemeMode.system,
          // Route configuration with navigation logic
          routerConfig: AppRouter.router,
          // Enable debug banner in development
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
