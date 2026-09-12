import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/parent_dashboard_service.dart';

class ParentAcademicsScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const ParentAcademicsScreen({super.key, this.selectedChild});

  @override
  State<ParentAcademicsScreen> createState() => _ParentAcademicsScreenState();
}

class _ParentAcademicsScreenState extends State<ParentAcademicsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _academics = [];
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    setState(() => _isLoading = true);
    final list = await ParentDashboardService.getAcademicReport();
    if (mounted) {
      setState(() {
        _academics = list;
        _isLoading = false;
      });
    }
  }

  void _showMarksheetModal(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: AppTheme.electricCobalt, size: 24),
                    SizedBox(width: 8),
                    Text('Official Exam Marksheet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            Text(
              result['exam_title'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
            ),
            const SizedBox(height: 4),
            Text('Subject: ${result['subject'] ?? ''} • Date: ${result['date'] ?? ''}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
            const SizedBox(height: 20),

            // Score Highlight Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMarksheetMetric('Marks Obtained', '${result['marks_obtained']}/${result['max_marks']}'),
                  _buildMarksheetMetric('Percentage', '${result['percentage']}'),
                  _buildMarksheetMetric('Batch Rank', '${result['rank']}'),
                  _buildMarksheetMetric('Grade', '${result['grade']}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Faculty Remarks
            Container(
              padding: const EdgeInsets.all(16),
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
                      Icon(Icons.rate_review_rounded, size: 16, color: AppTheme.electricCobalt),
                      SizedBox(width: 6),
                      Text('Faculty Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textHeading)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['remarks'] ?? '',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textBody, height: 1.4),
                  ),
                ],
              ),
            ),

            const Spacer(),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('Download Official Report Card (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading report card for ${result['exam_title']}...'),
                    backgroundColor: AppTheme.primaryNavy,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksheetMetric(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successText)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedSubject == 'All'
        ? _academics
        : _academics.where((a) => (a['subject'] ?? '').toString().toLowerCase() == _selectedSubject.toLowerCase()).toList();

    return RefreshIndicator(
      onRefresh: _loadAcademicData,
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
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
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
                            'ACADEMIC PERFORMANCE',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Test Reports & Marksheets',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'View exam scores, class rankings, and personalized mentor feedback.',
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
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Subject Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Mathematics', 'Physics', 'Chemistry'].map((sub) {
                  final isSelected = _selectedSubject == sub;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sub),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F766E),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textBody,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      backgroundColor: AppTheme.surfaceWhite,
                      side: BorderSide(color: isSelected ? const Color(0xFF0F766E) : AppTheme.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedSubject = sub);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.electricCobalt),
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
                child: const Column(
                  children: [
                    Icon(Icons.assessment_outlined, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 12),
                    Text('No exam marks published yet', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Scores will appear once grading is finalized.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = filtered[index];

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
                                color: const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['subject'] ?? '',
                                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Grade ${item['grade'] ?? ''}',
                                style: const TextStyle(color: AppTheme.successText, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['exam_title'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                        ),
                        const SizedBox(height: 6),
                        Text('Conducted on ${item['date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 14),

                        // Score and Rank Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.canvasBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Score', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    const SizedBox(height: 2),
                                    Text('${item['marks_obtained'] ?? ''} / ${item['max_marks'] ?? ''} (${item['percentage'] ?? ''})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.canvasBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Batch Ranking', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    const SizedBox(height: 2),
                                    Text(item['rank'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Remarks
                        if (item['remarks'] != null) ...[
                          Text(
                            'Mentor Feedback: "${item['remarks']}"',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textBody),
                          ),
                          const SizedBox(height: 12),
                        ],

                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Color(0xFF0F766E)),
                          ),
                          icon: const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF0F766E)),
                          label: const Text('View Full Marksheet & Analysis', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () => _showMarksheetModal(item),
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
}
