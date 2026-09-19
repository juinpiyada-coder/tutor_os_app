import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/academics_service.dart';
import '../../services/academic_structure_service.dart';
import '../../services/settings_service.dart';
import '../../services/directory_service.dart';
import '../../services/operations_service.dart';

class AddBatchScreen extends StatefulWidget {
  final Map<String, dynamic>? existingBatch;
  const AddBatchScreen({super.key, this.existingBatch});

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _batchNameController;
  late final TextEditingController _batchCodeController;
  late final TextEditingController _maxStudentsController;
  late final TextEditingController _roomNameController;
  late final TextEditingController _teacherNameController;
  late final TextEditingController _meetUrlController;

  int? _selectedCourseId;
  int? _selectedYearId;
  int? _selectedGradeId;
  int? _selectedSubjectId;
  int? _selectedBranchId;
  int? _selectedStaffId;
  String _status = 'ACTIVE';

  // Schedule & Timing State
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  final List<String> _selectedDays = ['MONDAY', 'WEDNESDAY', 'FRIDAY'];

  final List<Map<String, String>> _allWeekdays = [
    {'key': 'MONDAY', 'short': 'Mon', 'label': 'Monday'},
    {'key': 'TUESDAY', 'short': 'Tue', 'label': 'Tuesday'},
    {'key': 'WEDNESDAY', 'short': 'Wed', 'label': 'Wednesday'},
    {'key': 'THURSDAY', 'short': 'Thu', 'label': 'Thursday'},
    {'key': 'FRIDAY', 'short': 'Fri', 'label': 'Friday'},
    {'key': 'SATURDAY', 'short': 'Sat', 'label': 'Saturday'},
    {'key': 'SUNDAY', 'short': 'Sun', 'label': 'Sunday'},
  ];

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _staffList = [];
  
  bool _isLoading = false;
  bool _isFetchingRelations = true;

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(text: widget.existingBatch?['batch_name'] ?? '');
    _batchCodeController = TextEditingController(text: widget.existingBatch?['batch_code'] ?? '');
    _maxStudentsController = TextEditingController(text: (widget.existingBatch?['max_students'] ?? 30).toString());
    _roomNameController = TextEditingController(text: widget.existingBatch?['room_name'] ?? 'Smart Class 101');
    _teacherNameController = TextEditingController(text: widget.existingBatch?['teacher_name'] ?? '');
    _meetUrlController = TextEditingController(text: widget.existingBatch?['meet_url'] ?? 'https://meet.google.com/new');

    _selectedCourseId = int.tryParse(widget.existingBatch?['course_id']?.toString() ?? '');
    _selectedYearId = int.tryParse(widget.existingBatch?['academic_year_id']?.toString() ?? '');
    _selectedGradeId = int.tryParse(widget.existingBatch?['grade_id']?.toString() ?? '');
    _selectedSubjectId = int.tryParse(widget.existingBatch?['subject_id']?.toString() ?? '');
    _selectedBranchId = int.tryParse(widget.existingBatch?['branch_id']?.toString() ?? '');
    _status = widget.existingBatch?['status'] ?? 'ACTIVE';

