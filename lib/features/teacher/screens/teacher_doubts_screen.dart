import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/teacher_dashboard_service.dart';

class TeacherDoubtsScreen extends StatefulWidget {
  const TeacherDoubtsScreen({super.key});

  @override
  State<TeacherDoubtsScreen> createState() => _TeacherDoubtsScreenState();
}

class _TeacherDoubtsScreenState extends State<TeacherDoubtsScreen> {
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
    final list = await TeacherDashboardService.getDoubts();
    if (mounted) {
      setState(() {
        _doubts = list;
        _isLoading = false;
      });
    }
  }

  void _showAnswerDoubtModal(Map<String, dynamic> doubt) {
    final replyController = TextEditingController(text: doubt['teacher_reply'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_all_rounded, color: Color(0xFF7C3AED), size: 24),
                      SizedBox(width: 8),
                      Text('Resolve Student Doubt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),

              // Student Query Preview
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(doubt['student_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED))),
                        Text(doubt['date'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doubt['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: replyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Your Explanation & Mathematical Solution *',
                  hintText: 'Type clear step-by-step guidance or key theorem references...',
                  filled: true,
                  fillColor: AppTheme.canvasBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send Explanation to Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  if (replyController.text.trim().isNotEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final doubtId = int.tryParse(doubt['doubt_id'].toString()) ?? 401;

                    doubt['status'] = 'ANSWERED';
                    doubt['teacher_reply'] = replyController.text.trim();

                    await TeacherDashboardService.answerDoubt(
                      doubtId: doubtId,
                      replyText: replyController.text.trim(),
                    );

                    _loadDoubts();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Doubt marked as answered and delivered to student!'),
                        backgroundColor: AppTheme.successText,
                      ),
                    );
                  }
                },
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
                              'STUDENT QUERIES',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Doubt Resolution Hub',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Answer questions from your enrolled students and clarify tricky lecture topics.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
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

              // Filter Tabs
              Row(
                children: [
                  _buildFilterTab('All', 'All Doubts'),
                  const SizedBox(width: 8),
                  _buildFilterTab('OPEN', 'Pending (${_doubts.where((d) => d['status'] == 'OPEN').length})'),
                  const SizedBox(width: 8),
                  _buildFilterTab('ANSWERED', 'Resolved'),
                ],
              ),

              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.successText),
                      SizedBox(height: 12),
                      Text('No unresolved doubts in queue!', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('All student questions have been addressed.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
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
                    final isAnswered = d['status'] == 'ANSWERED';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isAnswered ? AppTheme.borderSubtle : const Color(0xFFFDE68A), width: isAnswered ? 1 : 1.5),
                        boxShadow: AppTheme.level1Shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(d['student_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAnswered ? AppTheme.successBg : AppTheme.warningBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  d['status'] ?? '',
                                  style: TextStyle(
                                    color: isAnswered ? AppTheme.successText : AppTheme.warningText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            d['title'] ?? '',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                          ),
                          const SizedBox(height: 6),
                          Text('Subject: ${d['subject'] ?? ''} • Posted ${d['date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),

                          if (isAnswered && d['teacher_reply'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your Reply:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successText)),
                                  const SizedBox(height: 4),
                                  Text(d['teacher_reply'], style: const TextStyle(fontSize: 13, color: AppTheme.textHeading)),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAnswered ? AppTheme.canvasBackground : const Color(0xFF7C3AED),
                              foregroundColor: isAnswered ? AppTheme.textHeading : Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(isAnswered ? Icons.edit_note_rounded : Icons.reply_rounded, size: 16),
                            label: Text(isAnswered ? 'Edit Explanation' : 'Write Solution & Resolve', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _showAnswerDoubtModal(d),
                          ),
                        ],
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
