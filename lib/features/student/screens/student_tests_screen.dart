import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/student_dashboard_service.dart';

class StudentTestsScreen extends StatefulWidget {
  const StudentTestsScreen({super.key});

  @override
  State<StudentTestsScreen> createState() => _StudentTestsScreenState();
}

class _StudentTestsScreenState extends State<StudentTestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _exams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final examsData = await StudentDashboardService.getExams();
    if (mounted) {
      setState(() {
        _exams = examsData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Examinations & Results'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today_rounded, size: 20), text: 'Upcoming Exams'),
            Tab(icon: Icon(Icons.quiz_rounded, size: 20), text: 'My Exams'),
            Tab(icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'Results'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingExamsList(),
                _buildExamsList(),
                _buildResultsList(),
              ],
            ),
    );
  }

  Widget _buildUpcomingExamsList() {
    final upcoming = _exams.where((e) => (e['status'] ?? '').toString().toUpperCase() != 'COMPLETED').toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: upcoming.length + 1,
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
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SCHEDULED ASSESSMENTS', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        SizedBox(height: 6),
                        Text('Upcoming Exams', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Review your upcoming scheduled exams, dates, timings and syllabus.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.calendar_month_rounded, color: Colors.white, size: 40),
                ],
              ),
            );
          }
          return _buildExamCard(upcoming[index - 1]);
        },
      ),
    );
  }

  Widget _buildResultsList() {
    final completed = _exams.where((e) => (e['status'] ?? '').toString().toUpperCase() == 'COMPLETED').toList();
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: completed.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.level2Shadow,
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PERFORMANCE REPORT', style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        SizedBox(height: 6),
                        Text('Exam Results & Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('View graded marks, score breakdowns and solution keys.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                ],
              ),
            );
          }
          return _buildExamCard(completed[index - 1]);
        },
      ),
    );
  }

  void _startMockTest(Map<String, dynamic> exam) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MockTestRunnerModal(
        exam: exam,
        onExamSubmitted: (score, total, passed) {
          setState(() {
            exam['status'] = 'COMPLETED';
            exam['score'] = '$score/$total (${((score / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}%)';
            exam['rank'] = passed ? 'Passed' : 'Failed';
          });
        },
      ),
    );
  }

  void _showTestAnalysis(Map<String, dynamic> exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExamAnalysisModal(exam: exam),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final isCompleted = exam['status'] == 'COMPLETED';
    final isLive = exam['status'] == 'LIVE' || exam['status'] == 'PUBLISHED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive 
              ? AppTheme.electricCobalt.withValues(alpha: 0.5) 
              : (isCompleted ? AppTheme.successText.withValues(alpha: 0.3) : AppTheme.borderSubtle),
          width: isLive ? 1.5 : 1.0,
        ),
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
                  color: isCompleted ? AppTheme.successBg : AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam['subject'] ?? '',
                  style: TextStyle(
                    color: isCompleted ? AppTheme.successText : AppTheme.electricCobalt,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.successBg 
                      : (isLive ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted 
                        ? AppTheme.successText.withValues(alpha: 0.3) 
                        : (isLive ? AppTheme.electricCobalt.withValues(alpha: 0.4) : const Color(0xFFF59E0B)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.electricCobalt, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isCompleted ? 'COMPLETED' : (isLive ? 'LIVE TEST' : 'UPCOMING'),
                      style: TextStyle(
                        color: isCompleted 
                            ? AppTheme.successText 
                            : (isLive ? AppTheme.electricCobalt : const Color(0xFFD97706)),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exam['title'] ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
          ),
          const SizedBox(height: 4),
          Text(
            'Batch: ${exam['batch_name'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          if (exam['syllabus'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Topics: ${exam['syllabus']}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.canvasBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(exam['date'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(exam['duration'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text('${exam['total_marks'] ?? ''} Marks', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted && exam['score'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.successText, size: 16),
                      const SizedBox(width: 6),
                      Text('Score: ${exam['score']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successText, fontSize: 13)),
                    ],
                  ),
                  Text(exam['rank'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.electricCobalt, fontSize: 13)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? AppTheme.surfaceSubtle : AppTheme.electricCobalt,
              foregroundColor: isCompleted ? AppTheme.electricCobalt : Colors.white,
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: Icon(isCompleted ? Icons.insights_rounded : Icons.play_arrow_rounded, size: 18),
            label: Text(
              isCompleted ? 'View Analysis & Solutions' : 'Start Mock Test', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () {
              if (isCompleted) {
                _showTestAnalysis(exam);
              } else {
                _startMockTest(exam);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.electricCobalt,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _exams.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.level2Shadow,
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ASSESSMENT CENTER', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        SizedBox(height: 6),
                        Text('Exams & Performance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Take live mock tests, practice quizzes & track detailed ranking analysis.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                ],
              ),
            );
          }

          final exam = _exams[index - 1];
          final isCompleted = exam['status'] == 'COMPLETED';
          final isLive = exam['status'] == 'LIVE' || exam['status'] == 'PUBLISHED';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLive 
                    ? AppTheme.electricCobalt.withValues(alpha: 0.5) 
                    : (isCompleted ? AppTheme.successText.withValues(alpha: 0.3) : AppTheme.borderSubtle),
                width: isLive ? 1.5 : 1.0,
              ),
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
                        color: isCompleted ? AppTheme.successBg : AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exam['subject'] ?? '',
                        style: TextStyle(
                          color: isCompleted ? AppTheme.successText : AppTheme.electricCobalt,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? AppTheme.successBg 
                            : (isLive ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCompleted 
                              ? AppTheme.successText.withValues(alpha: 0.3) 
                              : (isLive ? AppTheme.electricCobalt.withValues(alpha: 0.4) : const Color(0xFFF59E0B)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.electricCobalt, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isCompleted ? 'COMPLETED' : (isLive ? 'LIVE TEST' : 'UPCOMING'),
                            style: TextStyle(
                              color: isCompleted 
                                  ? AppTheme.successText 
                                  : (isLive ? AppTheme.electricCobalt : const Color(0xFFD97706)),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  exam['title'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batch: ${exam['batch_name'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                if (exam['syllabus'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Topics: ${exam['syllabus']}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(exam['date'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(exam['duration'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text('${exam['total_marks'] ?? ''} Marks', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCompleted && exam['score'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.successText, size: 16),
                            const SizedBox(width: 6),
                            Text('Score: ${exam['score']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successText, fontSize: 13)),
                          ],
                        ),
                        Text(exam['rank'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.electricCobalt, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? AppTheme.surfaceSubtle : AppTheme.electricCobalt,
                    foregroundColor: isCompleted ? AppTheme.electricCobalt : Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: Icon(isCompleted ? Icons.insights_rounded : Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    isCompleted ? 'View Analysis & Solutions' : 'Start Mock Test', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    if (isCompleted) {
                      _showTestAnalysis(exam);
                    } else {
                      _startMockTest(exam);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MockTestRunnerModal extends StatefulWidget {
  final Map<String, dynamic> exam;
  final Function(int score, int total, bool passed) onExamSubmitted;

  const _MockTestRunnerModal({required this.exam, required this.onExamSubmitted});

  @override
  State<_MockTestRunnerModal> createState() => _MockTestRunnerModalState();
}

class _MockTestRunnerModalState extends State<_MockTestRunnerModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  int _currentQIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> optionId
  int _secondsLeft = 1800; // 30 minutes default timer countdown
  bool _isSubmitted = false;
  int _earnedScore = 0;
  int _totalPossibleScore = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final examId = int.tryParse(widget.exam['exam_id'].toString()) ?? 1;
    final questions = await StudentDashboardService.getExamQuestions(examId);
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
        final dur = widget.exam['duration_minutes'] ?? 30;
        _secondsLeft = dur * 60;
      });
    }
  }

  void _finishExam() {
    int score = 0;
    int totalMarks = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final marks = int.tryParse(q['marks'].toString()) ?? 4;
      totalMarks += marks;

      final selectedOptId = _selectedAnswers[i];
      if (selectedOptId != null && q['options'] != null) {
        final options = q['options'] as List;
        final correctOpt = options.firstWhere((opt) => opt['is_correct'] == true, orElse: () => null);
        if (correctOpt != null && correctOpt['option_id'] == selectedOptId) {
          score += marks;
        }
      }
    }

    final passMarks = (widget.exam['pass_marks'] != null) 
        ? (int.tryParse(widget.exam['pass_marks'].toString()) ?? (totalMarks * 0.4).toInt())
        : (totalMarks * 0.4).toInt();
    final isPassed = score >= passMarks;

    setState(() {
      _isSubmitted = true;
      _earnedScore = score;
      _totalPossibleScore = totalMarks == 0 ? 20 : totalMarks;
    });

    final examId = int.tryParse(widget.exam['exam_id'].toString()) ?? 1;
    StudentDashboardService.submitExamAttempt(
      examId: examId,
      score: _earnedScore,
      totalMarks: _totalPossibleScore,
      answers: _selectedAnswers,
      timeSpentSeconds: (widget.exam['duration_minutes'] ?? 30) * 60 - _secondsLeft,
    );

    widget.onExamSubmitted(_earnedScore, _totalPossibleScore, isPassed);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : _isSubmitted
              ? _buildResultView()
              : _buildExamQuizView(minutes, seconds),
    );
  }

  Widget _buildExamQuizView(String minutes, String seconds) {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('No questions loaded for this test', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }

    final currentQ = _questions[_currentQIndex];
    final options = (currentQ['options'] as List?) ?? [];

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      widget.exam['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Question ${_currentQIndex + 1} of ${_questions.length} • Marks: ${currentQ['marks'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.electricCobalt.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 16, color: AppTheme.electricCobalt),
                    const SizedBox(width: 6),
                    Text(
                      '$minutes:$seconds',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Progress indicators
        LinearProgressIndicator(
          value: (_currentQIndex + 1) / _questions.length,
          backgroundColor: AppTheme.borderSubtle,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricCobalt),
          minHeight: 4,
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentQ['subject'] ?? widget.exam['subject'] ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentQ['question_text'] ?? '',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textHeading, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Options list or Descriptive Input
                if (options.isNotEmpty) ...[
                  ...options.map((opt) {
                    final optId = opt['option_id'];
                    final isSelected = _selectedAnswers[_currentQIndex] == optId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAnswers[_currentQIndex] = optId;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.surfaceSubtle : AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.electricCobalt : AppTheme.textMuted,
                                  width: 2,
                                ),
                                color: isSelected ? AppTheme.electricCobalt : Colors.transparent,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt['option_text'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.electricCobalt : AppTheme.textHeading,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Descriptive Answer / Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted)),
                        const SizedBox(height: 10),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type your explanation or final answer here...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: AppTheme.canvasBackground,
                          ),
                          onChanged: (val) {
                            if (val.trim().isNotEmpty) {
                              _selectedAnswers[_currentQIndex] = 1;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Navigation Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _currentQIndex > 0
                    ? () => setState(() => _currentQIndex--)
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Previous'),
              ),
              if (_currentQIndex < _questions.length - 1)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => setState(() => _currentQIndex++),
                  icon: const Text('Next'),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Submit Mock Test?'),
                        content: Text('You have answered ${_selectedAnswers.length} of ${_questions.length} questions. Are you ready to submit?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Review')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successText, foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(c);
                              _finishExam();
                            },
                            child: const Text('Submit Exam'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Submit Test'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final pct = ((_earnedScore / (_totalPossibleScore == 0 ? 1 : _totalPossibleScore)) * 100).toStringAsFixed(0);
    final isPassed = int.parse(pct) >= 40;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isPassed ? AppTheme.successBg : AppTheme.urgentBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.emoji_events_rounded : Icons.replay_rounded,
              color: isPassed ? AppTheme.successText : AppTheme.urgentText,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Congratulations! Test Completed' : 'Test Submitted',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textHeading),
          ),
          const SizedBox(height: 6),
          Text(
            'You scored $_earnedScore out of $_totalPossibleScore marks ($pct%)',
            style: const TextStyle(fontSize: 15, color: AppTheme.textBody),
          ),
          const SizedBox(height: 24),

          // Score Breakdown Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: AppTheme.level1Shadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric('Total Questions', '${_questions.length}'),
                    _buildMetric('Answered', '${_selectedAnswers.length}'),
                    _buildMetric('Accuracy', '$pct%'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Outcome', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    Text(
                      isPassed ? 'PASSED (Qualified)' : 'NEEDS PRACTICE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? AppTheme.successText : AppTheme.urgentText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Return to Assessment Center', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.electricCobalt)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _ExamAnalysisModal extends StatelessWidget {
  final Map<String, dynamic> exam;

  const _ExamAnalysisModal({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Analysis: ${exam['title'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textHeading),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.canvasBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalysisStat('Score', exam['score']?.toString() ?? ''),
                _buildAnalysisStat('Batch Rank', exam['rank']?.toString() ?? ''),
                _buildAnalysisStat('Percentile', exam['percentile']?.toString() ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Subject-wise Mastery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _buildSubjectBar('Theory & Core Formulas', 0.92, AppTheme.successText),
          const SizedBox(height: 8),
          _buildSubjectBar('Numerical Problem Solving', 0.84, AppTheme.electricCobalt),
          const SizedBox(height: 8),
          _buildSubjectBar('Speed & Time Management', 0.78, const Color(0xFFF59E0B)),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildSubjectBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody)),
            Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppTheme.borderSubtle,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
