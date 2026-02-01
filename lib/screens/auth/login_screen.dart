import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/auth0_service.dart';

/// Login screen for user authentication
/// Supports email/password login and Auth0 SSO
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Password visibility toggle
  bool _isPasswordVisible = false;
  
  // Loading state
  bool _isLoading = false;

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome back header
              const SizedBox(height: 40),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your wellness journey',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Login form
              _buildLoginForm(context),
              
              const SizedBox(height: 32),
              
              // Divider with "or" text
              _buildDivider(context),
              
              const SizedBox(height: 32),
              
              // Social/SSO login buttons
              _buildSSOLoginButtons(context),
              
              const SizedBox(height: 32),
              
              // Sign up link
              _buildSignUpLink(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the email/password login form
  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Enter your email',
            ),
            validator: _validateEmail,
          ),
          
          const SizedBox(height: 16),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              hintText: 'Enter your password',
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => _handleLogin(context),
          ),
          
          const SizedBox(height: 12),
          
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              child: const Text('Forgot Password?'),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Login button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleLogin(context),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Sign In'),
            ),
          ),
          
          // Error message display
          if (context.watch<AuthService>().errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.watch<AuthService>().errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the divider with "or" text
  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }

  /// Builds SSO login buttons (Google, Apple, etc.)
  Widget _buildSSOLoginButtons(BuildContext context) {
    return Column(
      children: [
        // Auth0 / SSO Login button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _handleSSOLogin(context),
            icon: const Icon(Icons.business),
            label: const Text('Sign in with Organization'),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Continue without login (demo mode)
        TextButton(
          onPressed: () {
            // Allow demo mode for testing
            context.go('/dashboard');
          },
          child: Text(
            'Continue as Guest (Demo)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the sign up link for new users
  Widget _buildSignUpLink(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: 'Sign Up',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push('/register'),
            ),
          ],
        ),
      ),
    );
  }

  /// Validates email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Handles email/password login
  Future<void> _handleLogin(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    
    final success = await authService.signInWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      // Clear error and navigate
      authService.clearError();
      
      // Check onboarding status and navigate accordingly
      if (authService.userModel?.hasCompletedOnboarding ?? false) {
        context.go('/dashboard');
      } else {
        context.go('/onboarding');
      }
    }
  }

  /// Handles SSO login via Auth0
  Future<void> _handleSSOLogin(BuildContext context) async {
    final auth0Service = context.read<Auth0Service>();
    
    // Initialize Auth0 if not already done
    // In production, these would come from environment/config
    if (!auth0Service.isConfigured) {
      auth0Service.initialize(
        domain: 'your-tenant.auth0.com',
        clientId: 'your-client-id',
      );
    }

    // Login with Auth0 - this will open Universal Login
    final success = await auth0Service.loginWithAuth0();
    
    if (success && mounted) {
      // Navigate to dashboard after successful Auth0 login
      context.go('/dashboard');
    }
  }

  /// Shows forgot password dialog
  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address and we\'ll send you instructions to reset your password.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final authService = context.read<AuthService>();
                      final success = await authService.sendPasswordResetEmail(
                        emailController.text.trim(),
                      );
                      setState(() => isLoading = false);
                      
                      if (success && mounted) {
                        context.pop();
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent!'),
                          ),
                        );
                      }
                    },
              child: const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
