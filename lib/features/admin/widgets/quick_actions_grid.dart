import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/academics/add_batch_screen.dart';
import '../screens/operations/operations_screen.dart';

import '../screens/finance/finance_hub_screen.dart';
import '../screens/assessments/assessments_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, 
              height: 16, 
              decoration: BoxDecoration(
                color: AppTheme.electricCobalt, 
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text('Quick Actions', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              context, 
              title: 'Finance & Fees', 
              icon: Icons.account_balance_wallet_outlined, 
              color: AppTheme.electricCobalt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FinanceHubScreen()),
                );
              },
            ),
            _buildActionCard(
              context, 
              title: 'Create Batch', 
              icon: Icons.class_outlined, 
              color: const Color(0xFF059669), // Emerald
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddBatchScreen()),
                );
              },
            ),
            _buildActionCard(
              context, 
              title: 'Schedule Class', 
              icon: Icons.event_available_outlined, 
              color: const Color(0xFFD97706), // Amber
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OperationsScreen()),
                );
              },
            ),
            _buildActionCard(
              context, 
              title: 'Assessments', 
              icon: Icons.assignment_outlined, 
              color: const Color(0xFF7C3AED), // Purple
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessmentsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textHeading,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
