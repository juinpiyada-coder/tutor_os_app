import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/platform_service.dart';

class SubscriptionBillingScreen extends StatefulWidget {
  const SubscriptionBillingScreen({super.key});

  @override
  State<SubscriptionBillingScreen> createState() => _SubscriptionBillingScreenState();
}

class _SubscriptionBillingScreenState extends State<SubscriptionBillingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subs = await PlatformService.getSubscriptions();
    final plans = await PlatformService.getPlans();
    final invoices = await PlatformService.getSubscriptionInvoices();

    if (mounted) {
      setState(() {
        _subscriptions = subs;
        _plans = plans;
        _invoices = invoices;
        _isLoading = false;
      });
    }
  }

  void _openPlanUpgradeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select a SaaS Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textHeading,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _plans.isEmpty
                    ? const Center(child: Text('No pricing plans found.'))
                    : ListView.builder(
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          final planId = int.tryParse(plan['plan_id']?.toString() ?? '0') ?? 0;
                          final planName = plan['plan_name'] ?? '';
                          final price = plan['monthly_price'] ?? '0';
                          final maxStudents = plan['max_students'] ?? '';
                          final maxStorage = plan['max_storage_mb'] ?? '1000';
                          final desc = plan['description'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
                              ),
                            ),
                            color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        planName,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '\$$price / mo',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.electricCobalt,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(desc, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.people_outline, size: 14, color: AppTheme.electricCobalt),
                                      const SizedBox(width: 4),
                                      Text('Up to $maxStudents Students', style: const TextStyle(fontSize: 11)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.cloud_outlined, size: 14, color: AppTheme.electricCobalt),
                                      const SizedBox(width: 4),
                                      Text('${(int.tryParse(maxStorage.toString()) ?? 1024) ~/ 1024} GB Storage', style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.electricCobalt,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        Navigator.pop(ctx);
                                        final success = await PlatformService.subscribePlan(planId: planId);
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text(success ? 'Subscribed to $planName!' : 'Subscription failed')),
                                          );
                                          _loadData();
                                        }
                                      },
                                      child: Text('Subscribe to $planName'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 0,
        title: Text(
          'SaaS Plan & Billing',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textHeading,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ThemeToggleSwitch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.electricCobalt,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card, size: 18), text: 'Active Plan'),
            Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Invoices History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivePlanTab(isDark),
                _buildInvoicesTab(isDark),
              ],
            ),
    );
  }

  Widget _buildActivePlanTab(bool isDark) {
    final activeSub = _subscriptions.isNotEmpty ? _subscriptions.first : null;
    final planName = activeSub?['plan_name'] ?? '';
    final price = activeSub?['monthly_price'] ?? '49.00';
    final status = activeSub?['status'] ?? 'ACTIVE';
    final startDate = activeSub?['start_date'] ?? '2026-01-01';
    final endDate = activeSub?['end_date'] ?? '2027-01-01';
    final maxStudents = activeSub?['max_students'] ?? 500;
    final maxStorage = activeSub?['max_storage_mb'] ?? 10240;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B44), Color(0xFF0051D5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricCobalt.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      planName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$$price / month',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Active cycle: $startDate  →  $endDate',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.electricCobalt,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openPlanUpgradeModal,
                    child: const Text('Upgrade / Change Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Resource Quotas & Usage',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 12),
          // Students quota
          _buildQuotaMeter(
            title: 'Enrolled Students',
            current: 128,
            max: int.tryParse(maxStudents.toString()) ?? 500,
            icon: Icons.school,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          // Storage quota
          _buildQuotaMeter(
            title: 'Cloud Document Storage',
            current: 2450,
            max: int.tryParse(maxStorage.toString()) ?? 10240,
            unit: 'MB',
            icon: Icons.cloud,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaMeter({
    required String title,
    required int current,
    required int max,
    String unit = '',
    required IconData icon,
    required bool isDark,
  }) {
    final double pct = (current / (max > 0 ? max : 1)).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.electricCobalt),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  '$current / $max $unit',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
              color: pct > 0.85 ? Colors.red : AppTheme.electricCobalt,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesTab(bool isDark) {
    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Subscription Invoices Found',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final invNo = inv['invoice_no'] ?? '';
        final total = inv['total_amount'] ?? inv['amount'] ?? '0';
        final date = inv['invoice_date'] ?? '';
        final status = inv['status'] ?? 'PAID';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
            ),
          ),
          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
              child: const Icon(Icons.receipt, color: AppTheme.electricCobalt),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invNo,
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '\$$total',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.electricCobalt),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Issued: $date', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'PAID' ? AppTheme.successBg : AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'PAID' ? AppTheme.successText : AppTheme.warningText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
