import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/institute_header.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/theme_toggle_switch.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/today_schedule_widget.dart';
import '../services/admin_dashboard_service.dart';
import '../../../../core/network/api_service.dart';
import '../../auth/screens/login_screen.dart';
import 'operations/operations_screen.dart';

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
      return const Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        body: Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.canvasBackground,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.electricCobalt,
          onRefresh: _fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                
                // 1. App Bar Header Tier with Hamburger Drawer Menu & Dark/Light Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        if (widget.onOpenDrawer != null) {
                          widget.onOpenDrawer!();
                        } else {
                          Scaffold.of(context).openDrawer();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.menu_rounded, color: AppTheme.surfaceWhite, size: 22),
                      ),
                    ),
                    Row(
                      children: [
                        const ThemeToggleSwitch(width: 60, height: 30),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.refresh_rounded, color: Theme.of(context).iconTheme.color),
                          tooltip: 'Refresh',
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _fetchDashboardData();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded, color: Theme.of(context).iconTheme.color),
                          onPressed: () {},
                        ),
                        IconButton(
                          tooltip: 'Logout',
                          icon: const Icon(Icons.logout_rounded, color: AppTheme.urgentText),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Logout'),
                                content: const Text('Are you sure you want to log out of TutorOS?'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.urgentText,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ApiService.logout();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.electricCobalt,
                          child: Text(
                            ApiStyleFormat.getInitials('${ApiService.currentFirstName ?? ''} ${ApiService.currentLastName ?? ''}'),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                
                const SizedBox(height: 12),

                // 2. Hero Institute Profile Container
                const InstituteHeader(),

                const SizedBox(height: 16),

                // 3. Quick Actions
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
