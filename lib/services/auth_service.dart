import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

/// Authentication service using Firebase Auth
/// Manages user authentication state and user-related operations
class AuthService extends ChangeNotifier {
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current authenticated user
  User? _currentUser;
  
  // User model from Firestore
  UserModel? _userModel;
  
  // Loading state
  bool _isLoading = false;
  
  // Error message for display
  String? _errorMessage;

  // Getters for reactive state
  User? get currentUser => _currentUser;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the auth service and set up auth state listener
  /// Call this in main.dart after Firebase initialization
  void initialize() {
    // Listen to authentication state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Handles changes in authentication state
  /// Updates current user and fetches user model if authenticated
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    
    if (user != null) {
      // User is signed in, fetch their profile from Firestore
      await _fetchUserModel();
    } else {
      // User is signed out, clear the user model
      _userModel = null;
    }
    
    notifyListeners();
  }

  /// Fetches user model from Firestore
  /// This would typically call FirestoreService
  Future<void> _fetchUserModel() async {
    if (_currentUser == null) return;
    
    try {
      // Import FirestoreService dynamically to avoid circular dependency
      // In a real app, you'd inject this or use a service locator
      // For now, we'll just set a placeholder
      _userModel = UserModel(
        id: _currentUser!.uid,
        email: _currentUser!.email ?? '',
        displayName: _currentUser!.displayName,
        photoUrl: _currentUser!.photoURL,
        hasCompletedOnboarding: false,
        hasProvidedConsent: false,
        themeMode: ThemeMode.system,
        notificationSettings: const NotificationSettings(),
        timezone: 'UTC',
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
    } catch (e) {
      _errorMessage = 'Failed to load user profile: $e';
    }
  }

  /// Signs in with email and password
  /// Returns true if successful, false otherwise
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Attempt to sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = credential.user;
      await _fetchUserModel();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      _errorMessage = _getErrorMessage(e.code);
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

  /// Creates a new account with email and password
  /// Returns true if successful, false otherwise
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create the user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update the user's display name
      await _currentUser?.updateDisplayName(displayName);
      
      _currentUser = credential.user;
      
      // Create user model and save to Firestore
      // This would typically call FirestoreService.createUser()
      _userModel = UserModel(
        id: _currentUser!.uid,
        email: email,
        displayName: displayName,
        hasCompletedOnboarding: false,
        hasProvidedConsent: false,
        themeMode: ThemeMode.system,
        notificationSettings: const NotificationSettings(),
        timezone: 'UTC',
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
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

  /// Signs out the current user
  /// Clears all local user data
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  /// Sends a password reset email to the provided email
  /// Returns true if the email was sent successfully
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates the user's profile information
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;
    
    try {
      if (displayName != null) {
        await _currentUser!.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await _currentUser!.updatePhotoURL(photoUrl);
      }
      
      // Refresh the user data
      await _currentUser!.reload();
      _currentUser = _auth.currentUser;
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  /// Re-authenticates the user before sensitive operations
  /// Required for password changes or account deletion
  Future<bool> reauthenticateWithCredential({
    required String email,
    required String password,
  }) async {
    if (_currentUser == null || _currentUser!.email == null) return false;
    
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _currentUser!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      _errorMessage = 'Re-authentication failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes the current user account
  /// WARNING: This action is irreversible
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;
    
    try {
      // Delete user data from Firestore would happen here
      await _currentUser!.delete();
      _currentUser = null;
      _userModel = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete account: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clears the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Converts Firebase Auth error codes to user-friendly messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email format. Please check your input.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Import for ThemeMode support
import 'package:flutter/material.dart';
