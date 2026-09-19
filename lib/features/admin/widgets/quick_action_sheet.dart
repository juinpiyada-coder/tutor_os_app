import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/directory/add_student_screen.dart';
import '../screens/directory/add_staff_screen.dart';
import '../screens/academics/add_batch_screen.dart';
import '../screens/academics/add_subject_screen.dart';
import '../screens/operations/operations_screen.dart';
import '../screens/finance/finance_hub_screen.dart';
import '../screens/assessments/assessments_screen.dart';
import '../screens/communications/communications_screen.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppTheme.level3Shadow,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCobalt.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: AppTheme.electricCobalt, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions Bar',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextHeading(context),
                        ),
                      ),
                      Text(
                        'Instant center management actions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid of Quick Actions
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: [
              _QuickActionItem(
                icon: Icons.person_add_rounded,
                label: 'Add Student',
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.class_outlined,
                label: 'Create Batch',
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBatchScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.payments_outlined,
                label: 'Collect Fee',
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceHubScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.how_to_reg_rounded,
                label: 'Attendance',
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.badge_outlined,
                label: 'Add Staff',
                color: const Color(0xFF0891B2),
                bgColor: const Color(0xFFECFEFF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStaffScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.menu_book_rounded,
                label: 'Add Subject',
                color: const Color(0xFF4F46E5),
                bgColor: const Color(0xFFEEF2FF),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSubjectScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.quiz_rounded,
                label: 'Create Test',
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentsScreen()));
                },
              ),
              _QuickActionItem(
                icon: Icons.campaign_rounded,
                label: 'Broadcast',
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunicationsScreen()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? color.withValues(alpha: 0.18) : bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextHeading(context),
            ),
          ),
        ],
      ),
    );
  }
}
