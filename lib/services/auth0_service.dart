import 'package:flutter/foundation.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import '../models/user.dart';

/// Auth0 Authentication Service
/// Provides alternative authentication method using Auth0
/// Useful for enterprise SSO and social login integration
class Auth0Service extends ChangeNotifier {
  // Auth0 client instance
  Auth0? _auth0Client;
  
  // User credentials from Auth0
  Credentials? _credentials;
  
  // Loading state
  bool _isLoading = false;
  
  // Error message for display
  String? _errorMessage;

  // Getters for reactive state
  Credentials? get credentials => _credentials;
  bool get isAuthenticated => _credentials != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the Auth0 client with configuration
  /// Call this in main.dart or in your auth initialization
  void initialize({
    required String domain,
    required String clientId,
  }) {
    _auth0Client = Auth0(
      domain: domain,
      clientId: clientId,
    );
  }

  /// Checks if Auth0 is properly configured
  bool get isConfigured => _auth0Client != null;

  /// Logs in using Auth0 Universal Login
  /// Opens the Auth0 hosted login page in a browser/webview
  Future<bool> loginWithAuth0({
    List<String>? scopes,
    Map<String, String>? parameters,
  }) async {
    if (!isConfigured) {
      _errorMessage = 'Auth0 is not configured. Please set up your credentials.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Attempt to log in with Auth0
      // This will open the Universal Login page
      _credentials = await _auth0Client!.webAuthentication.login(
        scope: scopes?.join(' ') ?? 'openid profile email offline_access',
        parameters: parameters ?? {},
      );

      // If successful, you might want to sync with Firebase
      // or create a Firebase custom token using the Auth0 ID token
      await _syncAuth0User();

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthenticationException catch (e) {
      _errorMessage = _getAuth0ErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logs in with a specific identity provider
  /// Useful for enterprise SSO (Okta, Azure AD, etc.)
  Future<bool> loginWithProvider(String connectionName) async {
    return loginWithAuth0(
      parameters: {
        'connection': connectionName,
        'screen_hint': 'signup',
      },
    );
  }

  /// Logs out from Auth0
  /// Clears local session and redirects to Auth0 logout
  Future<void> logout() async {
    if (!isConfigured || _credentials == null) return;

    try {
      // Log out from Auth0 (clears SSO session)
      await _auth0Client!.webAuthentication.logout(
        returnTo: 'bipolarclarity://', // Your app's deep link
      );

      _credentials = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to logout: $e';
      notifyListeners();
    }
  }

  /// Refreshes the access token using the refresh token
  /// Useful for maintaining long-lived sessions
  Future<bool> refreshToken() async {
    if (_credentials == null || _credentials!.refreshToken == null) {
      return false;
    }

    try {
      _credentials = await _auth0Client!.credentials.refresh(
        refreshToken: _credentials!.refreshToken!,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to refresh token: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gets user profile information from Auth0
  Future<UserProfile?> getUserProfile() async {
    if (!isAuthenticated || _credentials == null) return null;

    try {
      return await _auth0Client!.userProfile(
        accessToken: _credentials!.accessToken,
      );
    } catch (e) {
      _errorMessage = 'Failed to get user profile: $e';
      notifyListeners();
      return null;
    }
  }

  /// Syncs Auth0 user data with the app's user model
  /// Creates or updates the user in your backend if needed
  Future<void> _syncAuth0User() async {
    if (_credentials == null) return;

    try {
      final userProfile = await getUserProfile();
      if (userProfile != null) {
        // You can sync this data with Firestore or your backend
        // This is where you'd create/update the user model
        // based on Auth0 profile information
        debugPrint('Auth0 user synced: ${userProfile.name}');
      }
    } catch (e) {
      debugPrint('Failed to sync Auth0 user: $e');
    }
  }

  /// Gets the ID token for API authentication
  /// Useful for making authenticated API calls
  Future<String?> getIdToken() async {
    if (!isAuthenticated || _credentials == null) return null;
    
    try {
      // Refresh token if needed before getting ID token
      if (_isTokenExpired()) {
        await refreshToken();
      }
      return _credentials!.idToken;
    } catch (e) {
      _errorMessage = 'Failed to get ID token: $e';
      return null;
    }
  }

  /// Gets the access token for API authentication
  Future<String?> getAccessToken() async {
    if (!isAuthenticated || _credentials == null) return null;
    
    try {
      if (_isTokenExpired()) {
        await refreshToken();
      }
      return _credentials!.accessToken;
    } catch (e) {
      _errorMessage = 'Failed to get access token: $e';
      return null;
    }
  }

  /// Checks if the current token is expired
  bool _isTokenExpired() {
    if (_credentials == null || _credentials!.expiresAt == null) return true;
    return DateTime.now().isAfter(_credentials!.expiresAt!);
  }

  /// Exchanges an Auth0 ID token for a Firebase custom token
  /// This allows seamless integration between Auth0 and Firebase
  Future<String?> exchangeForFirebaseToken() async {
    final idToken = await getIdToken();
    if (idToken == null) return null;

    // In a real app, you'd call your backend to exchange the Auth0 token
    // for a Firebase custom token
    // This requires setting up Auth0 as an identity provider in Firebase
    try {
      // Example backend call (implement this on your server):
      // POST /auth/exchange-auth0-for-firebase
      // Body: { idToken: idToken }
      // Response: { firebaseToken: "..." }
      
      debugPrint('Would exchange Auth0 token for Firebase token');
      return idToken; // Placeholder - return actual Firebase token in production
    } catch (e) {
      _errorMessage = 'Failed to exchange tokens: $e';
      return null;
    }
  }

  /// Clears the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Converts Auth0 exceptions to user-friendly messages
  String _getAuth0ErrorMessage(AuthenticationException e) {
    switch (e.code) {
      case 'a0.session_user_missing':
        return 'Session expired. Please log in again.';
      case 'a0.invalid_refresh_token':
        return 'Session expired. Please log in again.';
      case 'a0.pkce_not_allowed':
        return 'PKCE authentication is not supported on this platform.';
      case 'a0.browser_not_available':
        return 'Unable to open the login browser. Please try again.';
      case 'access_denied':
        return 'Access denied. You may not have permission to log in.';
      case 'unauthorized':
        return 'Unauthorized. Please check your credentials.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
