import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/student_dashboard_service.dart';

class StudentStudyScreen extends StatefulWidget {
  final int initialTabIndex;
  const StudentStudyScreen({super.key, this.initialTabIndex = 0});

  @override
  State<StudentStudyScreen> createState() => _StudentStudyScreenState();
}

class _StudentStudyScreenState extends State<StudentStudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _doubts = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 3));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final matData = await StudentDashboardService.getStudyMaterials();
    final assignData = await StudentDashboardService.getAssignments();
    final doubtData = await StudentDashboardService.getDoubts();
    if (mounted) {
      setState(() {
        _materials = matData;
        _assignments = assignData;
        _doubts = doubtData;
        _isLoading = false;
      });
    }
  }

  void _showSubmitAssignmentDialog(Map<String, dynamic> assignment) {
    final textController = TextEditingController();
    final linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.surfaceSubtle, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.upload_file_rounded, color: AppTheme.electricCobalt, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Submit Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Subject: ${assignment['subject'] ?? ''} • Max Marks: ${assignment['total_marks'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),

              // Allowed Formats Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.canvasBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.electricCobalt),
                        SizedBox(width: 6),
                        Text('Accepted Submission File Formats:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (assignment['allowed_file_types'] is List)
                          ? (assignment['allowed_file_types'] as List).join(' • ')
                          : (assignment['allowed_file_types']?.toString() ?? 'PDF (.pdf) • Image (.jpg, .png) • DOCX (.docx) • Plain Text (.txt)'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.electricCobalt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Solution / Answer Text *',
                  hintText: 'Enter your typed responses, explanations or numerical workings...',
                  filled: true,
                  fillColor: AppTheme.canvasBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: 'Attachment Link / File URL (Optional)',
                  hintText: 'e.g. https://drive.google.com/.../solution.pdf or .jpg / .docx / .txt',
                  prefixIcon: const Icon(Icons.attach_file_rounded, size: 18),
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
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (textController.text.trim().isEmpty) {
                messenger.showSnackBar(const SnackBar(content: Text('Please enter your solution before submitting.')));
                return;
              }

              final attachmentLink = linkController.text.trim().toLowerCase();
              if (attachmentLink.isNotEmpty) {
                final validExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.docx', '.doc', '.txt', 'drive.google.com', 'dropbox.com'];
                final hasValidFormat = validExtensions.any((ext) => attachmentLink.contains(ext));
                if (!hasValidFormat) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Allowed file formats are: PDF, JPG/PNG images, DOCX documents, or TXT files.'),
                      backgroundColor: AppTheme.urgentText,
                    ),
                  );
                  return;
                }
              }

              Navigator.pop(ctx);
              final assignmentId = int.tryParse((assignment['assignment_id'] ?? 1).toString()) ?? 1;
              await StudentDashboardService.submitAssignment(
                assignmentId,
                textController.text.trim(),
                attachmentUrl: linkController.text.trim().isNotEmpty ? linkController.text.trim() : null,
              );
              _loadData();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Assignment submitted successfully! Recorded in database.'),
                  backgroundColor: AppTheme.successText,
                ),
              );
            },
            child: const Text('Submit Solution'),
          ),
        ],
      ),
    );
  }

  void _showNewGeneralSubmissionDialog() {
    if (_assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active assignments found to submit.')),
      );
      return;
    }

    Map<String, dynamic> selectedAssign = _assignments.first;
    final textCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_task_rounded, color: AppTheme.electricCobalt, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Submit Homework / Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Assignment / Homework *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: selectedAssign,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  items: _assignments.map((a) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: a,
                      child: Text(
                        '${a['subject'] ?? ''} - ${a['title'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedAssign = val);
                  },
                ),
                const SizedBox(height: 12),

                // Allowed Formats Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.electricCobalt),
                          SizedBox(width: 6),
                          Text('Allowed Submission Formats:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (selectedAssign['allowed_file_types'] is List)
                            ? (selectedAssign['allowed_file_types'] as List).join(' • ')
                            : (selectedAssign['allowed_file_types']?.toString() ?? 'PDF (.pdf) • Image (.jpg, .png) • DOCX (.docx) • Plain Text (.txt)'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.electricCobalt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Your Homework Answer / Notes *',
                    hintText: 'Type your completed homework, answers or explanations here...',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkCtrl,
                  decoration: InputDecoration(
                    labelText: 'File / Drive URL (Optional)',
                    hintText: 'e.g. https://.../solution.pdf or .jpg / .docx / .txt',
                    prefixIcon: const Icon(Icons.attach_file_rounded, size: 18),
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
                backgroundColor: AppTheme.electricCobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (textCtrl.text.trim().isEmpty) {
                  messenger.showSnackBar(const SnackBar(content: Text('Please enter your homework answer before submitting.')));
                  return;
                }

                final attachmentLink = linkCtrl.text.trim().toLowerCase();
                if (attachmentLink.isNotEmpty) {
                  final validExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.docx', '.doc', '.txt', 'drive.google.com', 'dropbox.com'];
                  final hasValidFormat = validExtensions.any((ext) => attachmentLink.contains(ext));
                  if (!hasValidFormat) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Allowed file formats are: PDF, JPG/PNG images, DOCX documents, or TXT files.'),
                        backgroundColor: AppTheme.urgentText,
                      ),
                    );
                    return;
                  }
                }

                Navigator.pop(ctx);
                final assignmentId = int.tryParse((selectedAssign['assignment_id'] ?? 1).toString()) ?? 1;
                await StudentDashboardService.submitAssignment(
                  assignmentId,
                  textCtrl.text.trim(),
                  attachmentUrl: linkCtrl.text.trim().isNotEmpty ? linkCtrl.text.trim() : null,
                );
                _loadData();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Homework submitted successfully!'),
                    backgroundColor: AppTheme.successText,
                  ),
                );
              },
              child: const Text('Submit Homework'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAskDoubtDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
                const Text('Subject *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
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
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Topic / Question Title *',
                    hintText: 'e.g. Question on Newton Laws equation 3',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Explain your doubt / question in detail *',
                    hintText: 'Type your question or steps where you need guidance...',
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
                if (titleCtrl.text.trim().isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  await StudentDashboardService.askDoubt(
                    titleCtrl.text.trim(),
                    descCtrl.text.trim(),
                    subject: selectedSubject,
                  );
                  _loadData();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Doubt posted to faculty portal! You will receive response here.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Learning Hub'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Submit Homework / Task',
            icon: const Icon(Icons.add_task_rounded, color: AppTheme.electricCobalt),
            onPressed: _showNewGeneralSubmissionDialog,
          ),
          IconButton(
            tooltip: 'Ask Doubt',
            icon: const Icon(Icons.contact_support_rounded, color: Color(0xFF7C3AED)),
            onPressed: _showAskDoubtDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_rounded, size: 18), text: 'Lessons'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'Study Materials'),
            Tab(icon: Icon(Icons.assignment_turned_in_rounded, size: 18), text: 'Assignments'),
            Tab(icon: Icon(Icons.forum_rounded, size: 18), text: 'My Doubts'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Submit Homework / Ask Doubt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () {
          if (_tabController.index == 3) {
            _showAskDoubtDialog();
          } else {
            _showNewGeneralSubmissionDialog();
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildMaterialsTab(),
                _buildAssignmentsTab(),
                _buildDoubtsTab(),
              ],
            ),
    );
  }

  Widget _buildLessonsTab() {
    final lessons = [
      {
        'title': 'Limits & Differential Calculus',
        'subject': 'Mathematics',
        'chapter': 'Chapter 4: Calculus Foundations',
        'progress': '80% Completed',
        'topics': 'Continuity, Derivatives, Chain Rule',
        'status': 'ACTIVE',
      },
      {
        'title': 'Electromagnetism & Gauss Law',
        'subject': 'Physics',
        'chapter': 'Chapter 2: Electrostatics',
        'progress': '65% Completed',
        'topics': 'Electric Flux, Spherical Shells, Dipoles',
        'status': 'ACTIVE',
      },
      {
        'title': 'Chemical Bonding & Hybridization',
        'subject': 'Chemistry',
        'chapter': 'Chapter 3: Molecular Structure',
        'progress': '90% Completed',
        'topics': 'VSEPR, sp3 Hybridization, Dipole Moments',
        'status': 'COMPLETED',
      },
      {
        'title': 'Cell Cycle & Genetics',
        'subject': 'Biology',
        'chapter': 'Chapter 5: Cytology',
        'progress': '50% Completed',
        'topics': 'Mitosis, Meiosis, Mendelian Ratios',
        'status': 'ACTIVE',
      },
    ];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: lessons.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final l = lessons[index];
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l['subject'] ?? '',
                        style: const TextStyle(color: AppTheme.electricCobalt, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l['progress'] ?? '',
                        style: const TextStyle(color: AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l['title'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                ),
                const SizedBox(height: 4),
                Text(
                  l['chapter'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bookmark_border_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Topics: ${l['topics']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoubtsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _doubts.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF581C87), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.level2Shadow,
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('FACULTY DOUBT DESK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.help_center_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Have a Question or Doubts?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Post questions directly to your subject teachers and get verified step-by-step solutions.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF581C87),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_comment_rounded, size: 18),
                    label: const Text('+ Ask Faculty a New Doubt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _showAskDoubtDialog,
                  ),
                ],
              ),
            );
          }
          final d = _doubts[index - 1];
                final isSolved = (d['status'] ?? '').toString().toUpperCase() == 'SOLVED' || (d['teacher_reply'] != null && d['teacher_reply'].toString().isNotEmpty);
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
                          Text(d['subject'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt, fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSolved ? AppTheme.successBg : AppTheme.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSolved ? 'Answered' : 'Open',
                              style: TextStyle(
                                color: isSolved ? AppTheme.successText : AppTheme.warningText,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(d['title'] ?? 'Doubt Query', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (d['teacher_reply'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text('Faculty Answer: ${d['teacher_reply']}', style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMaterialsTab() {
    final filtered = _selectedCategory == 'All'
        ? _materials
        : _materials.where((m) => (m['subject'] ?? '').toString().toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
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
                  colors: [Color(0xFF312E81), Color(0xFF4338CA)],
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
                            'STUDY VAULT',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Study Materials & Notes',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Download cheat sheets, lecture PDFs, diagrams, and revision modules.',
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
                    child: const Icon(Icons.folder_special_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Subject Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Mathematics', 'Physics', 'Chemistry', 'Biology'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF4338CA),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textBody,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      backgroundColor: AppTheme.surfaceWhite,
                      side: BorderSide(color: isSelected ? const Color(0xFF4338CA) : AppTheme.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    const Text('No study materials found', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Materials for this subject will be published by faculty soon.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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
                  final m = filtered[index];
                  final fileType = (m['file_type'] ?? '').toString().toUpperCase();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                      boxShadow: AppTheme.level1Shadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: fileType == 'PDF' 
                                ? const Color(0xFFFEE2E2) 
                                : (fileType == 'PNG' || fileType == 'JPG' ? const Color(0xFFE0E7FF) : const Color(0xFFFEF3C7)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              fileType,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: fileType == 'PDF' 
                                    ? const Color(0xFFDC2626) 
                                    : (fileType == 'PNG' || fileType == 'JPG' ? const Color(0xFF4338CA) : const Color(0xFFD97706)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['title'] ?? '',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(m['subject'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA))),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                                  const SizedBox(width: 8),
                                  Text(m['size'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                                  const SizedBox(width: 8),
                                  Text(m['date'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download_rounded, color: Color(0xFF4338CA)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading ${m['title']}...'),
                                backgroundColor: const Color(0xFF312E81),
                              ),
                            );
                          },
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
    );
  }

  Widget _buildAssignmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _assignments.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.level2Shadow,
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('ASSIGNMENTS & HOMEWORK', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Homework & Task Submissions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Submit your homework solutions, upload project drive links and check teacher evaluations.', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('+ Submit New Homework / Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _showNewGeneralSubmissionDialog,
                  ),
                ],
              ),
            );
          }

          final a = _assignments[index - 1];
          final isPending = (a['status'] ?? '') == 'PENDING';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isPending ? AppTheme.warningText.withValues(alpha: 0.4) : AppTheme.borderSubtle),
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
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a['subject'] ?? '',
                        style: const TextStyle(color: AppTheme.electricCobalt, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending ? AppTheme.warningBg : AppTheme.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a['status'] ?? '',
                        style: TextStyle(
                          color: isPending ? AppTheme.warningText : AppTheme.successText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  a['title'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                ),
                const SizedBox(height: 6),
                if (a['description'] != null)
                  Text(
                    a['description'],
                    style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.alarm_rounded, size: 14, color: AppTheme.urgentText),
                    const SizedBox(width: 6),
                    Text('Due: ${a['due_date'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.urgentText)),
                    const Spacer(),
                    Text('Total Marks: ${a['total_marks'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                if (a['score'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.successBg, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.successText),
                        const SizedBox(width: 8),
                        Text('Grade: ${a['score']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successText, fontSize: 13)),
                        if (a['feedback'] != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('• ${a['feedback']}', style: const TextStyle(fontSize: 12, color: AppTheme.textBody), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending ? AppTheme.electricCobalt : AppTheme.canvasBackground,
                    foregroundColor: isPending ? Colors.white : AppTheme.textBody,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(isPending ? Icons.upload_file_rounded : Icons.check_circle_rounded, size: 18),
                  label: Text(isPending ? 'Submit Assignment Solution' : 'Resubmit / View Submission', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showSubmitAssignmentDialog(a),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
