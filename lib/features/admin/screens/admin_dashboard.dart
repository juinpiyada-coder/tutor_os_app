import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/institute_header.dart';
import '../../../shared/widgets/metric_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/today_schedule_widget.dart';
import '../services/admin_dashboard_service.dart';
import 'operations/operations_screen.dart';
import '../../../core/widgets/universal_owner_header.dart';
import '../../../core/network/api_service.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const AdminDashboard({super.key, this.onOpenDrawer});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final stats = await AdminDashboardService.fetchDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Missing Authorization') || errStr.contains('unauthorized') || errStr.contains('401')) {
        ApiService.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.getCanvasBackground(context),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.getCanvasBackground(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _fetchDashboardData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.getCanvasBackground(context),
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        onRefresh: () {
          setState(() => _isLoading = true);
          _fetchDashboardData();
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.electricCobalt,
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Institute Profile Container
                const InstituteHeader(),

                const SizedBox(height: 16),

                // 2. Quick Actions
                const QuickActionsGrid(),
                const SizedBox(height: 24),

                // 4. Primary KPI Snapshot Grid
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Students',
                        value: _stats['studentsCount'] ?? '0',
                        icon: Icons.people_alt_outlined,
                        footerText: _stats['studentsGrowth'] ?? '',
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        title: 'Attendance',
                        value: _stats['attendanceRate'] ?? '0%',
                        icon: Icons.co_present_outlined,
                        footerText: _stats['attendanceSummary'] ?? '',
                        isPositive: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        title: 'Fees Due',
                        value: _stats['feesOverdue']?.split(' ')[0] ?? '₹0',
                        icon: Icons.account_balance_wallet_outlined,
                        footerText: 'Pending',
                        isPositive: false,
                        isWarning: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 5. Today's Schedule
                TodayScheduleWidget(
                  schedules: _stats['schedules'] ?? [],
                  onViewAll: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OperationsScreen()),
                    );
                    _fetchDashboardData();
                  },
                ),
                
                const SizedBox(height: 24),

                // 6. Recent Alerts (Simplified logic based on alerts returned from API)
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.warningText, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Recent Alerts', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_stats['alerts'] ?? []).map<Widget>((alert) {
                  final isWarning = alert['type'] == 'warning';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isWarning ? AppTheme.warningBg : AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isWarning ? AppTheme.warningText.withValues(alpha: 0.5) : AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                          color: isWarning ? AppTheme.warningText : AppTheme.electricCobalt,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(alert['description'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
