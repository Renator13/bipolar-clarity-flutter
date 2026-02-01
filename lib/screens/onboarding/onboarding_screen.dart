import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Welcome screen - First onboarding screen
/// Introduces the app and sets the tone for the user
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a gradient background for visual appeal
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 60,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Welcome headline
                Text(
                  'Welcome to Bipolar Clarity',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle with app description
                Text(
                  'Your personal companion for understanding and managing your mood patterns. Track, analyze, and gain insights into your emotional well-being.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Feature highlights
                _buildFeatureTile(
                  context,
                  icon: Icons.trending_up,
                  title: 'Track Your Mood',
                  description: 'Quick and easy daily check-ins to monitor your emotional state',
                ),
                
                const SizedBox(height: 12),
                
                _buildFeatureTile(
                  context,
                  icon: Icons.insights,
                  title: 'Discover Patterns',
                  description: 'Identify correlations between mood, sleep, and activities',
                ),
                
                const SizedBox(height: 12),
                
                _buildFeatureTile(
                  context,
                  icon: Icons.security,
                  title: 'Stay Safe',
                  description: 'Trusted ally support and crisis resources when you need them',
                ),
                
                const SizedBox(height: 48),
                
                // Get started button
                ElevatedButton(
                  onPressed: () => context.push('/onboarding/permissions'),
                  child: const Text('Get Started'),
                ),
                
                const SizedBox(height: 16),
                
                // Skip button (optional - for users who want to explore quickly)
                TextButton(
                  onPressed: () {
                    // In a real app, you might want to track this
                    context.push('/dashboard');
                  },
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a feature highlight tile with icon, title, and description
  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Permissions screen - Second onboarding screen
/// Requests necessary app permissions (notifications, storage, etc.)
class OnboardingPermissionsScreen extends StatelessWidget {
  const OnboardingPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and progress indicator
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  // Progress dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: false),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: false),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Enable Permissions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Bipolar Clarity needs the following permissions to provide the best experience:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Permission cards
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      context,
                      icon: Icons.notifications,
                      title: 'Notifications',
                      description: 'Receive daily check-in reminders and important alerts about your mood patterns.',
                      permissionGranted: true, // Would be dynamic in real app
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      context,
                      icon: Icons.access_time,
                      title: 'Background App Refresh',
                      description: 'Allow the app to check your mood patterns even when it\'s not open.',
                      permissionGranted: false,
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(
                      context,
                      icon: Icons.security,
                      title: 'Health Data Access',
                      description: 'Optionally sync with health apps to incorporate sleep and activity data.',
                      permissionGranted: false,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              ElevatedButton(
                onPressed: () => context.push('/onboarding/notifications'),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a progress indicator dot
  Widget _buildProgressDot(BuildContext context, {required bool isActive}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Builds a permission request card
  Widget _buildPermissionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool permissionGranted,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: permissionGranted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: permissionGranted
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: permissionGranted
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (permissionGranted)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!permissionGranted) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      // Request permission logic here
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 36),
                    ),
                    child: const Text('Enable'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications preferences screen - Third onboarding screen
/// Configure notification settings for check-in reminders
class OnboardingNotificationsScreen extends StatefulWidget {
  const OnboardingNotificationsScreen({super.key});

  @override
  State<OnboardingNotificationsScreen> createState() =>
      _OnboardingNotificationsScreenState();
}

class _OnboardingNotificationsScreenState
    extends State<OnboardingNotificationsScreen> {
  // Notification preference states
  bool _dailyReminder = true;
  bool _patternAlerts = true;
  bool _weeklyReports = true;
  int _selectedHour = 20; // Default 8 PM

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and progress
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: false),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Set Your Preferences',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Configure how and when you want to receive reminders:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Notification preferences
              Expanded(
                child: ListView(
                  children: [
                    // Daily reminder toggle
                    _buildSwitchTile(
                      context,
                      icon: Icons.access_time,
                      title: 'Daily Check-in Reminder',
                      subtitle: 'Get a daily reminder to log your mood',
                      value: _dailyReminder,
                      onChanged: (value) => setState(() => _dailyReminder = value),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Time picker (only visible if daily reminder is on)
                    if (_dailyReminder) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.schedule,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reminder Time',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '$_selectedHour:00 ${_selectedHour >= 12 ? 'PM' : 'AM'}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showTimePicker(context),
                              icon: const Icon(Icons.edit_calendar),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Pattern alerts toggle
                    _buildSwitchTile(
                      context,
                      icon: Icons.insights,
                      title: 'Pattern Alerts',
                      subtitle: 'Get notified about significant mood changes',
                      value: _patternAlerts,
                      onChanged: (value) => setState(() => _patternAlerts = value),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Weekly reports toggle
                    _buildSwitchTile(
                      context,
                      icon: Icons.assessment,
                      title: 'Weekly Insights Report',
                      subtitle: 'Receive a weekly summary of your mood patterns',
                      value: _weeklyReports,
                      onChanged: (value) => setState(() => _weeklyReports = value),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              ElevatedButton(
                onPressed: () => context.push('/onboarding/consent'),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(BuildContext context, {required bool isActive}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dayPeriodBorderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
      });
    }
  }
}

/// Consent screen - Fourth and final onboarding screen
/// Obtains user consent for data processing and privacy policy
class OnboardingConsentScreen extends StatefulWidget {
  const OnboardingConsentScreen({super.key});

  @override
  State<OnboardingConsentScreen> createState() => _OnboardingConsentScreenState();
}

class _OnboardingConsentScreenState extends State<OnboardingConsentScreen> {
  // Consent checkbox states
  bool _privacyConsent = false;
  bool _dataProcessingConsent = false;
  bool _emergencyContactConsent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and progress
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: true),
                      const SizedBox(width: 8),
                      _buildProgressDot(context, isActive: true),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Privacy & Consent',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Please review and accept the following to get started:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Consent options
              Expanded(
                child: ListView(
                  children: [
                    // Privacy policy consent
                    _buildConsentCheckbox(
                      context,
                      title: 'Privacy Policy',
                      description: 'I have read and agree to the Privacy Policy and understand how my data is collected and used.',
                      linkText: 'Read Privacy Policy',
                      onLinkTap: () => _openPrivacyPolicy(),
                      value: _privacyConsent,
                      onChanged: (value) => setState(() => _privacyConsent = value),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Data processing consent
                    _buildConsentCheckbox(
                      context,
                      title: 'Data Processing',
                      description: 'I consent to the processing of my mood and health data for the purpose of providing personalized insights and analytics.',
                      value: _dataProcessingConsent,
                      onChanged: (value) => setState(() => _dataProcessingConsent = value),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Emergency contact consent
                    _buildConsentCheckbox(
                      context,
                      title: 'Emergency Contact Alerts',
                      description: 'I understand that my trusted ally may be notified if the app detects signs of crisis.',
                      value: _emergencyContactConsent,
                      onChanged: (value) => setState(() => _emergencyContactConsent = value),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Important notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.errorContainer,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This app is not a replacement for professional medical care. If you\'re experiencing a crisis, please contact emergency services or a mental health professional.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Complete setup button
              ElevatedButton(
                onPressed: _canCompleteOnboarding
                    ? () => _completeOnboarding(context)
                    : null,
                child: const Text('Complete Setup'),
              ),
              
              const SizedBox(height: 12),
              
              // Can complete indicator
              if (!_canCompleteOnboarding)
                Center(
                  child: Text(
                    'Please accept all required terms to continue',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canCompleteOnboarding {
    // Privacy and data processing consent are required
    // Emergency contact is optional
    return _privacyConsent && _dataProcessingConsent;
  }

  Widget _buildProgressDot(BuildContext context, {required bool isActive}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildConsentCheckbox(
    BuildContext context, {
    required String title,
    required String description,
    String? linkText,
    VoidCallback? onLinkTap,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (linkText != null && onLinkTap != null) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: linkText,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    // In a real app, open privacy policy URL or show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content would be displayed here. '
            'This should include detailed information about: '
            '- What data we collect '
            '- How we use your data '
            '- How we protect your data '
            '- Your rights regarding your data '
            '- How to contact us with questions',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    // Save consent status to Firestore
    // Mark onboarding as complete
    // Navigate to dashboard
    
    // For demo purposes, just navigate to dashboard
    context.go('/dashboard');
  }
}

import 'package:flutter/gestures.dart';
