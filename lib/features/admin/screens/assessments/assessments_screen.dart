import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/assessments_service.dart';
import '../../services/academics_service.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AssessmentsService.getExams(),
        AssessmentsService.getAssignments(),
        AssessmentsService.getQuestions(),
        AcademicsService.getBatches().catchError((_) => <Map<String, dynamic>>[]),
        AcademicsService.getSubjects().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _exams = results[0];
          _assignments = results[1];
          _questions = results[2];
          _batches = results[3];
          _subjects = results[4];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openExamFormModal({Map<String, dynamic>? existingExam}) {
    final isEditing = existingExam != null;
    final titleController = TextEditingController(text: existingExam?['title'] ?? '');
    final batchController = TextEditingController(text: existingExam?['batch_name'] ?? '');
    final marksController = TextEditingController(text: (existingExam?['total_marks'] ?? 100).toString());
    final passMarksController = TextEditingController(text: (existingExam?['pass_marks'] ?? 35).toString());
    final durationController = TextEditingController(text: (existingExam?['duration_minutes'] ?? 60).toString());
    final List<int> selectedQuestionIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Examination' : 'Create Examination / Test',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Exam Title',
                        hintText: 'e.g. Term 1 Physics Assessment',
                        prefixIcon: Icon(Icons.quiz_outlined, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_batches.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _batches.any((b) => b['batch_name'] == batchController.text) ? batchController.text : _batches.first['batch_name'],
                        decoration: const InputDecoration(
                          labelText: 'Target Batch',
                          prefixIcon: Icon(Icons.groups_outlined, color: AppTheme.electricCobalt),
                        ),
                        items: _batches.map((b) {
                          final name = b['batch_name'] ?? '';
                          return DropdownMenuItem<String>(value: name, child: Text(name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => batchController.text = val);
                        },
                      )
                    else
                      TextField(
                        controller: batchController,
                        decoration: const InputDecoration(
                          labelText: 'Target Batch',
                          prefixIcon: Icon(Icons.groups_outlined, color: AppTheme.electricCobalt),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: marksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Marks',
                              prefixIcon: Icon(Icons.grade_outlined, color: AppTheme.electricCobalt),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: passMarksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pass Marks',
                              prefixIcon: Icon(Icons.check_circle_outlined, color: AppTheme.electricCobalt),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (Minutes)',
                        prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!isEditing) ...[
                      // Section: Attach Questions from Question Bank
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, size: 18, color: AppTheme.electricCobalt),
                              const SizedBox(width: 6),
                              Text(
                                'Attach Questions (${selectedQuestionIds.length} Selected)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textHeading),
                              ),
                            ],
                          ),
                          if (_questions.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  if (selectedQuestionIds.length == _questions.length) {
                                    selectedQuestionIds.clear();
                                  } else {
                                    for (var q in _questions) {
                                      if (q['question_id'] != null) {
                                        selectedQuestionIds.add(int.parse(q['question_id'].toString()));
                                      }
                                    }
                                  }
                                });
                              },
                              child: Text(
                                selectedQuestionIds.length == _questions.length ? 'Deselect All' : 'Select All',
                                style: const TextStyle(fontSize: 12, color: AppTheme.electricCobalt),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_questions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.canvasBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Text(
                            'No questions in Question Bank yet. You can still publish this exam and link questions later.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: AppTheme.canvasBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _questions.length,
                            separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.borderSubtle),
                            itemBuilder: (context, i) {
                              final q = _questions[i];
                              final qId = int.tryParse((q['question_id'] ?? 0).toString()) ?? 0;
                              final isSelected = selectedQuestionIds.contains(qId);
                              final qMarks = q['marks'] ?? 2;

                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                activeColor: AppTheme.electricCobalt,
                                title: Text(
                                  q['question_text'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: AppTheme.textHeading,
                                  ),
                                ),
                                subtitle: Text(
                                  '${q['subject'] ?? ''} • ${q['question_type'] ?? ''} • $qMarks Marks',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      selectedQuestionIds.add(qId);
                                    } else {
                                      selectedQuestionIds.remove(qId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) return;
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter exam title')));
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        final payload = {
                          'title': titleController.text.trim(),
                          'batch_name': batchController.text.trim(),
                          'total_marks': int.tryParse(marksController.text) ?? 100,
                          'pass_marks': int.tryParse(passMarksController.text) ?? 35,
                          'duration_minutes': int.tryParse(durationController.text) ?? 60,
                        };

                        if (isEditing) {
                          final examId = int.tryParse((existingExam['exam_id'] ?? 1).toString()) ?? 1;
                          await AssessmentsService.updateExam(examId, payload);
                        } else {
                          final examId = await AssessmentsService.createExam(payload);
                          if (examId != null && selectedQuestionIds.isNotEmpty) {
                            final List<Map<String, dynamic>> mappedQuestions = [];
                            int seq = 1;
                            for (var qId in selectedQuestionIds) {
                              final match = _questions.firstWhere(
                                (item) => int.tryParse((item['question_id'] ?? 0).toString()) == qId,
                                orElse: () => {'marks': 2},
                              );
                              mappedQuestions.add({
                                'question_id': qId,
                                'question_sequence': seq++,
                                'marks': match['marks'] ?? 2,
                              });
                            }
                            await AssessmentsService.mapQuestionsToExam(
                              examId: examId,
                              questions: mappedQuestions,
                            );
                          }
                        }

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Exam updated successfully!' : 'Examination created and scheduled!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Update Examination' : 'Schedule & Publish Exam', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteExam(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Examination?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${exam['title']}"? All mapped questions and test sessions will be unlinked.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final examId = int.tryParse(exam['exam_id'].toString()) ?? 1;
              final success = await AssessmentsService.deleteExam(examId);
              if (mounted) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Exam deleted successfully.' : 'Exam removed.'),
                    backgroundColor: AppTheme.successText,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAssignment(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Assignment?'),
          ],
        ),
        content: Text('Are you sure you want to delete assignment "${a['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final assignId = int.tryParse(a['assignment_id'].toString()) ?? 1;
              final success = await AssessmentsService.deleteAssignment(assignId);
              if (mounted) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Assignment deleted successfully.' : 'Assignment removed.'),
                    backgroundColor: AppTheme.successText,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openManageExamQuestionsModal(Map<String, dynamic> exam) async {
    final examId = int.tryParse((exam['exam_id'] ?? 0).toString()) ?? 0;
    if (examId == 0) return;

    // Load currently mapped questions
    final currentMapped = await AssessmentsService.getExamQuestions(examId);
    final Set<int> selectedQuestionIds = currentMapped
        .map((m) => int.tryParse((m['question_id'] ?? 0).toString()) ?? 0)
        .where((id) => id > 0)
        .toSet();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                'Map Questions to Exam',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy),
                              ),
                              Text(
                                exam['title'] ?? '',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Questions (${selectedQuestionIds.length} Linked)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textHeading),
                        ),
                        if (_questions.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                if (selectedQuestionIds.length == _questions.length) {
                                  selectedQuestionIds.clear();
                                } else {
                                  for (var q in _questions) {
                                    if (q['question_id'] != null) {
                                      selectedQuestionIds.add(int.parse(q['question_id'].toString()));
                                    }
                                  }
                                }
                              });
                            },
                            child: Text(
                              selectedQuestionIds.length == _questions.length ? 'Deselect All' : 'Select All',
                              style: const TextStyle(fontSize: 12, color: AppTheme.electricCobalt),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_questions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.canvasBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Text('No questions found in Question Bank. Add some questions first!'),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: AppTheme.canvasBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _questions.length,
                          separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.borderSubtle),
                          itemBuilder: (context, i) {
                            final q = _questions[i];
                            final qId = int.tryParse((q['question_id'] ?? 0).toString()) ?? 0;
                            final isSelected = selectedQuestionIds.contains(qId);
                            final qMarks = q['marks'] ?? 2;

                            return CheckboxListTile(
                              value: isSelected,
                              dense: true,
                              activeColor: AppTheme.electricCobalt,
                              title: Text(
                                q['question_text'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: AppTheme.textHeading,
                                ),
                              ),
                              subtitle: Text(
                                '${q['subject'] ?? ''} • ${q['question_type'] ?? ''} • $qMarks Marks',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedQuestionIds.add(qId);
                                  } else {
                                    selectedQuestionIds.remove(qId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final List<Map<String, dynamic>> mappedQuestions = [];
                        int seq = 1;
                        for (var qId in selectedQuestionIds) {
                          final match = _questions.firstWhere(
                            (item) => int.tryParse((item['question_id'] ?? 0).toString()) == qId,
                            orElse: () => {'marks': 2},
                          );
                          mappedQuestions.add({
                            'question_id': qId,
                            'question_sequence': seq++,
                            'marks': match['marks'] ?? 2,
                          });
                        }

                        await AssessmentsService.mapQuestionsToExam(
                          examId: examId,
                          questions: mappedQuestions,
                          replace: true,
                        );

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Successfully updated ${mappedQuestions.length} mapped question(s)!')),
                        );
                      },
                      child: const Text('Save Mapped Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAssignmentFormModal({Map<String, dynamic>? existingAssignment}) {
    final isEditing = existingAssignment != null;
    final titleController = TextEditingController(text: existingAssignment?['title'] ?? '');
    final descController = TextEditingController(text: existingAssignment?['description'] ?? '');
    final batchController = TextEditingController(text: existingAssignment?['batch_name'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Assignment' : 'Post Assignment / Homework',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    hintText: 'e.g. Calculus Problems Chapter 4',
                    prefixIcon: Icon(Icons.assignment_outlined, color: AppTheme.electricCobalt),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchController,
                  decoration: const InputDecoration(
                    labelText: 'Target Batch',
                    prefixIcon: Icon(Icons.groups_outlined, color: AppTheme.electricCobalt),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instructions / Details',
                    hintText: 'Submit hand-written solutions in PDF format before next Tuesday.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    if (isEditing) {
                      final assignId = int.tryParse((existingAssignment['assignment_id'] ?? 1).toString()) ?? 1;
                      await AssessmentsService.updateAssignment(assignId, {
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                      });
                    } else {
                      await AssessmentsService.createAssignment({
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'batch_name': batchController.text.trim(),
                      });
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Assignment updated successfully!' : 'Assignment assigned to students!'),
                        backgroundColor: AppTheme.successText,
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Update Assignment' : 'Post Assignment', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openQuestionFormModal({Map<String, dynamic>? existingQuestion}) {
    final isEditing = existingQuestion != null;
    final questionTextController = TextEditingController(text: existingQuestion?['question_text'] ?? '');
    final subjectController = TextEditingController(text: existingQuestion?['subject'] ?? '');
    final marksController = TextEditingController(text: (existingQuestion?['marks'] ?? 2).toString());
    String questionType = existingQuestion?['question_type'] ?? 'MCQ';
    String difficulty = existingQuestion?['difficulty_level'] ?? (existingQuestion?['difficulty'] ?? 'MEDIUM');

    // 4 MCQ Option controllers
    final optAController = TextEditingController();
    final optBController = TextEditingController();
    final optCController = TextEditingController();
    final optDController = TextEditingController();
    int correctOptionIndex = 0;

    if (existingQuestion != null && existingQuestion['options'] is List) {
      final opts = existingQuestion['options'] as List;
      if (opts.isNotEmpty) {
        optAController.text = opts[0]['option_text'] ?? '';
        if (opts[0]['is_correct'] == true || opts[0]['is_correct'] == 1) correctOptionIndex = 0;
      }
      if (opts.length > 1) {
        optBController.text = opts[1]['option_text'] ?? '';
        if (opts[1]['is_correct'] == true || opts[1]['is_correct'] == 1) correctOptionIndex = 1;
      }
      if (opts.length > 2) {
        optCController.text = opts[2]['option_text'] ?? '';
        if (opts[2]['is_correct'] == true || opts[2]['is_correct'] == 1) correctOptionIndex = 2;
      }
      if (opts.length > 3) {
        optDController.text = opts[3]['option_text'] ?? '';
        if (opts[3]['is_correct'] == true || opts[3]['is_correct'] == 1) correctOptionIndex = 3;
      }
    }

    final descriptiveAnswerController = TextEditingController(text: existingQuestion?['correct_answer'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Question & Answers' : 'Add Question & Answers',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Type selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Multiple Choice (MCQ)')),
                            selected: questionType == 'MCQ',
                            selectedColor: AppTheme.electricCobalt,
                            labelStyle: TextStyle(
                              color: questionType == 'MCQ' ? Colors.white : AppTheme.textHeading,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => questionType = 'MCQ');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Descriptive / Short Ans')),
                            selected: questionType == 'DESCRIPTIVE',
                            selectedColor: AppTheme.electricCobalt,
                            labelStyle: TextStyle(
                              color: questionType == 'DESCRIPTIVE' ? Colors.white : AppTheme.textHeading,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => questionType = 'DESCRIPTIVE');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: questionTextController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Question Statement',
                        hintText: 'e.g. State Newton\'s second law of motion...',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.help_outline, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _subjects.isNotEmpty
                              ? DropdownButtonFormField<String>(
                                  initialValue: _subjects.any((s) => s['subject_name'] == subjectController.text) ? subjectController.text : _subjects.first['subject_name'],
                                  decoration: const InputDecoration(
                                    labelText: 'Subject',
                                    prefixIcon: Icon(Icons.menu_book_outlined, color: AppTheme.electricCobalt),
                                  ),
                                  items: _subjects.map<DropdownMenuItem<String>>((s) {
                                    final name = s['subject_name'] ?? '';
                                    return DropdownMenuItem<String>(value: name, child: Text(name));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => subjectController.text = val);
                                  },
                                )
                              : TextField(
                                  controller: subjectController,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject',
                                    prefixIcon: Icon(Icons.menu_book_outlined, color: AppTheme.electricCobalt),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: marksController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Marks',
                              prefixIcon: Icon(Icons.grade_outlined, color: AppTheme.electricCobalt),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty Level',
                        prefixIcon: Icon(Icons.speed, color: AppTheme.electricCobalt),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'EASY', child: Text('Easy')),
                        DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                        DropdownMenuItem(value: 'HARD', child: Text('Hard')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => difficulty = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (questionType == 'MCQ') ...[
                      const Text(
                        'Multiple Choice Options (Select the correct radio):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                      ),
                      const SizedBox(height: 8),
                      _buildOptionRow('Option A', optAController, 0, correctOptionIndex, (idx) {
                        setModalState(() => correctOptionIndex = idx);
                      }),
                      const SizedBox(height: 6),
                      _buildOptionRow('Option B', optBController, 1, correctOptionIndex, (idx) {
                        setModalState(() => correctOptionIndex = idx);
                      }),
                      const SizedBox(height: 6),
                      _buildOptionRow('Option C', optCController, 2, correctOptionIndex, (idx) {
                        setModalState(() => correctOptionIndex = idx);
                      }),
                      const SizedBox(height: 6),
                      _buildOptionRow('Option D', optDController, 3, correctOptionIndex, (idx) {
                        setModalState(() => correctOptionIndex = idx);
                      }),
                    ] else ...[
                      TextField(
                        controller: descriptiveAnswerController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Model / Correct Answer Key',
                          hintText: 'Enter the ideal answer or key grading points here...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (questionTextController.text.trim().isEmpty) return;

                        final optionsList = questionType == 'MCQ'
                            ? [
                                {'option_text': optAController.text.trim().isEmpty ? 'Option A' : optAController.text.trim(), 'is_correct': correctOptionIndex == 0},
                                {'option_text': optBController.text.trim().isEmpty ? 'Option B' : optBController.text.trim(), 'is_correct': correctOptionIndex == 1},
                                {'option_text': optCController.text.trim().isEmpty ? 'Option C' : optCController.text.trim(), 'is_correct': correctOptionIndex == 2},
                                {'option_text': optDController.text.trim().isEmpty ? 'Option D' : optDController.text.trim(), 'is_correct': correctOptionIndex == 3},
                              ]
                            : null;

                        final payload = {
                          'question_text': questionTextController.text.trim(),
                          'question_type': questionType,
                          'subject': subjectController.text.trim(),
                          'marks': int.tryParse(marksController.text) ?? 2,
                          'difficulty_level': difficulty,
                          'options': optionsList,
                          'correct_answer': descriptiveAnswerController.text.trim(),
                        };

                        final messenger = ScaffoldMessenger.of(context);
                        if (isEditing) {
                          final qId = int.tryParse(existingQuestion['question_id'].toString()) ?? 1;
                          await AssessmentsService.updateQuestion(qId, payload);
                        } else {
                          await AssessmentsService.createQuestionWithOptions(payload);
                        }

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Question updated successfully!' : 'Question and answer key saved to Question Bank!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Update Question' : 'Save to Question Bank', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteQuestion(Map<String, dynamic> q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Question?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${q['question_text']}" from the Question Bank?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final qId = int.tryParse(q['question_id'].toString()) ?? 1;
              final success = await AssessmentsService.deleteQuestion(qId);
              if (mounted) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Question deleted successfully.' : 'Question deleted from bank.'),
                    backgroundColor: AppTheme.successText,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, TextEditingController controller, int index, int selectedIndex, Function(int) onSelect) {
    final isSelected = selectedIndex == index;
    return Row(
      children: [
        RadioGroup<int>(
          groupValue: selectedIndex,
          onChanged: (val) {
            if (val != null) onSelect(val);
          },
          child: Radio<int>(
            value: index,
            activeColor: AppTheme.successText,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: isSelected
                  ? const Tooltip(
                      message: 'Marked Correct',
                      child: Icon(Icons.check_circle, color: AppTheme.successText, size: 20),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Assessments & Question Bank',
            style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.electricCobalt),
            onPressed: _loadData,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.fact_check), text: 'Exams & Tests'),
            Tab(icon: Icon(Icons.menu_book), text: 'Assignments'),
            Tab(icon: Icon(Icons.quiz), text: 'Question Bank'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExamsList(),
                _buildAssignmentsList(),
                _buildQuestionsList(),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.level3Shadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 0) {
              _openExamFormModal();
            } else if (_tabController.index == 1) {
              _openAssignmentFormModal();
            } else {
              _openQuestionFormModal();
            }
          },
          elevation: 0,
          backgroundColor: AppTheme.electricCobalt,
          foregroundColor: AppTheme.surfaceWhite,
          icon: const Icon(Icons.add),
          label: Text(_getFabLabel()),
        ),
      ),
    );
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 0:
        return 'Schedule Exam';
      case 1:
        return 'New Assignment';
      case 2:
      default:
        return 'Add Question & Ans';
    }
  }

  Widget _buildExamsList() {
    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No exams scheduled yet.', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final isCompleted = exam['status'] == 'COMPLETED';
        final isScheduled = exam['status'] == 'SCHEDULED';

        Color badgeColor = isCompleted ? AppTheme.successText : (isScheduled ? AppTheme.academicText : AppTheme.warningText);
        Color badgeBg = isCompleted ? AppTheme.successBg : (isScheduled ? AppTheme.academicBg : AppTheme.warningBg);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.level1Shadow,
            border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      exam['status'] ?? '',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(exam['batch_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
                  const SizedBox(width: 16),
                  const Icon(Icons.event_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(exam['exam_date'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.canvasBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Duration', '${exam['duration_minutes'] ?? 60} mins'),
                    _buildDivider(),
                    _buildStatItem('Max Marks', '${exam['total_marks'] ?? 100}'),
                    _buildDivider(),
                    _buildStatItem('Pass Mark', '${exam['pass_marks'] ?? 35}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.electricCobalt,
                      side: const BorderSide(color: AppTheme.electricCobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _openExamFormModal(existingExam: exam),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.urgentText,
                      side: const BorderSide(color: AppTheme.urgentText),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmDeleteExam(exam),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.playlist_add_check, size: 15),
                    label: const Text('Questions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _openManageExamQuestionsModal(exam),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsList() {
    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No assignments posted yet.', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final a = _assignments[index];
        final isEvaluated = a['status'] == 'EVALUATED';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.level1Shadow,
            border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      a['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEvaluated ? AppTheme.successBg : AppTheme.academicBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a['status'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEvaluated ? AppTheme.successText : AppTheme.academicText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(a['batch_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.urgentText),
                  const SizedBox(width: 4),
                  Text('Due: ${a['due_date'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.urgentText, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submissions: ${a['total_submissions'] ?? 0} / ${a['total_students'] ?? 30}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (((double.tryParse((a['total_submissions'] ?? 0).toString()) ?? 0)) /
                                ((double.tryParse((a['total_students'] ?? 30).toString()) ?? 30).clamp(1, 10000)))
                            .clamp(0.0, 1.0),
                        backgroundColor: AppTheme.borderSubtle.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricCobalt),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.electricCobalt,
                      side: const BorderSide(color: AppTheme.electricCobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _openAssignmentFormModal(existingAssignment: a),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.urgentText,
                      side: const BorderSide(color: AppTheme.urgentText),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmDeleteAssignment(a),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionsList() {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No questions added to Question Bank yet.', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final q = _questions[index];
        final isMcq = q['question_type'] == 'MCQ';
        final options = (q['options'] as List<dynamic>?) ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.level1Shadow,
            border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.academicBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          q['subject'] ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.academicText),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.surfaceSubtle, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isMcq ? 'MCQ (4 Options)' : 'Descriptive',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.successBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${q['marks'] ?? 2} Marks',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Question text
              Text(
                'Q${index + 1}. ${q['question_text'] ?? ''}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading, height: 1.3),
              ),
              const SizedBox(height: 12),

              // Options or answer key
              if (isMcq) ...[
                ...options.map((opt) {
                  final isCorrect = opt['is_correct'] == true || opt['is_correct'] == 1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCorrect ? AppTheme.successBg : AppTheme.canvasBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect ? AppTheme.successText.withValues(alpha: 0.5) : AppTheme.borderSubtle.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: isCorrect ? AppTheme.successText : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt['option_text'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                              color: isCorrect ? AppTheme.successText : AppTheme.textBody,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Text('Correct Ans',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successText)),
                      ],
                    ),
                  );
                }),
              ] else if (q['correct_answer'] != null && q['correct_answer'].toString().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.key_rounded, size: 16, color: AppTheme.successText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Answer Key: ${q['correct_answer']}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.successText, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 20),

              // Action Buttons Row: Edit and Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.electricCobalt,
                      side: const BorderSide(color: AppTheme.electricCobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _openQuestionFormModal(existingQuestion: q),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.urgentText,
                      side: const BorderSide(color: AppTheme.urgentText),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmDeleteQuestion(q),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 20, width: 1, color: AppTheme.borderSubtle.withValues(alpha: 0.5));
  }
}
