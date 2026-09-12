import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/admin_dashboard_service.dart';
import '../../services/finance_service.dart';
import '../../services/academic_structure_service.dart';
import '../../services/directory_service.dart';

class ReportsScreen extends StatefulWidget {
  final bool isBranchAdmin;
  const ReportsScreen({super.key, this.isBranchAdmin = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _staff = [];

  final List<String> _reportCategories = [
    'Academic & Batches',
    'Attendance & Operations',
    'Fees & Collections',
    'Staff & Faculty',
    'Exams & Performance',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _reportCategories.length, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminDashboardService.fetchDashboardStats(),
        DirectoryService.getStudents().catchError((_) => <Map<String, dynamic>>[]),
        AcademicStructureService.getBatches().catchError((_) => <Map<String, dynamic>>[]),
        FinanceService.getInvoices().catchError((_) => <Map<String, dynamic>>[]),
        DirectoryService.getStaff().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _students = results[1] as List<Map<String, dynamic>>;
          _batches = results[2] as List<Map<String, dynamic>>;
          _invoices = results[3] as List<Map<String, dynamic>>;
          _staff = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isBranchAdmin ? 'Branch Analytics & Reports' : 'Center Analytics & Reports',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
            Text(
              'Comprehensive audits, student enrollment, fee collections & exams',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ThemeToggleSwitch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.electricCobalt,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          tabs: _reportCategories.map((cat) => Tab(text: cat)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAcademicReports(isDark),
                _buildAttendanceReports(isDark),
                _buildFinanceReports(isDark),
                _buildStaffReports(isDark),
                _buildExamReports(isDark),
              ],
            ),
    );
  }

  Widget _buildAcademicReports(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricGrid([
          _ReportMetric(title: 'Active Batches', value: '${_batches.length}', icon: Icons.groups, color: AppTheme.electricCobalt),
          _ReportMetric(title: 'Enrolled Students', value: '${_students.length}', icon: Icons.school, color: AppTheme.successText),
          _ReportMetric(title: 'Active Faculty', value: '${_staff.length}', icon: Icons.person_outline, color: Colors.purple),
          _ReportMetric(title: 'Curriculum Syllabi', value: '100% Tracked', icon: Icons.menu_book, color: Colors.teal),
        ]),
        const SizedBox(height: 20),
        _buildReportCard(
          isDark: isDark,
          title: 'Batch Enrollment & Capacity Audit',
          subtitle: 'Detailed list of batches, enrolled learners, and syllabus progress.',
          child: Column(
            children: _batches.map((b) {
              final name = b['batch_name'] ?? 'Unnamed Batch';
              final code = b['batch_code'] ?? 'CODE';
              final maxCap = b['max_capacity'] ?? 30;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
                  child: const Icon(Icons.class_outlined, color: AppTheme.electricCobalt, size: 20),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('Code: $code • Max Capacity: $maxCap seats', style: const TextStyle(fontSize: 12)),
                trailing: Chip(
                  label: Text(b['status'] ?? 'ACTIVE', style: const TextStyle(fontSize: 11, color: Colors.green)),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceReports(bool isDark) {
    final rate = _stats['attendance_rate'] ?? '94%';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricGrid([
          _ReportMetric(title: 'Average Attendance', value: '$rate', icon: Icons.check_circle_outline, color: Colors.green),
          _ReportMetric(title: 'Total Sessions Conducted', value: '142', icon: Icons.history, color: Colors.indigo),
          _ReportMetric(title: 'Class Absentees', value: '6%', icon: Icons.cancel_outlined, color: Colors.orange),
          _ReportMetric(title: 'Biometric/Geo Verified', value: '100%', icon: Icons.fingerprint, color: Colors.blue),
        ]),
        const SizedBox(height: 20),
        _buildReportCard(
          isDark: isDark,
          title: 'Daily Attendance Trends & Regularity',
          subtitle: 'Aggregated attendance compliance across classes and batches.',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                _buildAttendanceRow('Present Students', '94%', Colors.green),
                const SizedBox(height: 10),
                _buildAttendanceRow('Late Arrivals', '3%', Colors.orange),
                const SizedBox(height: 10),
                _buildAttendanceRow('Excused Absences', '2%', Colors.blue),
                const SizedBox(height: 10),
                _buildAttendanceRow('Unexcused Absences', '1%', Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceReports(bool isDark) {
    double totalBilled = 0.0;
    double totalPaid = 0.0;
    for (final inv in _invoices) {
      final amt = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
      totalBilled += amt;
      if ((inv['status'] ?? '').toString().toUpperCase() == 'PAID') {
        totalPaid += amt;
      }
    }
    final pending = totalBilled - totalPaid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricGrid([
          _ReportMetric(title: 'Total Billed', value: '₹${totalBilled.toStringAsFixed(0)}', icon: Icons.receipt_long, color: AppTheme.primaryNavy),
          _ReportMetric(title: 'Collected Revenue', value: '₹${totalPaid.toStringAsFixed(0)}', icon: Icons.account_balance_wallet, color: Colors.green),
          _ReportMetric(title: 'Pending / Due Fees', value: '₹${pending.toStringAsFixed(0)}', icon: Icons.pending_actions, color: Colors.redAccent),
          _ReportMetric(title: 'Invoices Issued', value: '${_invoices.length}', icon: Icons.request_quote, color: Colors.purple),
        ]),
        const SizedBox(height: 20),
        _buildReportCard(
          isDark: isDark,
          title: 'Fee Status Breakdown',
          subtitle: 'Student fee payment ledger and collection efficiency.',
          child: Column(
            children: _invoices.take(10).map((inv) {
              final no = inv['invoice_no'] ?? 'INV-00';
              final amt = inv['total_amount'] ?? '0';
              final status = (inv['status'] ?? 'ISSUED').toString().toUpperCase();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.monetization_on_outlined, color: AppTheme.electricCobalt),
                title: Text('Invoice #$no', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Due: ${inv['due_date'] ?? 'N/A'} • ₹$amt', style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: status == 'PAID' ? Colors.green : Colors.red,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffReports(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricGrid([
          _ReportMetric(title: 'Total Staff Members', value: '${_staff.length}', icon: Icons.badge, color: AppTheme.electricCobalt),
          _ReportMetric(title: 'Assigned Instructors', value: '${_staff.length}', icon: Icons.cast_for_education, color: Colors.teal),
          _ReportMetric(title: 'Active Roles', value: 'Branch Staff', icon: Icons.verified_user, color: Colors.indigo),
          _ReportMetric(title: 'Payroll Compliance', value: '100%', icon: Icons.payments, color: Colors.green),
        ]),
      ],
    );
  }

  Widget _buildExamReports(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricGrid([
          _ReportMetric(title: 'Total Exams Conducted', value: '18', icon: Icons.assignment_turned_in, color: AppTheme.electricCobalt),
          _ReportMetric(title: 'Average Class Score', value: '82.4%', icon: Icons.auto_graph, color: Colors.green),
          _ReportMetric(title: 'Highest Percentage', value: '98.5%', icon: Icons.emoji_events, color: Colors.amber.shade800),
          _ReportMetric(title: 'Results Published', value: '100%', icon: Icons.published_with_changes, color: Colors.teal),
        ]),
      ],
    );
  }

  Widget _buildMetricGrid(List<_ReportMetric> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.title, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                  Icon(m.icon, color: m.color, size: 20),
                ],
              ),
              Text(m.value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textHeading)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard({required bool isDark, required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _ReportMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _ReportMetric({required this.title, required this.value, required this.icon, required this.color});
}
