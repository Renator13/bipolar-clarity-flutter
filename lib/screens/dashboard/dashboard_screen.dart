import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firestore_service.dart';
import '../../models/daily_metrics.dart';
import '../../models/mood_entry.dart';
import '../../utils/theme_config.dart';
import '../../services/auth_service.dart';

/// Main dashboard screen displaying mood overview, status light, and sleep metrics
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Daily metrics for current user
  DailyMetrics? _todayMetrics;
  
  // Recent mood entries
  List<MoodEntry> _recentEntries = [];
  
  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    _loadDashboardData();
  }

  /// Loads dashboard data from Firestore
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    
    if (authService.userModel != null) {
      final userId = authService.userModel!.id;
      
      // Load today's metrics
      _todayMetrics = await firestoreService.getLatestDailyMetrics(userId);
      
      // Load recent mood entries (last 7 days)
      _recentEntries = await firestoreService.getMoodEntries(
        userId: userId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      
      // Update last active timestamp
      await firestoreService.updateLastActive(userId);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating action button for quick check-in
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/check-in'),
        icon: const Icon(Icons.add),
        label: const Text('Check In'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading ? _buildLoadingState(context) : _buildDashboardContent(context),
      ),
    );
  }

  /// Builds loading state with progress indicator
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your dashboard...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main dashboard content
  Widget _buildDashboardContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting and date
            _buildHeader(context),
            
            const SizedBox(height: 24),
            
            // Status light indicator
            _buildStatusLight(context),
            
            const SizedBox(height: 24),
            
            // Quick stats cards
            _buildQuickStats(context),
            
            const SizedBox(height: 24),
            
            // Mood chart for the week
            _buildMoodChart(context),
            
            const SizedBox(height: 24),
            
            // Sleep metrics
            _buildSleepMetrics(context),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  /// Builds the header with greeting and current date
  Widget _buildHeader(BuildContext context) {
    final authService = context.read<AuthService>();
    final displayName = authService.userModel?.displayName ?? 'there';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $displayName',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getCurrentDateString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Returns formatted current date string
  String _getCurrentDateString() {
    final now = DateTime.now();
    return '${_getWeekday(now.weekday)}, ${_getMonth(now.month)} ${now.day}, ${now.year}';
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  /// Builds the status light indicator showing current mood state
  Widget _buildStatusLight(BuildContext context) {
    final currentMood = _todayMetrics?.averageMood ?? 5.0;
    final stabilityScore = _todayMetrics?.stabilityScore ?? 50;
    final riskLevel = _todayMetrics?.riskLevel ?? RiskLevel.low;
    
    // Calculate status color based on mood and stability
    Color statusColor = ThemeConfig.getMoodColor(currentMood.round());
    if (riskLevel == RiskLevel.high) {
      statusColor = Colors.red;
    } else if (riskLevel == RiskLevel.elevated) {
      statusColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.2),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Status light icon with glow effect
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _getMoodIcon(currentMood.round()),
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status text
          Text(
            ThemeConfig.getMoodStatus(currentMood.round()),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Stability score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Stability: '),
              Text(
                '$stabilityScore%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.getStabilityColor(stabilityScore),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Risk level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: riskLevel.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskLevel.color.withOpacity(0.5)),
            ),
            child: Text(
              riskLevel.label,
              style: TextStyle(
                color: riskLevel.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns appropriate icon for mood level
  IconData _getMoodIcon(int moodLevel) {
    if (moodLevel <= 2) return Icons.sentiment_very_dissatisfied;
    if (moodLevel <= 4) return Icons.sentiment_dissatisfied;
    if (moodLevel <= 6) return Icons.sentiment_neutral;
    if (moodLevel <= 8) return Icons.sentiment_satisfied;
    return Icons.sentiment_very_satisfied;
  }

  /// Builds quick stats cards (sleep, energy, etc.)
  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.bedtime,
            title: 'Sleep',
            value: '${(_todayMetrics?.totalSleepHours ?? 7).toStringAsFixed(1)}h',
            subtitle: 'Last night',
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.bolt,
            title: 'Energy',
            value: '${(_todayMetrics?.averageEnergy ?? 5).toStringAsFixed(1)}/10',
            subtitle: 'Avg today',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_today,
            title: 'Entries',
            value: '${_todayMetrics?.entryCount ?? 0}',
            subtitle: 'Today',
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  /// Builds a single stat card
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the mood chart showing weekly trend
  Widget _buildMoodChart(BuildContext context) {
    // Prepare data for the chart
    final moodData = _getWeeklyMoodData();
    
    if (moodData.isEmpty) {
      return _buildEmptyChartState(context);
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Mood Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/insights'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Text(
                            days[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                      interval: 2,
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: moodData,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      dotSize: 6,
                      dotColor: Theme.of(context).colorScheme.primary,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          Theme.of(context).colorScheme.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gets weekly mood data for chart
  List<FlSpot> _getWeeklyMoodData() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    
    // Create data for last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Find entries for this day
      final dayEntries = _recentEntries.where((entry) {
        final entryDate = entry.timestamp.toIso8601String().split('T')[0];
        return entryDate == dateStr;
      }).toList();
      
      if (dayEntries.isNotEmpty) {
        final avgMood = dayEntries.map((e) => e.moodLevel.value).reduce((a, b) => a + b) / dayEntries.length;
        spots.add(FlSpot((6 - i).toDouble(), avgMood));
      } else {
        spots.add(FlSpot((6 - i).toDouble(), 0)); // Placeholder for no data
      }
    }
    
    return spots;
  }

  /// Builds empty state for when there's no chart data
  Widget _buildEmptyChartState(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No mood data yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.push('/check-in'),
              child: const Text('Log Your First Check-In'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds sleep metrics section
  Widget _buildSleepMetrics(BuildContext context) {
    final sleepHours = _todayMetrics?.totalSleepHours ?? 0;
    final sleepQuality = _todayMetrics?.sleepQuality ?? 3;
    
    // Determine sleep status
    String sleepStatus;
    Color sleepColor;
    if (sleepHours >= 7 && sleepHours <= 9) {
      sleepStatus = 'Good';
      sleepColor = Colors.green;
    } else if (sleepHours >= 5) {
      sleepStatus = 'Fair';
      sleepColor = Colors.orange;
    } else {
      sleepStatus = 'Needs Attention';
      sleepColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bedtime, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sleep',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sleepColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sleepStatus,
                  style: TextStyle(
                    color: sleepColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Sleep duration
          Row(
            children: [
              Text(
                sleepHours > 0 ? sleepHours.toStringAsFixed(1) : '--',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text('hours'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sleep quality bar
          if (sleepHours > 0) ...[
            Row(
              children: [
                Text(
                  'Quality: ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                for (int i = 1; i <= 5; i++)
                  Icon(
                    i <= sleepQuality ? Icons.star : Icons.star_outline,
                    color: i <= sleepQuality ? Colors.amber : Colors.grey.shade300,
                    size: 20,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sleep recommendation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSleepRecommendation(sleepHours),
                      style: Theme.of(context).textTheme.bodySmall,
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

  /// Returns sleep recommendation based on hours
  String _getSleepRecommendation(double hours) {
    if (hours < 5) {
      return 'Your sleep is below recommended levels. Try to get at least 7 hours for better mood stability.';
    } else if (hours < 7) {
      return 'You\'re getting some rest, but aim for 7-9 hours for optimal mood management.';
    } else if (hours > 9) {
      return 'You\'re getting plenty of sleep. Excessive sleep can sometimes indicate mood episodes.';
    }
    return 'Great job maintaining healthy sleep patterns!';
  }
}