    _loadRelationalData();
  }

  Future<void> _loadRelationalData() async {
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        AcademicsService.getCourses().catchError((_) => <Map<String, dynamic>>[]),
        AcademicStructureService.getAcademicYears().catchError((_) => <Map<String, dynamic>>[]),
        AcademicStructureService.getGrades().catchError((_) => <Map<String, dynamic>>[]),
        AcademicsService.getSubjects().catchError((_) => <Map<String, dynamic>>[]),
        SettingsService.getBranches().catchError((_) => <Map<String, dynamic>>[]),
        DirectoryService.getStaff().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0];
          _academicYears = results[1];
          _grades = results[2];
          _subjects = results[3];
          _branches = results[4];
          _staffList = results[5];

          if (_grades.isEmpty) {
            _grades = [
              {'grade_id': 1, 'grade_name': 'Class I', 'grade_code': 'STD-1'},
              {'grade_id': 2, 'grade_name': 'Class II', 'grade_code': 'STD-2'},
              {'grade_id': 3, 'grade_name': 'Class III', 'grade_code': 'STD-3'},
              {'grade_id': 4, 'grade_name': 'Class IV', 'grade_code': 'STD-4'},
              {'grade_id': 5, 'grade_name': 'Class V', 'grade_code': 'STD-5'},
              {'grade_id': 6, 'grade_name': 'Class VI', 'grade_code': 'STD-6'},
              {'grade_id': 7, 'grade_name': 'Class VII', 'grade_code': 'STD-7'},
              {'grade_id': 8, 'grade_name': 'Class VIII', 'grade_code': 'STD-8'},
              {'grade_id': 9, 'grade_name': 'Class IX', 'grade_code': 'STD-9'},
              {'grade_id': 10, 'grade_name': 'Class X', 'grade_code': 'STD-10'},
              {'grade_id': 11, 'grade_name': 'Class XI', 'grade_code': 'STD-11'},
              {'grade_id': 12, 'grade_name': 'Class XII', 'grade_code': 'STD-12'},
            ];
          }

          _selectedCourseId ??= _courses.isNotEmpty ? int.tryParse(_courses.first['course_id']?.toString() ?? '1') : null;
          _selectedYearId ??= _academicYears.isNotEmpty ? int.tryParse(_academicYears.first['academic_year_id']?.toString() ?? '1') : null;
          _selectedGradeId ??= _grades.isNotEmpty ? int.tryParse(_grades.first['grade_id']?.toString() ?? '1') : null;
          _selectedSubjectId ??= _subjects.isNotEmpty ? int.tryParse(_subjects.first['subject_id']?.toString() ?? '1') : null;
          _selectedBranchId ??= _branches.isNotEmpty ? int.tryParse(_branches.first['branch_id']?.toString() ?? '1') : null;

          _isFetchingRelations = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingRelations = false);
    }
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _batchCodeController.dispose();
    _maxStudentsController.dispose();
    _roomNameController.dispose();
    _teacherNameController.dispose();
    _meetUrlController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _timeOfDayToDbString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.electricCobalt,
              onPrimary: Colors.white,
              onSurface: AppTheme.textHeading,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.electricCobalt,
              onPrimary: Colors.white,
              onSurface: AppTheme.textHeading,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _applyDayPreset(String preset) {
    setState(() {
      _selectedDays.clear();
      switch (preset) {
        case 'MWF':
          _selectedDays.addAll(['MONDAY', 'WEDNESDAY', 'FRIDAY']);
          break;
        case 'TTS':
          _selectedDays.addAll(['TUESDAY', 'THURSDAY', 'SATURDAY']);
          break;
        case 'WEEKDAYS':
          _selectedDays.addAll(['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY']);
          break;
        case 'DAILY':
          _selectedDays.addAll(['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY']);
          break;
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.existingBatch != null;

      try {
        String teacherName = _teacherNameController.text.trim();
        if (_selectedStaffId != null) {
          final matchedStaff = _staffList.firstWhere(
            (s) => int.tryParse((s['staff_id'] ?? s['id'] ?? '').toString()) == _selectedStaffId,
            orElse: () => <String, dynamic>{},
          );
          if (matchedStaff.isNotEmpty) {
            final fName = matchedStaff['first_name'] ?? '';
            final lName = matchedStaff['last_name'] ?? '';
            final resolved = '$fName $lName'.trim();
            if (resolved.isNotEmpty) teacherName = resolved;
          }
        }

        final data = {
          'batch_name': _batchNameController.text.trim(),
          'batch_code': _batchCodeController.text.trim(),
          'max_students': int.tryParse(_maxStudentsController.text.trim()) ?? 30,
          if (_selectedCourseId != null) 'course_id': _selectedCourseId,
          if (_selectedYearId != null) 'academic_year_id': _selectedYearId,
          if (_selectedGradeId != null) 'grade_id': _selectedGradeId,
          if (_selectedSubjectId != null) 'subject_id': _selectedSubjectId,
          if (_selectedBranchId != null) 'branch_id': _selectedBranchId,
          'status': _status,
          // Schedule & timing details embedded directly
          'start_time': _timeOfDayToDbString(_startTime),
          'end_time': _timeOfDayToDbString(_endTime),
          'room_name': _roomNameController.text.trim().isNotEmpty ? _roomNameController.text.trim() : 'Smart Class 101',
          'teacher_name': teacherName.isNotEmpty ? teacherName : 'Faculty Instructor',
          if (_selectedStaffId != null) 'staff_id': _selectedStaffId,
          'meet_url': _meetUrlController.text.trim(),
          'days': _selectedDays.isNotEmpty ? _selectedDays : ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
        };
        
        if (isEditing) {
          final batchId = int.tryParse((widget.existingBatch!['batch_id'] ?? 1).toString()) ?? 1;
          await AcademicsService.updateBatch(batchId, data);
        } else {
          await AcademicsService.addBatch(data);
        }

        // Also add explicit schedule entries to master_schedule for each day
        final daysToSchedule = _selectedDays.isNotEmpty ? _selectedDays : ['MONDAY'];
        for (final day in daysToSchedule) {
          await OperationsService.addSchedule({
            'day_of_week': day,
            'start_time': _timeOfDayToDbString(_startTime),
            'end_time': _timeOfDayToDbString(_endTime),
            'room_name': _roomNameController.text.trim().isNotEmpty ? _roomNameController.text.trim() : 'Smart Class 101',
            'teacher_name': teacherName.isNotEmpty ? teacherName : 'Faculty Instructor',
            'subject_name': _batchNameController.text.trim(),
            'meet_url': _meetUrlController.text.trim(),
            'status': 'ACTIVE',
          }).catchError((_) => false);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing 
                    ? 'Batch & time schedule updated successfully' 
                    : 'Batch created with class time schedule!',
                style: const TextStyle(color: AppTheme.surfaceWhite, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.successText,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', style: const TextStyle(color: AppTheme.surfaceWhite)), backgroundColor: AppTheme.urgentText),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBatch != null;
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Batch & Schedule' : 'Create Batch & Schedule'),
        elevation: 0,
      ),
      body: _isFetchingRelations 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- SECTION 1: BATCH INFORMATION ---
                    Container(
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.groups_rounded, color: AppTheme.electricCobalt, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Batch Details',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _batchNameController,
                            decoration: const InputDecoration(
                              labelText: 'Batch Name',
                              hintText: 'e.g. Class 10 - Mathematics Morning',
                              prefixIcon: Icon(Icons.class_outlined),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Batch name is required' : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _batchCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Batch Code',
                              hintText: 'e.g. MTH-10-M',
                              prefixIcon: Icon(Icons.qr_code_rounded),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Batch code is required' : null,
                          ),
                          const SizedBox(height: 14),

                          // Relational ER Selector: Course
                          if (_courses.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: _selectedCourseId,
                              decoration: const InputDecoration(
                                labelText: 'Select Course Program',
                                prefixIcon: Icon(Icons.school_outlined),
                              ),
                              items: _courses.map((c) {
                                final id = int.tryParse(c['course_id']?.toString() ?? '1') ?? 1;
                                final name = c['course_name'] ?? '';
                                return DropdownMenuItem<int>(value: id, child: Text(name));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCourseId = val),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Relational ER Selector: Grade / Class
                          if (_grades.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: _selectedGradeId,
                              decoration: const InputDecoration(
                                labelText: 'Grade / Class Level',
                                prefixIcon: Icon(Icons.format_list_numbered_rounded),
                              ),
                              items: _grades.map((g) {
                                final id = int.tryParse(g['grade_id']?.toString() ?? '1') ?? 1;
                                final name = g['grade_name'] ?? g['grade_code'] ?? '';
                                return DropdownMenuItem<int>(value: id, child: Text(name));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedGradeId = val),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Relational ER Selector: Subject
                          if (_subjects.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: _selectedSubjectId,
                              decoration: const InputDecoration(
                                labelText: 'Subject Curriculum',
                                prefixIcon: Icon(Icons.menu_book_rounded),
                              ),
                              items: _subjects.map((s) {
                                final id = int.tryParse(s['subject_id']?.toString() ?? '1') ?? 1;
                                final name = s['subject_name'] ?? s['subject_code'] ?? '';
                                return DropdownMenuItem<int>(value: id, child: Text(name));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedSubjectId = val),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Relational ER Selector: Branch
                          if (_branches.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: _selectedBranchId,
                              decoration: const InputDecoration(
                                labelText: 'Campus Branch',
                                prefixIcon: Icon(Icons.business_rounded),
                              ),
                              items: _branches.map((b) {
                                final id = int.tryParse(b['branch_id']?.toString() ?? '1') ?? 1;
                                final name = b['branch_name'] ?? '';
                                return DropdownMenuItem<int>(value: id, child: Text(name));
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedBranchId = val),
                            ),
                            const SizedBox(height: 14),
                          ],

                          TextFormField(
                            controller: _maxStudentsController,
                            decoration: const InputDecoration(
                              labelText: 'Max Student Capacity',
                              hintText: 'e.g. 30',
                              prefixIcon: Icon(Icons.person_pin_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Max students is required';
                              final capacity = int.tryParse(value.trim());
                              if (capacity == null) return 'Must be a valid number';
                              if (capacity <= 0) return 'Must be greater than zero';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.toggle_on_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                              DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                            ],
                            onChanged: (val) => setState(() => _status = val ?? 'ACTIVE'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- SECTION 2: CLASS ROUTINE & TIME SCHEDULE ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.electricCobalt.withValues(alpha: 0.35), width: 1.3),
                        boxShadow: AppTheme.level1Shadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.access_time_rounded, color: Color(0xFF059669), size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class Routine & Time Schedule',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                                    ),
                                    Text(
                                      'Set recurring days, timings, classroom, and faculty',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Quick Presets
                          const Text('Recurring Days:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                          const SizedBox(height: 8),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ActionChip(
                                  label: const Text('MWF (Mon, Wed, Fri)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppTheme.surfaceSubtle,
                                  onPressed: () => _applyDayPreset('MWF'),
                                ),
                                const SizedBox(width: 6),
                                ActionChip(
                                  label: const Text('TTS (Tue, Thu, Sat)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppTheme.surfaceSubtle,
                                  onPressed: () => _applyDayPreset('TTS'),
                                ),
                                const SizedBox(width: 6),
                                ActionChip(
                                  label: const Text('Weekdays (Mon-Fri)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppTheme.surfaceSubtle,
                                  onPressed: () => _applyDayPreset('WEEKDAYS'),
                                ),
                                const SizedBox(width: 6),
                                ActionChip(
                                  label: const Text('Daily (Mon-Sat)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  backgroundColor: AppTheme.surfaceSubtle,
                                  onPressed: () => _applyDayPreset('DAILY'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Multi-select Day Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _allWeekdays.map((day) {
                              final isSelected = _selectedDays.contains(day['key']);
                              return FilterChip(
                                label: Text(day['short']!),
                                selected: isSelected,
                                selectedColor: AppTheme.electricCobalt,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textBody,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                checkmarkColor: Colors.white,
                                backgroundColor: AppTheme.surfaceSubtle,
                                side: BorderSide(color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedDays.add(day['key']!);
                                    } else {
                                      _selectedDays.remove(day['key']!);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // Start Time & End Time Pickers
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: _pickStartTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderSubtle),
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppTheme.surfaceSubtle,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start Time', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule, size: 16, color: AppTheme.electricCobalt),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTimeOfDay(_startTime),
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickEndTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.borderSubtle),
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppTheme.surfaceSubtle,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('End Time', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.timelapse_rounded, size: 16, color: Color(0xFF7C3AED)),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTimeOfDay(_endTime),
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Classroom / Venue Input
                          TextFormField(
                            controller: _roomNameController,
                            decoration: const InputDecoration(
                              labelText: 'Classroom / Venue Name',
                              hintText: 'e.g. Smart Class 101 / Physics Lab A',
                              prefixIcon: Icon(Icons.room_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Teacher / Faculty Assignment
                          if (_staffList.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              initialValue: _selectedStaffId,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Faculty / Teacher',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('Default / Assign Later')),
                                ..._staffList.map((s) {
                                  final id = int.tryParse((s['staff_id'] ?? s['id'] ?? '').toString()) ?? 1;
                                  final fName = s['first_name'] ?? '';
                                  final lName = s['last_name'] ?? '';
                                  final role = s['designation'] ?? s['role'] ?? 'Teacher';
                                  return DropdownMenuItem<int>(
                                    value: id,
                                    child: Text('$fName $lName ($role)'.trim()),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedStaffId = val;
                                });
                              },
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _teacherNameController,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Teacher / Faculty',
                                hintText: 'e.g. Prof. R.K. Sharma',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Virtual Meeting Link
                          TextFormField(
                            controller: _meetUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Live Class / Google Meet Link',
                              hintText: 'e.g. https://meet.google.com/abc-defg-hij',
                              prefixIcon: Icon(Icons.videocam_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: AppTheme.surfaceWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(isEditing ? Icons.save_rounded : Icons.add_task_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing ? 'Save Batch & Schedule' : 'Create Batch & Schedule',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
