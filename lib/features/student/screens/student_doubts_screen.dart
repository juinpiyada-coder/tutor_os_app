import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/student_dashboard_service.dart';

class StudentDoubtsScreen extends StatefulWidget {
  const StudentDoubtsScreen({super.key});

  @override
  State<StudentDoubtsScreen> createState() => _StudentDoubtsScreenState();
}

class _StudentDoubtsScreenState extends State<StudentDoubtsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _doubts = [];
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadDoubts();
  }

  Future<void> _loadDoubts() async {
    setState(() => _isLoading = true);
    final data = await StudentDashboardService.getDoubts();
    if (mounted) {
      setState(() {
        _doubts = data;
        _isLoading = false;
      });
    }
  }

  void _showAskDoubtDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedSubject = 'Mathematics';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF7C3AED), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Ask Faculty a Doubt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  items: ['Mathematics', 'Physics', 'Chemistry', 'Biology'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSubject = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Topic / Question Title *',
                    hintText: 'e.g. Electric flux integration across cylinder',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Explanation / Step you are stuck on',
                    hintText: 'Provide details or equations where you need clarification...',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  await StudentDashboardService.askDoubt(
                    titleController.text.trim(),
                    descController.text.trim(),
                    subject: selectedSubject,
                  );
                  _loadDoubts();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Doubt posted to teacher portal! You will be notified once answered.'),
                      backgroundColor: AppTheme.successText,
                    ),
                  );
                }
              },
              child: const Text('Post Doubt'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoubtDetailModal(Map<String, dynamic> doubt) {
    final replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doubt['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Subject: ${doubt['subject'] ?? ''} • Status: ${doubt['status'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Conversation Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Question Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.canvasBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFE0E7FF),
                                child: Icon(Icons.person, size: 16, color: AppTheme.electricCobalt),
                              ),
                              const SizedBox(width: 8),
                              const Text('You (Student)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              Text(doubt['date'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            doubt['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                          ),
                          if (doubt['description'] != null && doubt['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(doubt['description'], style: const TextStyle(fontSize: 13, color: AppTheme.textBody, height: 1.4)),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Teacher Reply if present
                    if (doubt['teacher_reply'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFDCFCE7),
                                  child: Icon(Icons.verified, size: 16, color: AppTheme.successText),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  doubt['teacher'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.successText),
                                ),
                                const Spacer(),
                                const Text('Teacher Solution', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.successText)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              doubt['teacher_reply'],
                              style: const TextStyle(fontSize: 14, color: AppTheme.textHeading, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your doubt is in the faculty queue. A teacher will reply shortly.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Reply Field
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: replyController,
                        decoration: InputDecoration(
                          hintText: 'Type follow-up message...',
                          filled: true,
                          fillColor: AppTheme.canvasBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF7C3AED)),
                      onPressed: () async {
                        if (replyController.text.trim().isNotEmpty) {
                          final doubtId = int.tryParse((doubt['doubt_id'] ?? 1).toString()) ?? 1;
                          final msg = replyController.text.trim();
                          final messenger = ScaffoldMessenger.of(context);
                          replyController.clear();
                          Navigator.pop(ctx);
                          await StudentDashboardService.postDoubtReply(doubtId, msg);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Follow-up message sent!'),
                              backgroundColor: Color(0xFF7C3AED),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _doubts;
    if (_statusFilter == 'OPEN') {
      filtered = filtered.where((d) => (d['status'] ?? '') == 'OPEN').toList();
    } else if (_statusFilter == 'ANSWERED') {
      filtered = filtered.where((d) => (d['status'] ?? '') == 'ANSWERED').toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Ask a Doubt', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAskDoubtDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoubts,
        color: const Color(0xFF7C3AED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF581C87), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.level2Shadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'FACULTY DOUBT ASSISTANT',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ask Questions & Doubts',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Get instant direct answers and walkthroughs from your coaching mentors.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Filter Tabs
              Row(
                children: [
                  _buildFilterTab('All', 'All Doubts'),
                  const SizedBox(width: 8),
                  _buildFilterTab('OPEN', 'Unresolved / Open'),
                  const SizedBox(width: 8),
                  _buildFilterTab('ANSWERED', 'Answered'),
                ],
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text('No doubts found', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Tap "Ask a Doubt" below to ask your teachers anything.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    final isAnswered = (d['status'] ?? '') == 'ANSWERED';

                    return GestureDetector(
                      onTap: () => _showDoubtDetailModal(d),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isAnswered ? const Color(0xFFBBF7D0) : AppTheme.borderSubtle),
                          boxShadow: AppTheme.level1Shadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    d['subject'] ?? '',
                                    style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAnswered ? AppTheme.successBg : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    d['status'] ?? '',
                                    style: TextStyle(
                                      color: isAnswered ? AppTheme.successText : const Color(0xFFD97706),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              d['title'] ?? '',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Posted ${d['date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                const Spacer(),
                                const Text('Tap to view discussion →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                              ],
                            ),

                            if (isAnswered && d['teacher_reply'] != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_user_rounded, color: AppTheme.successText, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Teacher Response (${d['teacher'] ?? ''})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successText),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      d['teacher_reply'],
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textHeading, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String status, String label) {
    final isSelected = _statusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E8FF) : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : AppTheme.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF7C3AED) : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}
