import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../../auth/screens/login_screen.dart';
import '../admin_main_screen.dart';
import '../register_institute_screen.dart';

class SuperAdminPlatformScreen extends StatefulWidget {
  const SuperAdminPlatformScreen({super.key});

  @override
  State<SuperAdminPlatformScreen> createState() => _SuperAdminPlatformScreenState();
}

class _SuperAdminPlatformScreenState extends State<SuperAdminPlatformScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _allTenants = [];
  List<Map<String, dynamic>> _filteredTenants = [];
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  String _planFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadPlatformData();
  }

  Future<void> _loadPlatformData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.getSuperAdminStats();
      if (mounted) {
        final rawList = data['coaching_centers'] as List<dynamic>? ?? [];
        final list = rawList.cast<Map<String, dynamic>>();
        setState(() {
          _stats = data;
          _allTenants = list;
          _applyFilters();
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

  void _applyFilters() {
    setState(() {
      _filteredTenants = _allTenants.where((t) {
        final q = _searchQuery.toLowerCase();
        final name = (t['institute_name'] ?? t['tenant_name'] ?? '').toString().toLowerCase();
        final code = (t['tenant_code'] ?? '').toString().toLowerCase();
        final admin = (t['admin_name'] ?? '').toString().toLowerCase();
        final email = (t['email'] ?? '').toString().toLowerCase();
        final matchesSearch = q.isEmpty || name.contains(q) || code.contains(q) || admin.contains(q) || email.contains(q);

        final status = (t['status'] ?? '').toString().toUpperCase();
        final matchesStatus = _statusFilter == 'ALL' || status == _statusFilter;

        final isMulti = t['is_multi_branch'] == true || (t['branch_count'] ?? 1) > 1;
        final matchesPlan = _planFilter == 'ALL' ||
            (_planFilter == 'MULTI' && isMulti) ||
            (_planFilter == 'SINGLE' && !isMulti);

        return matchesSearch && matchesStatus && matchesPlan;
      }).toList();
    });
  }

  void _openPlanAndStatusModal(Map<String, dynamic> tenant) {
    final tenantId = int.tryParse((tenant['tenant_id'] ?? 0).toString()) ?? 0;
    String currentStatus = (tenant['status'] ?? 'ACTIVE').toString().toUpperCase();
    bool isMulti = tenant['is_multi_branch'] == true || (tenant['branch_count'] ?? 1) > 1;
    final branchNameCtrl = TextEditingController(text: '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manage Coaching Center',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textHeading,
                              ),
                            ),
                            Text(
                               tenant['institute_name'] ?? '',
                              style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Selector
                    Text('Center Status', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: currentStatus,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.shield_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Full Access)')),
                        DropdownMenuItem(value: 'TRIAL', child: Text('TRIAL (14-Day Evaluation)')),
                        DropdownMenuItem(value: 'SUSPENDED', child: Text('SUSPENDED (Locked)')),
                      ],
                      onChanged: (val) => setModalState(() => currentStatus = val ?? 'ACTIVE'),
                    ),
                    const SizedBox(height: 20),

                    // Multi-Branch Plan Tier Configuration
                    Text('Subscription & Branch License Plan', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMulti ? AppTheme.electricCobalt : (isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle),
                        ),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Enable Multi-Branch Enterprise Tier',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              isMulti
                                  ? 'Center can create and manage multiple campus branches.'
                                  : 'Center operates strictly on a single campus branch.',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: isMulti,
                            onChanged: (val) => setModalState(() => isMulti = val),
                          ),
                          if (isMulti && (tenant['branch_count'] ?? 1) <= 1) ...[
                            const Divider(height: 20),
                            TextField(
                              controller: branchNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Add 2nd Campus Branch Name',
                                hintText: 'e.g. South City Campus',
                                prefixIcon: const Icon(Icons.add_business_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(modalCtx);
                          final payload = <String, dynamic>{
                            'status': currentStatus,
                            if (isMulti && (tenant['branch_count'] ?? 1) <= 1) ...{
                              'create_branch': true,
                              'branch_name': branchNameCtrl.text.trim(),
                            },
                          };
                          final ok = await ApiService.updateTenantStatus(tenantId, payload);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Coaching Center settings updated!' : 'Update failed'),
                                backgroundColor: ok ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                            _loadPlatformData();
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)], // Flame Gradient
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'FLAME PLATFORM',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Super Admin Command Center',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Coaching Center Operations View',
            icon: const Icon(Icons.dashboard_outlined, color: AppTheme.electricCobalt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminMainScreen()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ThemeToggleSwitch(),
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.urgentText),
            onPressed: () {
              ApiService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterInstituteScreen()),
          );
          if (res == true) _loadPlatformData();
        },
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Coaching Center'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadPlatformData, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlatformData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Platform Overview Hero Cards
                        _buildPlatformMetricGrid(isDark),
                        const SizedBox(height: 24),

                        // Coaching Center Roster Title & Filter Bar
                        _buildRosterHeader(isDark),
                        const SizedBox(height: 14),

                        // Coaching Center List Cards
                        if (_filteredTenants.isEmpty)
                          _buildEmptyState(isDark)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredTenants.length,
                            itemBuilder: (context, index) {
                              return _buildTenantCard(_filteredTenants[index], isDark);
                            },
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPlatformMetricGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 14)) / crossAxisCount;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metricCard(
              width: itemWidth,
              isDark: isDark,
              title: 'Coaching Centers',
              value: '${_stats['total_coaching_centers'] ?? 0}',
              subtitle: '${_stats['active_institutes'] ?? 0} Active Institutes',
              icon: Icons.corporate_fare_rounded,
              gradientColors: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
            ),
            _metricCard(
              width: itemWidth,
              isDark: isDark,
              title: 'Total Campuses',
              value: '${_stats['total_campuses'] ?? 0}',
              subtitle: 'Branches Across Centers',
              icon: Icons.storefront_rounded,
              gradientColors: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
            ),
            _metricCard(
              width: itemWidth,
              isDark: isDark,
              title: 'Platform Students',
              value: '${_stats['total_students'] ?? 0}',
              subtitle: 'Active Enrolled Learners',
              icon: Icons.groups_rounded,
              gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            _metricCard(
              width: itemWidth,
              isDark: isDark,
              title: 'Platform MRR',
              value: '${_stats['platform_mrr'] ?? ''}',
              subtitle: 'Monthly SaaS Volume',
              icon: Icons.monetization_on_rounded,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required double width,
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registered Coaching Centers',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textHeading,
                  ),
                ),
                Text(
                  'Oversee institutes, multi-branch licenses & activation status',
                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search & Filter controls
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search center, code, or owner...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                DropdownMenuItem(value: 'TRIAL', child: Text('Trial')),
                DropdownMenuItem(value: 'SUSPENDED', child: Text('Suspended')),
              ],
              onChanged: (val) {
                setState(() => _statusFilter = val ?? 'ALL');
                _applyFilters();
              },
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _planFilter,
              dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All Plans')),
                DropdownMenuItem(value: 'SINGLE', child: Text('Single-Campus')),
                DropdownMenuItem(value: 'MULTI', child: Text('Multi-Branch')),
              ],
              onChanged: (val) {
                setState(() => _planFilter = val ?? 'ALL');
                _applyFilters();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant, bool isDark) {
    final status = (tenant['status'] ?? 'ACTIVE').toString().toUpperCase();
    final isActive = status == 'ACTIVE';
    final isTrial = status == 'TRIAL';
    final isMulti = tenant['is_multi_branch'] == true || (tenant['branch_count'] ?? 1) > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.4),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkAcademicBg : AppTheme.academicBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          (tenant['institute_name'] ?? '').toString().isNotEmpty ? tenant['institute_name'].toString()[0].toUpperCase() : '',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.electricCobalt,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant['institute_name'] ?? tenant['tenant_name'] ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textHeading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              tenant['tenant_code'] ?? '',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.electricCobalt,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Registered: ${tenant['created_at'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'manage') {
                      _openPlanAndStatusModal(tenant);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 18, color: AppTheme.electricCobalt),
                          SizedBox(width: 8),
                          Text('Manage Plan & Status'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Metadata & Badges
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                // Plan Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isMulti
                        ? (isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF))
                        : (isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMulti ? AppTheme.electricCobalt : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMulti ? Icons.domain_rounded : Icons.store_rounded,
                        size: 14,
                        color: isMulti ? AppTheme.electricCobalt : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isMulti
                            ? 'Enterprise Multi-Branch (${tenant['branch_count']} Campuses)'
                            : 'Starter Single-Campus (1 Branch)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMulti ? AppTheme.electricCobalt : (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? AppTheme.darkSuccessBg : AppTheme.successBg)
                        : (isTrial
                            ? (isDark ? AppTheme.darkWarningBg : AppTheme.warningBg)
                            : (isDark ? AppTheme.darkUrgentBg : AppTheme.urgentBg)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? AppTheme.successText
                          : (isTrial ? AppTheme.warningText : AppTheme.urgentText),
                    ),
                  ),
                ),

                // Student Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${tenant['student_count'] ?? 0} Students',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contact Info
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  tenant['admin_name'] ?? '',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(width: 14),
                Icon(Icons.mail_outline_rounded, size: 14, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  tenant['email'] ?? '',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No Coaching Centers match the filter',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
