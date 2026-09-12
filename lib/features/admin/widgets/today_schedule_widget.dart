import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/operations/operations_screen.dart';

class TodayScheduleWidget extends StatelessWidget {
  final List<dynamic> schedules;
  final VoidCallback? onViewAll;

  const TodayScheduleWidget({
    super.key,
    required this.schedules,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4, 
                  height: 16, 
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNavy, 
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Today\'s Schedule', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            TextButton(
              onPressed: onViewAll ?? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OperationsScreen()),
                );
              },
              child: const Text('View All', style: TextStyle(color: AppTheme.electricCobalt)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (schedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Center(
              child: Text(
                'No classes scheduled for today.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return _buildScheduleItem(
                context,
                time: schedule['time'] ?? '',
                subject: schedule['subject'] ?? '',
                batch: schedule['batch'] ?? '',
                status: schedule['status'] ?? '',
              );
            },
          ),
      ],
    );
  }

  Widget _buildScheduleItem(
    BuildContext context, {
    required String time,
    required String subject,
    required String batch,
    required String status,
  }) {
    final isCompleted = status.toLowerCase() == 'completed';
    final isLive = status.toLowerCase() == 'live';

    Color statusColor = AppTheme.textMuted;
    if (isCompleted) statusColor = AppTheme.successText;
    if (isLive) statusColor = AppTheme.urgentText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          // Time Column
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
          
          // Divider Line
          Container(
            height: 40,
            width: 2,
            color: isLive ? AppTheme.urgentText : AppTheme.borderSubtle,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  batch,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          )
        ],
      ),
    );
  }
}
