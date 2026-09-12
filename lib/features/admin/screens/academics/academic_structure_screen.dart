import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/academic_structure_service.dart';

class AcademicStructureScreen extends StatefulWidget {
  const AcademicStructureScreen({super.key});

  @override
  State<AcademicStructureScreen> createState() => _AcademicStructureScreenState();
}

class _AcademicStructureScreenState extends State<AcademicStructureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final years = await AcademicStructureService.getAcademicYears();
    final grades = await AcademicStructureService.getGrades();
    if (mounted) {
      setState(() {
        _academicYears = years;
        _grades = grades;
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // MODALS: ACADEMIC YEAR
  // ===========================================================================
  void _openYearModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['year_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['year_name'] ?? '');
    DateTime startDate = item != null && item['start_date'] != null
        ? DateTime.tryParse(item['start_date']) ?? DateTime.now()
        : DateTime.now();
    DateTime endDate = item != null && item['end_date'] != null
        ? DateTime.tryParse(item['end_date']) ?? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 365));
    bool isCurrent = item != null ? (item['is_current'] == 1 || item['is_current'] == true) : false;
    String status = (item != null && item['status'] != null && item['status'].toString().isNotEmpty)
        ? item['status'].toString().toUpperCase()
        : 'ACTIVE';
    if (!['PLANNED', 'ACTIVE', 'CLOSED', 'ARCHIVED'].contains(status)) {
      status = 'ACTIVE';
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
                          isEdit ? 'Edit Academic Year' : 'Add Academic Year',
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
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Year Code (e.g. AY-2026-27)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Year Name (e.g. Academic Session 2026-2027)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2040),
                              );
                              if (picked != null) {
                                setModalState(() => startDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              'Start: ${startDate.toIso8601String().split('T')[0]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2040),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            icon: const Icon(Icons.event, size: 16),
                            label: Text(
                              'End: ${endDate.toIso8601String().split('T')[0]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Set as Current Active Session',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      value: isCurrent,
                      onChanged: (val) => setModalState(() => isCurrent = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PLANNED', child: Text('Planned')),
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                        DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                      ],
                      onChanged: (val) => setModalState(() => status = val ?? ''),
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
                          if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'year_code': codeCtrl.text.trim(),
                            'year_name': nameCtrl.text.trim(),
                            'start_date': startDate.toIso8601String().split('T')[0],
                            'end_date': endDate.toIso8601String().split('T')[0],
                            'is_current': isCurrent,
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await AcademicStructureService.updateAcademicYear(
                              int.parse(item['academic_year_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await AcademicStructureService.addAcademicYear(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Saved successfully!' : 'Action failed')),
                            );
                            _loadData();
                          }
                        },
                        child: Text(isEdit ? 'Update Year' : 'Create Academic Year'),
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

  // ===========================================================================
  // MODALS: GRADE / CLASS
  // ===========================================================================
  void _openGradeModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['grade_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['grade_name'] ?? '');
    final seqCtrl = TextEditingController(text: (item?['sequence_no'] ?? '1').toString());
    String status = (item != null && item['status'] != null && item['status'].toString().isNotEmpty)
        ? item['status'].toString().toUpperCase()
        : 'ACTIVE';
    if (!['ACTIVE', 'INACTIVE'].contains(status)) {
      status = 'ACTIVE';
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
                          isEdit ? 'Edit Grade / Class' : 'Add Grade / Class',
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
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Grade Code (e.g. GRD-10)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Grade / Class Name (e.g. Class 10 - Matric)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sequence Order (e.g. 10)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                      ],
                      onChanged: (val) => setModalState(() => status = val ?? ''),
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
                          if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'grade_code': codeCtrl.text.trim(),
                            'grade_name': nameCtrl.text.trim(),
                            'sequence_no': int.tryParse(seqCtrl.text.trim()) ?? 1,
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await AcademicStructureService.updateGrade(
                              int.parse(item['grade_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await AcademicStructureService.addGrade(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Grade saved!' : 'Action failed')),
                            );
                            _loadData();
                          }
                        },
                        child: Text(isEdit ? 'Update Grade' : 'Create Grade'),
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
          'Academic Structure',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.electricCobalt,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Academic Years'),
            Tab(icon: Icon(Icons.school, size: 18), text: 'Grades / Classes'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_tabController.index == 0) {
            _openYearModal();
          } else {
            _openGradeModal();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Year' : 'Add Grade'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildYearsTab(isDark),
                  _buildGradesTab(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildYearsTab(bool isDark) {
    if (_academicYears.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Academic Years Configured',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openYearModal(),
              child: const Text('Add Academic Year'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _academicYears.length,
      itemBuilder: (context, index) {
        final item = _academicYears[index];
        final isCurrent = item['is_current'] == 1 || item['is_current'] == true;
        final yearId = int.tryParse(item['academic_year_id']?.toString() ?? '0') ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCurrent ? AppTheme.electricCobalt : (isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3)),
              width: isCurrent ? 2 : 1,
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
                            item['year_code'] ?? '',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.academicText,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSuccessBg : AppTheme.successBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 12, color: AppTheme.successText),
                                SizedBox(width: 4),
                                Text(
                                  'Current Session',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _openYearModal(item);
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Academic Year?'),
                              content: Text('Are you sure you want to delete ${item['year_name']}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && yearId > 0) {
                            await AcademicStructureService.deleteAcademicYear(yearId);
                            _loadData();
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['year_name'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 14, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${item['start_date'] ?? ''}  →  ${item['end_date'] ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradesTab(bool isDark) {
    if (_grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Grades Configured',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _openGradeModal(),
              child: const Text('Add First Grade'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _grades.length,
      itemBuilder: (context, index) {
        final item = _grades[index];
        final gradeId = int.tryParse(item['grade_id']?.toString() ?? '0') ?? 0;

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
                '${item['sequence_no'] ?? index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricCobalt,
                ),
              ),
            ),
            title: Text(
              item['grade_name'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
            subtitle: Text(
              'Code: ${item['grade_code'] ?? ''} • Status: ${item['status'] ?? ''}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) async {
                if (val == 'edit') {
                  _openGradeModal(item);
                } else if (val == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Grade?'),
                      content: Text('Are you sure you want to delete ${item['grade_name']}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && gradeId > 0) {
                    await AcademicStructureService.deleteGrade(gradeId);
                    _loadData();
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        );
      },
    );
  }
}
