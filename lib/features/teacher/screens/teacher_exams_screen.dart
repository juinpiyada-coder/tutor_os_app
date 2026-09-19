import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/teacher_dashboard_service.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final list = await TeacherDashboardService.getExams();
    if (mounted) {
      setState(() {
        _exams = list;
        _isLoading = false;
      });
    }
  }

  String _formatExamDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  void _showCreateExamModal() {
    final titleController = TextEditingController();
    final durController = TextEditingController(text: '60');
    final totalMarksController = TextEditingController(text: '100');
    final passMarksController = TextEditingController(text: '40');
    final syllabusController = TextEditingController();
    String selectedSubject = 'Physics';
    DateTime? selectedDate;

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
                        Icon(Icons.quiz_rounded, color: AppTheme.electricCobalt, size: 24),
                        SizedBox(width: 8),
                        Text('Create Online Exam / Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 20),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Exam Title *',
                    hintText: 'e.g. Mid-Term Physics Assessment 2026',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  decoration: InputDecoration(
                    labelText: 'Subject *',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  items: ['Physics', 'Mathematics', 'Chemistry', 'Biology'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSubject = val);
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration (Minutes)',
                          filled: true,
                          fillColor: AppTheme.canvasBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: totalMarksController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total Marks',
                          filled: true,
                          fillColor: AppTheme.canvasBackground,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: syllabusController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Syllabus & Topics Covered',
                    hintText: 'e.g. Mechanics, Optics, Circuit Laws...',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Select Exam Date'
                              : 'Exam Date: ${_formatExamDate(selectedDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedDate == null ? AppTheme.textMuted : AppTheme.textHeading,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                        child: const Text('Choose', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
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
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Publish Exam & Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (titleController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter an exam title.')));
                      return;
                    }
                    if (selectedDate == null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Please select an exam date.')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    await TeacherDashboardService.createExam(
                      title: titleController.text.trim(),
                      subject: selectedSubject,
                      batchId: 0,
                      date: _formatExamDate(selectedDate!),
                      durationMinutes: int.tryParse(durController.text.trim()) ?? 0,
                      totalMarks: int.tryParse(totalMarksController.text.trim()) ?? 0,
                      passMarks: int.tryParse(passMarksController.text.trim()) ?? 0,
                      syllabus: syllabusController.text.trim(),
                    );

                    _loadExams();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Exam created and scheduled in portal!'),
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

  void _showAddQuestionModal(Map<String, dynamic> exam) {
    final qTextController = TextEditingController();
    final opt1Controller = TextEditingController(text: 'Option A statement');
    final opt2Controller = TextEditingController(text: 'Option B statement');
    final opt3Controller = TextEditingController(text: 'Option C statement');
    final opt4Controller = TextEditingController(text: 'Option D statement');
    int correctIndex = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setQModalState) => Container(
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
                        Icon(Icons.add_circle_outline, color: AppTheme.electricCobalt, size: 22),
                        SizedBox(width: 8),
                        Text('Add MCQ Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 20),

                TextField(
                  controller: qTextController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Question Statement *',
                    hintText: 'Enter question text or formula statement...',
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Answer Options (Select the correct option radio)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 8),

                _buildOptionInput(opt1Controller, 1, correctIndex, (v) => setQModalState(() => correctIndex = v)),
                _buildOptionInput(opt2Controller, 2, correctIndex, (v) => setQModalState(() => correctIndex = v)),
                _buildOptionInput(opt3Controller, 3, correctIndex, (v) => setQModalState(() => correctIndex = v)),
                _buildOptionInput(opt4Controller, 4, correctIndex, (v) => setQModalState(() => correctIndex = v)),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Save Question to Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (qTextController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(content: Text('Please enter the question statement.')));
                      return;
                    }
                    Navigator.pop(ctx);
                    final examId = int.tryParse(exam['exam_id'].toString()) ?? 1;

                    final options = [
                      {'option_id': 1, 'option_text': opt1Controller.text.trim(), 'is_correct': correctIndex == 1},
                      {'option_id': 2, 'option_text': opt2Controller.text.trim(), 'is_correct': correctIndex == 2},
                      {'option_id': 3, 'option_text': opt3Controller.text.trim(), 'is_correct': correctIndex == 3},
                      {'option_id': 4, 'option_text': opt4Controller.text.trim(), 'is_correct': correctIndex == 4},
                    ];

                    await TeacherDashboardService.addQuestion(
                      examId: examId,
                      questionText: qTextController.text.trim(),
                      subject: exam['subject'] ?? '',
                      marks: 0,
                      options: options,
                    );

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Question successfully added to exam Question Bank!'),
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

  Widget _buildOptionInput(TextEditingController ctrl, int index, int currentCorrect, Function(int) onSelect) {
    final isCorrect = index == currentCorrect;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          RadioGroup<int>(
            groupValue: currentCorrect,
            onChanged: (v) {
              if (v != null) onSelect(v);
            },
            child: Radio<int>(
              value: index,
              activeColor: AppTheme.successText,
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Option $index ${isCorrect ? '(Correct Answer)' : ''}',
                filled: true,
                fillColor: isCorrect ? const Color(0xFFF0FDF4) : AppTheme.canvasBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isCorrect ? AppTheme.successText : AppTheme.borderSubtle),
                ),
              ),
            ),
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
        label: const Text('Create Exam / Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showCreateExamModal,
      ),
      body: RefreshIndicator(
        onRefresh: _loadExams,
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
                    colors: [Color(0xFF701A75), Color(0xFF86198F)],
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
                              'EXAM CREATOR & GRADES',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Online Exams & Questions',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Design online mock quizzes, manage MCQ question bank and inspect student attempts.',
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
                      child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exams.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final e = _exams[index];

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
                                  color: const Color(0xFFFDF4FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  e['subject'] ?? '',
                                  style: const TextStyle(color: Color(0xFF86198F), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  e['status'] ?? '',
                                  style: const TextStyle(color: AppTheme.successText, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            e['title'] ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Date: ${e['date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              Text('Duration: ${e['duration'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              Text('Max Marks: ${e['total_marks'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF86198F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.add_circle_outline, size: 16),
                                  label: const Text('Add Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  onPressed: () => _showAddQuestionModal(e),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: const BorderSide(color: AppTheme.borderSubtle),
                                ),
                                icon: const Icon(Icons.insights_rounded, size: 16, color: AppTheme.textHeading),
                                label: const Text('Results', style: TextStyle(color: AppTheme.textHeading, fontSize: 13)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Viewing student attempts for ${e['title']}...')),
                                  );
                                },
                              ),
                            ],
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
}
