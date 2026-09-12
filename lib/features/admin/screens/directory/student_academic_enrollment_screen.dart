import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/people_service.dart';
import '../../services/academic_structure_service.dart';
import '../../services/directory_service.dart';

class StudentAcademicEnrollmentScreen extends StatefulWidget {
  const StudentAcademicEnrollmentScreen({super.key});

  @override
  State<StudentAcademicEnrollmentScreen> createState() => _StudentAcademicEnrollmentScreenState();
}

class _StudentAcademicEnrollmentScreenState extends State<StudentAcademicEnrollmentScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _enrollments = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _students = [];

  int? _filterYearId;
  int? _filterGradeId;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    final years = await AcademicStructureService.getAcademicYears();
    final grades = await AcademicStructureService.getGrades();
    final students = await DirectoryService.getStudents();

    if (mounted) {
      setState(() {
        _academicYears = years;
        _grades = grades;
        _students = students;
      });
      await _loadEnrollments();
    }
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoading = true);
    final list = await PeopleService.getStudentAcademics(
      yearId: _filterYearId,
      gradeId: _filterGradeId,
    );
    if (mounted) {
      setState(() {
        _enrollments = list;
        _isLoading = false;
      });
    }
  }

  void _openEnrollmentModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    int? selectedStudentId = item != null ? int.tryParse(item['student_id']?.toString() ?? '') : null;
    int? selectedYearId = item != null
        ? int.tryParse(item['academic_year_id']?.toString() ?? '')
        : (_academicYears.isNotEmpty ? int.tryParse(_academicYears.first['academic_year_id']?.toString() ?? '') : null);
    int? selectedGradeId = item != null
        ? int.tryParse(item['grade_id']?.toString() ?? '')
        : (_grades.isNotEmpty ? int.tryParse(_grades.first['grade_id']?.toString() ?? '') : null);
    final rollCtrl = TextEditingController(text: item?['roll_no'] ?? '');
    String status = item?['status'] ?? 'ACTIVE';

    if (!isEdit && _students.isNotEmpty && selectedStudentId == null) {
      selectedStudentId = int.tryParse(_students.first['student_id']?.toString() ?? '');
    }

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Update Class Enrollment' : 'Enroll Student in Grade',
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
                    if (!isEdit) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedStudentId,
                        decoration: InputDecoration(
                          labelText: 'Select Student',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _students.map((s) {
                          final sId = int.tryParse(s['student_id']?.toString() ?? '0') ?? 0;
                          return DropdownMenuItem<int>(
                            value: sId,
                            child: Text('${s['first_name']} ${s['last_name']} (${s['student_code'] ?? ''})'),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedStudentId = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      initialValue: selectedYearId,
                      decoration: InputDecoration(
                        labelText: 'Academic Year',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _academicYears.map((ay) {
                        final yId = int.tryParse(ay['academic_year_id']?.toString() ?? '0') ?? 0;
                        return DropdownMenuItem<int>(
                          value: yId,
                          child: Text('${ay['year_name']} (${ay['year_code'] ?? ''})'),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedYearId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedGradeId,
                      decoration: InputDecoration(
                        labelText: 'Grade / Class',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _grades.map((g) {
                        final gId = int.tryParse(g['grade_id']?.toString() ?? '0') ?? 0;
                        return DropdownMenuItem<int>(
                          value: gId,
                          child: Text('${g['grade_name']} (${g['grade_code'] ?? ''})'),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedGradeId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rollCtrl,
                      decoration: InputDecoration(
                        labelText: 'Roll Number (e.g. 101 or A-12)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'Enrollment Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'PROMOTED', child: Text('Promoted')),
                        DropdownMenuItem(value: 'WITHDRAWN', child: Text('Withdrawn')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                      ],
                      onChanged: (val) => setModalState(() => status = val ?? 'ACTIVE'),
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
                          if (selectedYearId == null || selectedGradeId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select Academic Year and Grade')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'student_id': selectedStudentId,
                            'academic_year_id': selectedYearId,
                            'grade_id': selectedGradeId,
                            'roll_no': rollCtrl.text.trim(),
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await PeopleService.updateStudentAcademic(
                              int.parse(item['student_academic_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await PeopleService.enrollStudentAcademic(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Enrollment updated!' : 'Action failed')),
                            );
                            _loadEnrollments();
                          }
                        },
                        child: Text(isEdit ? 'Update Enrollment' : 'Enroll Student'),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        elevation: 0,
        title: Text(
          'Student Academic Enrollment',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        onPressed: () => _openEnrollmentModal(),
        icon: const Icon(Icons.assignment_ind),
        label: const Text('Enroll Student'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterRow(isDark),
                Expanded(
                  child: _enrollments.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadEnrollments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _enrollments.length,
                            itemBuilder: (context, index) {
                              return _buildEnrollmentCard(_enrollments[index], isDark);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _filterYearId,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                hint: const Text('All Academic Years'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All Academic Years')),
                  ..._academicYears.map((ay) {
                    final yId = int.tryParse(ay['academic_year_id']?.toString() ?? '0') ?? 0;
                    return DropdownMenuItem<int?>(value: yId, child: Text(ay['year_code'] ?? ''));
                  }),
                ],
                onChanged: (val) {
                  setState(() => _filterYearId = val);
                  _loadEnrollments();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _filterGradeId,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                hint: const Text('All Grades'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All Grades')),
                  ..._grades.map((g) {
                    final gId = int.tryParse(g['grade_id']?.toString() ?? '0') ?? 0;
                    return DropdownMenuItem<int?>(value: gId, child: Text(g['grade_name'] ?? ''));
                  }),
                ],
                onChanged: (val) {
                  setState(() => _filterGradeId = val);
                  _loadEnrollments();
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
          Icon(Icons.how_to_reg_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Student Enrollments Found',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
            onPressed: () => _openEnrollmentModal(),
            icon: const Icon(Icons.add),
            label: const Text('Enroll First Student'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(Map<String, dynamic> item, bool isDark) {
    final recordId = int.tryParse(item['student_academic_id']?.toString() ?? '0') ?? 0;
    final studentName = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
    final gradeName = item['grade_name'] ?? '';
    final yearName = item['year_name'] ?? '';
    final rollNo = item['roll_no'] ?? '';
    final status = item['status'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkAcademicBg : AppTheme.academicBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Roll: $rollNo',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.academicText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'ACTIVE'
                            ? (isDark ? AppTheme.darkSuccessBg : AppTheme.successBg)
                            : (isDark ? AppTheme.darkWarningBg : AppTheme.warningBg),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'ACTIVE' ? AppTheme.successText : AppTheme.warningText,
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      _openEnrollmentModal(item);
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Enrollment?'),
                          content: Text('Remove $studentName from $gradeName?'),
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
                      if (confirm == true && recordId > 0) {
                        await PeopleService.deleteStudentAcademic(recordId);
                        _loadEnrollments();
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit / Promote')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              studentName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Grade: $gradeName  •  Session: $yearName',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
