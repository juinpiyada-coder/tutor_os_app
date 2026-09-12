import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/academics_service.dart';
import '../../services/academic_structure_service.dart';

class CourseSyllabusBuilderScreen extends StatefulWidget {
  final int? initialCourseId;
  const CourseSyllabusBuilderScreen({super.key, this.initialCourseId});

  @override
  State<CourseSyllabusBuilderScreen> createState() => _CourseSyllabusBuilderScreenState();
}

class _CourseSyllabusBuilderScreenState extends State<CourseSyllabusBuilderScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _allSubjects = [];
  int? _selectedCourseId;
  List<Map<String, dynamic>> _mappedSubjects = [];

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final courses = await AcademicsService.getCourses();
    final allSubjects = await AcademicsService.getSubjects();
    if (mounted) {
      setState(() {
        _courses = courses;
        _allSubjects = allSubjects;
        if (_selectedCourseId == null && courses.isNotEmpty) {
          _selectedCourseId = int.tryParse(courses.first['course_id']?.toString() ?? '0');
        }
      });
      if (_selectedCourseId != null && _selectedCourseId! > 0) {
        await _loadMappedSubjects(_selectedCourseId!);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMappedSubjects(int courseId) async {
    setState(() => _isLoading = true);
    final mapped = await AcademicStructureService.getMappedSubjects(courseId);
    if (mounted) {
      setState(() {
        _mappedSubjects = mapped;
        _isLoading = false;
      });
    }
  }

  void _openMapSubjectModal() {
    if (_selectedCourseId == null) return;
    int? selectedSubId;
    final seqCtrl = TextEditingController(text: (_mappedSubjects.length + 1).toString());

    // Filter out already mapped subjects
    final mappedIds = _mappedSubjects.map((m) => int.tryParse(m['subject_id']?.toString() ?? '0')).toSet();
    final availableSubjects = _allSubjects.where((s) {
      final sId = int.tryParse(s['subject_id']?.toString() ?? '0');
      return !mappedIds.contains(sId);
    }).toList();

    if (availableSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All available subjects are already mapped to this course!')),
      );
      return;
    }

    selectedSubId = int.tryParse(availableSubjects.first['subject_id']?.toString() ?? '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Map Subject to Course',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textHeading,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubId,
                    decoration: InputDecoration(
                      labelText: 'Select Subject',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: availableSubjects.map((sub) {
                      final subId = int.tryParse(sub['subject_id']?.toString() ?? '0') ?? 0;
                      return DropdownMenuItem<int>(
                        value: subId,
                        child: Text('${sub['subject_name']} (${sub['subject_code'] ?? ''})'),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedSubId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: seqCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Syllabus Sequence Order',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (selectedSubId == null) return;
                        Navigator.pop(modalCtx);
                        final success = await AcademicStructureService.mapSubjectToCourse(
                          courseId: _selectedCourseId!,
                          subjectId: selectedSubId!,
                          sequenceNo: int.tryParse(seqCtrl.text.trim()) ?? 1,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Subject mapped to course!' : 'Failed to map subject')),
                          );
                          _loadMappedSubjects(_selectedCourseId!);
                        }
                      },
                      child: const Text('Add to Course Syllabus'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 0,
        title: Text(
          'Course Syllabus Builder',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textHeading,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ThemeToggleSwitch(),
          ),
        ],
      ),
      floatingActionButton: _selectedCourseId != null
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
              onPressed: _openMapSubjectModal,
              icon: const Icon(Icons.add_link),
              label: const Text('Map Subject'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCourseSelector(isDark),
                Expanded(
                  child: _mappedSubjects.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _loadMappedSubjects(_selectedCourseId!),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mappedSubjects.length,
                            itemBuilder: (context, index) {
                              return _buildSubjectCard(_mappedSubjects[index], index, isDark);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCourseSelector(bool isDark) {
    if (_courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
        child: const Text('No courses found. Please add courses first in Academics.'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, color: AppTheme.electricCobalt, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCourseId,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppTheme.textHeading,
                ),
                items: _courses.map((c) {
                  final cId = int.tryParse(c['course_id']?.toString() ?? '0') ?? 0;
                  return DropdownMenuItem<int>(
                    value: cId,
                    child: Text('${c['course_name']} (${c['course_code'] ?? ''})'),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != _selectedCourseId) {
                    setState(() => _selectedCourseId = newId);
                    _loadMappedSubjects(newId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Subjects Mapped to This Course',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Link subjects to construct this course curriculum curriculum track.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
            ),
            onPressed: _openMapSubjectModal,
            icon: const Icon(Icons.add_link),
            label: const Text('Map First Subject'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> item, int index, bool isDark) {
    final subId = int.tryParse(item['subject_id']?.toString() ?? '0') ?? 0;
    final seqNo = item['sequence_no'] ?? (index + 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
          child: Text(
            '$seqNo',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
          ),
        ),
        title: Text(
          item['subject_name'] ?? '',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textHeading,
          ),
        ),
        subtitle: Text(
          'Code: ${item['subject_code'] ?? ''} • Syllabus Sequence #$seqNo',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.link_off, color: Colors.red),
          tooltip: 'Remove from Course',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Unlink Subject?'),
                content: Text('Remove ${item['subject_name'] ?? ''} from the course program?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true && _selectedCourseId != null && subId > 0) {
              await AcademicStructureService.unmapSubjectFromCourse(
                courseId: _selectedCourseId!,
                subjectId: subId,
              );
              _loadMappedSubjects(_selectedCourseId!);
            }
          },
        ),
      ),
    );
  }
}
