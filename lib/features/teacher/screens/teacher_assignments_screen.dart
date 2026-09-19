import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/teacher_dashboard_service.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    final list = await TeacherDashboardService.getAssignments();
    final batches = await TeacherDashboardService.getBatches();
    if (mounted) {
      setState(() {
        _assignments = list;
        _batches = batches;
        _isLoading = false;
      });
    }
  }

  void _showCreateAssignmentModal() {
    final titleController = TextEditingController();
    final marksController = TextEditingController(text: '50');
    final descController = TextEditingController();
    final List<String> selectedAllowedTypes = ['PDF', 'Image (JPG/PNG)', 'DOCX', 'TXT'];
    String selectedSubject = 'Mathematics';
    int selectedBatch = _batches.isNotEmpty
        ? (int.tryParse(_batches.first['batch_id']?.toString() ?? '1') ?? 1)
        : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                        Icon(Icons.assignment_add, color: AppTheme.electricCobalt, size: 24),
                        SizedBox(width: 8),
                        Text('Create New Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 20),

                const Text('Subject & Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                          if (val != null) setModalState(() => selectedSubject = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: selectedBatch,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.canvasBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                        ),
                        items: (_batches.isEmpty
                            ? const <DropdownMenuItem<int>>[
                                DropdownMenuItem(value: 1, child: Text('No batches available')),
                              ]
                            : _batches.map<DropdownMenuItem<int>>((b) {
                                final id = int.tryParse(b['batch_id']?.toString() ?? '1') ?? 1;
                                return DropdownMenuItem(value: id, child: Text(b['batch_name'] ?? ''));
                              }).toList()),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedBatch = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Assignment Title *',
                    hintText: 'e.g. Electromagnetic Induction Problem Set #2',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: marksController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Marks *',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Assignment Instructions / Questions *',
                    hintText: 'Enter question problems or worksheet reference...',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),

                // Allowed File Types Section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.file_present_rounded, size: 18, color: AppTheme.electricCobalt),
                          SizedBox(width: 8),
                          Text(
                            'Allowed Submission File Types *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select file types students can submit:',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          {'key': 'PDF', 'label': 'PDF (.pdf)', 'icon': Icons.picture_as_pdf_rounded, 'color': const Color(0xFFEF4444)},
                          {'key': 'Image (JPG/PNG)', 'label': 'Image (.jpg, .png)', 'icon': Icons.image_rounded, 'color': const Color(0xFF10B981)},
                          {'key': 'DOCX', 'label': 'Document (.docx, .doc)', 'icon': Icons.description_rounded, 'color': const Color(0xFF3B82F6)},
                          {'key': 'TXT', 'label': 'Plain Text (.txt)', 'icon': Icons.text_snippet_rounded, 'color': const Color(0xFF8B5CF6)},
                        ].map((type) {
                          final isSelected = selectedAllowedTypes.contains(type['key']);
                          final color = type['color'] as Color;
                          return FilterChip(
                            selected: isSelected,
                            avatar: Icon(
                              type['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : color,
                            ),
                            label: Text(
                              type['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppTheme.textHeading,
                              ),
                            ),
                            selectedColor: AppTheme.electricCobalt,
                            backgroundColor: AppTheme.surfaceWhite,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle,
                              ),
                            ),
                            onSelected: (bool val) {
                              setModalState(() {
                                if (val) {
                                  if (!selectedAllowedTypes.contains(type['key'])) {
                                    selectedAllowedTypes.add(type['key'] as String);
                                  }
                                } else {
                                  if (selectedAllowedTypes.length > 1) {
                                    selectedAllowedTypes.remove(type['key']);
                                  }
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.publish_rounded, size: 20),
                  label: const Text('Publish Assignment to Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (titleController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter an assignment title.')));
                      return;
                    }
                    if (marksController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter total marks.')));
                      return;
                    }
                    Navigator.pop(ctx);

                    final dueDate = DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0];
                    await TeacherDashboardService.createAssignment(
                      title: titleController.text.trim(),
                      subject: selectedSubject,
                      batchId: selectedBatch,
                      totalMarks: int.tryParse(marksController.text.trim()) ?? 50,
                      dueDate: dueDate,
                      description: descController.text.trim(),
                      allowedFileTypes: selectedAllowedTypes,
                    );

                    _loadAssignments();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Assignment created with file type constraints!'),
                        backgroundColor: AppTheme.successText,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubmissionsModal(Map<String, dynamic> assignment) async {
    final assignmentId = int.tryParse(assignment['assignment_id'].toString()) ?? 201;
    final submissions = await TeacherDashboardService.getAssignmentSubmissions(assignmentId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSubModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('Max Marks: ${assignment['total_marks'] ?? ''} • ${submissions.length} Submissions', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),

              Expanded(
                child: submissions.isEmpty
                    ? const Center(child: Text('No submissions received yet.'))
                    : ListView.separated(
                        itemCount: submissions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final sub = submissions[idx];
                          final isGraded = sub['status'] == 'GRADED';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.canvasBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isGraded ? AppTheme.successBg : AppTheme.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(sub['student_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isGraded ? AppTheme.successBg : AppTheme.warningBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isGraded ? 'Score: ${sub['score']}/${assignment['total_marks']}' : 'PENDING GRADING',
                                        style: TextStyle(
                                          color: isGraded ? AppTheme.successText : AppTheme.warningText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(sub['submission_text'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                                if (sub['feedback'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text('Feedback: "${sub['feedback']}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.successText)),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.electricCobalt,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.grading_rounded, size: 16),
                                      label: Text(isGraded ? 'Update Grade' : 'Grade Submission', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        _showGradeDialog(sub, assignment, () {
                                          setSubModalState(() {
                                            sub['status'] = 'GRADED';
                                          });
                                          _loadAssignments();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGradeDialog(Map<String, dynamic> submission, Map<String, dynamic> assignment, VoidCallback onGraded) {
    final scoreController = TextEditingController(text: submission['score']?.toString() ?? '');
    final feedbackController = TextEditingController(text: submission['feedback']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Grade ${submission['student_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Marks (Out of ${assignment['total_marks']})',
                filled: true,
                fillColor: AppTheme.canvasBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Teacher Remarks / Feedback',
                filled: true,
                fillColor: AppTheme.canvasBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
            onPressed: () async {
              if (scoreController.text.trim().isNotEmpty) {
                Navigator.pop(c);
                final score = int.tryParse(scoreController.text.trim()) ?? 45;
                final subId = int.tryParse(submission['submission_id'].toString()) ?? 1;

                submission['score'] = score;
                submission['feedback'] = feedbackController.text.trim();

                await TeacherDashboardService.gradeSubmission(
                  submissionId: subId,
                  score: score,
                  feedback: feedbackController.text.trim(),
                );

                onGraded();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grade and feedback saved to database!'), backgroundColor: AppTheme.successText),
                  );
                }
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showCreateAssignmentModal,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignments,
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
                    colors: [Color(0xFF064E3B), Color(0xFF047857)],
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
                              'HOMEWORK & EVALUATION',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Assignments & Grading',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Publish homework sets, review submitted work and enter scores with remarks.',
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
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_assignments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text('No assignments created yet', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Tap "Create Assignment" below to publish one to your batch.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _assignments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final a = _assignments[index];

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
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  a['subject'] ?? '',
                                  style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Text('Due: ${a['due_date'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.urgentText)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            a['title'] ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                          ),
                          const SizedBox(height: 4),
                          Text(a['batch_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(height: 12),

                          // Submission Ratio Bar
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.canvasBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatMetric('Submitted', '${a['submitted_count'] ?? 0} / ${a['total_students'] ?? 0}'),
                                _buildStatMetric('Pending Grading', '${a['pending_grading'] ?? 0}'),
                                _buildStatMetric('Max Marks', '${a['total_marks'] ?? ''}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Allowed Formats Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF047857).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.file_upload_outlined, size: 14, color: Color(0xFF047857)),
                                const SizedBox(width: 6),
                                const Text('Allowed Formats: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                Expanded(
                                  child: Text(
                                    (a['allowed_file_types'] is List)
                                        ? (a['allowed_file_types'] as List).join(' • ')
                                        : (a['allowed_file_types']?.toString() ?? 'PDF • JPG/PNG • DOCX • TXT'),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textHeading),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.grading_rounded, size: 18),
                            label: const Text('Inspect & Grade Submissions', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _showSubmissionsModal(a),
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

  Widget _buildStatMetric(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}
