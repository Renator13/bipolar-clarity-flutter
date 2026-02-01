import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/mood_checkin/mood_checkin_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/emergency_contact/emergency_contact_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../services/auth_service.dart';

/// Application router configuration
/// Manages all navigation routes using GoRouter
class AppRouter {
  // GoRouter instance
  static GoRouter get router {
    return GoRouter(
      // Initial redirect - checks auth state and redirects accordingly
      initialLocation: '/',
      redirect: (context, state) async {
        // Get AuthService from context (injected at root)
        final authService = AuthService();
        
        // Determine if user is authenticated
        final isAuthenticated = authService.isAuthenticated;
        
        // Determine if onboarding is complete
        final hasCompletedOnboarding = authService.userModel?.hasCompletedOnboarding ?? false;
        
        // Get current location
        final location = state.uri.toString();
        
        // Auth required routes
        final authRequiredRoutes = [
          '/dashboard',
          '/check-in',
          '/insights',
          '/settings',
          '/emergency-contact',
          '/admin',
        ];
        
        // Onboarding routes
        final onboardingRoutes = [
          '/onboarding',
          '/onboarding/permissions',
          '/onboarding/notifications',
          '/onboarding/consent',
        ];
        
        // Redirect logic
        if (!isAuthenticated && location != '/login' && location != '/register') {
          return '/login';
        }
        
        if (isAuthenticated && (location == '/login' || location == '/register')) {
          if (!hasCompletedOnboarding) {
            return '/onboarding';
          }
          return '/dashboard';
        }
        
        if (isAuthenticated && !hasCompletedOnboarding && !onboardingRoutes.any(location.startsWith)) {
          return '/onboarding';
        }
        
        // Admin route protection
        if (location.startsWith('/admin')) {
          // TODO: Add admin role check
          // final isAdmin = authService.userModel?.isAdmin ?? false;
          // if (!isAdmin) return '/dashboard';
        }
        
        return null;
      },
      // Error handler for unknown routes
      errorPageBuilder: (context, state) => MaterialPage(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The page "${state.uri}" does not exist.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
      routes: [
        // ==================== ONBOARDING ROUTES ====================
        
        /// Welcome screen - first onboarding screen
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
          routes: [
            /// Permissions screen
            GoRoute(
              path: 'permissions',
              name: 'onboarding-permissions',
              builder: (context, state) => const OnboardingPermissionsScreen(),
            ),
            /// Notifications screen
            GoRoute(
              path: 'notifications',
              name: 'onboarding-notifications',
              builder: (context, state) => const OnboardingNotificationsScreen(),
            ),
            /// Consent screen
            GoRoute(
              path: 'consent',
              name: 'onboarding-consent',
              builder: (context, state) => const OnboardingConsentScreen(),
            ),
          ],
        ),

        // ==================== AUTH ROUTES ====================
        
        /// Login screen
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        
        /// Registration screen
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // ==================== MAIN APP ROUTES ====================
        
        /// Main dashboard - shows mood overview, status light, sleep metrics
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        
        /// Quick mood check-in screen (5-second flow)
        GoRoute(
          path: '/check-in',
          name: 'check-in',
          builder: (context, state) => const MoodCheckInScreen(),
        ),
        
        /// Insights and analytics screen
        GoRoute(
          path: '/insights',
          name: 'insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        
        /// User settings screen
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            /// Emergency contact configuration
            GoRoute(
              path: 'emergency-contact',
              name: 'emergency-contact',
              builder: (context, state) => const EmergencyContactScreen(),
            ),
          ],
        ),
        
        /// Admin dashboard (for René)
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        
        // ==================== CATCH-ALL REDIRECT ====================
        
        /// Redirect root to appropriate page based on auth state
        GoRoute(
          path: '/',
          name: 'root',
          redirect: (context, state) async {
            final authService = AuthService();
            if (!authService.isAuthenticated) {
              return '/login';
            }
            if (!(authService.userModel?.hasCompletedOnboarding ?? false)) {
              return '/onboarding';
            }
            return '/dashboard';
          },
        ),
      ],
    );
  }
}

/// Route names for easy navigation
class RouteNames {
  // Onboarding
  static const onboarding = 'onboarding';
  static const onboardingPermissions = 'onboarding-permissions';
  static const onboardingNotifications = 'onboarding-notifications';
  static const onboardingConsent = 'onboarding-consent';
  
  // Auth
  static const login = 'login';
  static const register = 'register';
  
  // Main app
  static const dashboard = 'dashboard';
  static const checkIn = 'check-in';
  static const insights = 'insights';
  static const settings = 'settings';
  static const emergencyContact = 'emergency-contact';
  static const admin = 'admin';
}

/// Navigation helper extension
extension NavigationContext on BuildContext {
  /// Navigate to a named route
  void navigate(String name, {Map<String, String> params = const {}}) {
    goNamed(name, pathParameters: params);
  }
  
  /// Push a new route onto the stack
  void pushRoute(String path) {
    push(path);
  }
  
  /// Pop the current route
  void popRoute() {
    pop();
  }
}
