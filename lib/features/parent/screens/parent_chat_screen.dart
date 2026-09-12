import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/parent_dashboard_service.dart';

class ParentChatScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const ParentChatScreen({super.key, this.selectedChild});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  final List<Map<String, dynamic>> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final list = await ParentDashboardService.getMessages();
    if (mounted) {
      setState(() {
        _messages = list;
        _isLoading = false;
      });
    }
  }

  void _showApplyLeaveModal() {
    final reasonController = TextEditingController();
    DateTime fromDate = DateTime.now().add(const Duration(days: 1));
    DateTime toDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: AppTheme.electricCobalt, size: 22),
              SizedBox(width: 8),
              Text('Apply for Student Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reason for Absence *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Health illness, family function, out of town...',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: AppTheme.canvasBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderSubtle)),
                            child: Text('${fromDate.day}/${fromDate.month}/${fromDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('To Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: AppTheme.canvasBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderSubtle)),
                            child: Text('${toDate.day}/${toDate.month}/${toDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
              onPressed: () async {
                if (reasonController.text.trim().isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final reason = reasonController.text.trim();
                  Navigator.pop(ctx);

                  await ParentDashboardService.submitLeaveRequest(
                    studentId: 1,
                    reason: reason,
                    fromDate: '${fromDate.year}-${fromDate.month}-${fromDate.day}',
                    toDate: '${toDate.year}-${toDate.month}-${toDate.day}',
                  );

                  setState(() {
                    _leaveRequests.insert(0, {
                      'request_id': DateTime.now().millisecondsSinceEpoch,
                      'reason': reason,
                      'from_date': '${fromDate.day}/${fromDate.month}/${fromDate.year}',
                      'to_date': '${toDate.day}/${toDate.month}/${toDate.year}',
                      'days': '2 Days',
                      'status': 'PENDING',
                      'submitted_on': 'Today',
                      'approver': 'Class Mentor Review',
                    });
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Leave application submitted to mentor for review!'),
                      backgroundColor: AppTheme.successText,
                    ),
                  );
                }
              },
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Selector Header
        Container(
          color: AppTheme.surfaceWhite,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.electricCobalt,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.electricCobalt,
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.notifications_active_rounded, size: 18), text: 'Faculty Notices'),
              Tab(icon: Icon(Icons.event_busy_rounded, size: 18), text: 'Leave Applications'),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNoticesTab(),
                    _buildLeaveTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildNoticesTab() {
    return RefreshIndicator(
      onRefresh: _loadMessages,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = _messages[index];
          final isUnread = m['unread'] == true;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isUnread ? AppTheme.electricCobalt.withValues(alpha: 0.5) : AppTheme.borderSubtle),
              boxShadow: AppTheme.level1Shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFFEFF6FF),
                          child: Icon(Icons.person, size: 14, color: AppTheme.electricCobalt),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          m['sender'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.electricCobalt),
                        ),
                      ],
                    ),
                    Text(m['date'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  m['title'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                ),
                const SizedBox(height: 6),
                Text(
                  m['body'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textBody, height: 1.4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Apply for Leave of Absence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            onPressed: _showApplyLeaveModal,
          ),
          const SizedBox(height: 20),

          const Text('Leave Request History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _leaveRequests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = _leaveRequests[index];
              final isApproved = r['status'] == 'APPROVED';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${r['from_date']} - ${r['to_date']} (${r['days']})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved ? AppTheme.successBg : AppTheme.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r['status'],
                            style: TextStyle(
                              color: isApproved ? AppTheme.successText : AppTheme.warningText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Reason: ${r['reason']}', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                    const SizedBox(height: 6),
                    Text('Reviewed by: ${r['approver']}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
