import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../features/admin/screens/directory/directory_screen.dart';
import '../../features/admin/screens/academics/academics_screen.dart';
import '../../features/admin/screens/operations/operations_screen.dart';
import '../../features/admin/screens/finance/finance_hub_screen.dart';
import '../../features/admin/screens/assessments/assessments_screen.dart';
import '../../features/admin/screens/communications/communications_screen.dart';
import '../../features/admin/screens/settings/settings_screen.dart';
import '../../features/admin/screens/directory/add_student_screen.dart';
import '../../features/admin/screens/directory/add_staff_screen.dart';
import '../../features/admin/screens/academics/add_batch_screen.dart';

class SearchResultItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class UniversalSearchModal extends StatefulWidget {
  const UniversalSearchModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => const UniversalSearchModal(),
    );
  }

  @override
  State<UniversalSearchModal> createState() => _UniversalSearchModalState();
}

class _UniversalSearchModalState extends State<UniversalSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Navigation',
    'Quick Actions',
    'Academics',
    'Finance',
    'People',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SearchResultItem> _getAllSearchIndex(BuildContext context) {
    return [
      // Navigation
      SearchResultItem(
        title: 'Students & Faculty Directory',
        subtitle: 'Manage all students, parents, teachers, and staff members',
        category: 'People',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0D9488),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
        },
      ),
      SearchResultItem(
        title: 'Academic Hub & Curriculum',
        subtitle: 'Manage subjects, chapters, topics, courses, and syllabus',
        category: 'Academics',
        icon: Icons.school_rounded,
        color: const Color(0xFF6366F1),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicsScreen()));
        },
      ),
      SearchResultItem(
        title: 'Batches & Class Sections',
        subtitle: 'View active batches, assign teachers and students',
        category: 'Academics',
        icon: Icons.groups_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicsScreen()));
        },
      ),
      SearchResultItem(
        title: 'Operations & Timetable',
        subtitle: 'Class scheduling, live sessions, daily attendance, room allocations',
        category: 'Navigation',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF0284C7),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsScreen()));
        },
      ),
      SearchResultItem(
        title: 'Fee Collection & Double-Entry Accounting',
        subtitle: 'Invoices, ledger payments, receipts, fee structures, accounting reports',
        category: 'Finance',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF059669),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceHubScreen()));
        },
      ),
      SearchResultItem(
        title: 'Exams, Tests & Question Bank',
        subtitle: 'Create examinations, MCQ question bank, grade submissions & results',
        category: 'Academics',
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFFEC4899),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentsScreen()));
        },
      ),
      SearchResultItem(
        title: 'Communications & Announcements',
        subtitle: 'Broadcast SMS, Email, WhatsApp notifications and live chat',
        category: 'Navigation',
        icon: Icons.campaign_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationsScreen()));
        },
      ),
      SearchResultItem(
        title: 'Institute Settings & Profile',
        subtitle: 'Coaching center configuration, branch management, academic year setup',
        category: 'Navigation',
        icon: Icons.settings_rounded,
        color: const Color(0xFF64748B),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
      ),

      // Quick Actions
      SearchResultItem(
        title: 'Enroll New Student',
        subtitle: 'Add student admission, parent details and assign initial batch',
        category: 'Quick Actions',
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF0D9488),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen()));
        },
      ),
      SearchResultItem(
        title: 'Add Teacher / Faculty',
        subtitle: 'Register new educator, designate subject specialty and role',
        category: 'Quick Actions',
        icon: Icons.badge_rounded,
        color: const Color(0xFF3B82F6),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStaffScreen()));
        },
      ),
      SearchResultItem(
        title: 'Create New Batch',
        subtitle: 'Setup timing, assign primary teacher and standard curriculum',
        category: 'Quick Actions',
        icon: Icons.group_add_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBatchScreen()));
        },
      ),
      SearchResultItem(
        title: 'Collect Fee Payment',
        subtitle: 'Record instant offline/online fee receipt and auto-generate invoice item',
        category: 'Quick Actions',
        icon: Icons.payments_rounded,
        color: const Color(0xFF10B981),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceHubScreen()));
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _getAllSearchIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = allItems.where((item) {
      final matchesQuery = _query.isEmpty ||
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: BoxDecoration(
          color: AppTheme.getSurfaceCard(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.getBorderSubtle(context), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCobalt.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded, color: AppTheme.electricCobalt, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextHeading(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search modules, students, batches, fees, exams...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.getTextMuted(context),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                      onChanged: (val) {
                        setState(() => _query = val);
                      },
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.getTextMuted(context)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: AppTheme.getTextMuted(context)),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppTheme.getBorderSubtle(context)),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.electricCobalt
                              : AppTheme.getSurfaceSubtle(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.electricCobalt
                                : AppTheme.getBorderSubtle(context),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.getTextBody(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Divider(height: 1, color: AppTheme.getBorderSubtle(context)),

            // Results List
            Flexible(
              child: filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.getTextMuted(context)),
                          const SizedBox(height: 12),
                          Text(
                            'No results found for "$_query"',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextHeading(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for Students, Batches, Fees, Attendance, or Exams',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.getTextMuted(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filteredItems.length,
                      separatorBuilder: (c, i) => Divider(
                        height: 1,
                        indent: 56,
                        color: AppTheme.getBorderSubtle(context).withValues(alpha: 0.5),
                      ),
                      itemBuilder: (ctx, idx) {
                        final item = filteredItems[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.getTextHeading(context),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.getSurfaceSubtle(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.getTextMuted(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppTheme.getTextMuted(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppTheme.getTextMuted(context),
                          ),
                          onTap: item.onTap,
                        );
                      },
                    ),
            ),

            // Footer Shortcut Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceSubtle(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildKeyboardKey('Ctrl + K / Search Bar', context),
                      const SizedBox(width: 8),
                      Text(
                        'Universal Quick Search',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${filteredItems.length} shortcuts',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardKey(String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.getBorderSubtle(context)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.getTextBody(context),
        ),
      ),
    );
  }
}
