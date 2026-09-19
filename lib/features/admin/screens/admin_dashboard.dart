import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/institute_header.dart';
import '../../../shared/widgets/metric_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/today_schedule_widget.dart';
import '../services/admin_dashboard_service.dart';
import 'operations/operations_screen.dart';
import '../../../core/widgets/universal_owner_header.dart';

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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final stats = await AdminDashboardService.fetchDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('Network error: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stats.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.getCanvasBackground(context),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.electricCobalt),
              SizedBox(height: 16),
              Text(
                'Loading Coaching Dashboard...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _stats.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.getCanvasBackground(context),
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceWhite,
          elevation: 0,
          title: const Text('Dashboard', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
          leading: widget.onOpenDrawer != null
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppTheme.textHeading),
                  onPressed: widget.onOpenDrawer,
                )
              : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.urgentBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, color: AppTheme.urgentText, size: 40),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Could not load dashboard data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchDashboardData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final studentsCount = (_stats['studentsCount'] ?? _stats['students_count'] ?? '0').toString();
    final studentsGrowth = _stats['studentsGrowth'] ?? '${_stats['batches_count'] ?? 0} active batches';
    final attendanceRate = _stats['attendanceRate'] ?? '${_stats['attendance_percentage'] ?? 0}%';
    final attendanceSummary = _stats['attendanceSummary'] ?? '${_stats['present_count'] ?? 0} present today';
    final feesOverdue = _stats['feesOverdue']?.split(' ')[0] ?? '₹${_stats['pending_fees'] ?? 0}';
    final alertsList = (_stats['alerts'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.getCanvasBackground(context),
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        onRefresh: _fetchDashboardData,
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
                        value: studentsCount,
                        icon: Icons.people_alt_outlined,
                        footerText: studentsGrowth,
                        isPositive: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        title: 'Attendance',
                        value: attendanceRate,
                        icon: Icons.co_present_outlined,
                        footerText: attendanceSummary,
                        isPositive: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        title: 'Fees Due',
                        value: feesOverdue,
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

                // 6. Recent Alerts
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.warningText, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Recent Alerts', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 12),
                if (alertsList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppTheme.successText, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All operational systems active. No urgent alerts.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...alertsList.map<Widget>((alert) {
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
                  }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
