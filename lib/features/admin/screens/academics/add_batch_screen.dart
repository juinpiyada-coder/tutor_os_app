import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/academics_service.dart';
import '../../services/academic_structure_service.dart';
import '../../services/settings_service.dart';

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

  int? _selectedCourseId;
  int? _selectedYearId;
  int? _selectedGradeId;
  int? _selectedSubjectId;
  int? _selectedBranchId;
  String _status = 'ACTIVE';

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _academicYears = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _branches = [];
  
  bool _isLoading = false;
  bool _isFetchingRelations = true;

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController(text: widget.existingBatch?['batch_name'] ?? '');
    _batchCodeController = TextEditingController(text: widget.existingBatch?['batch_code'] ?? '');
    _maxStudentsController = TextEditingController(text: (widget.existingBatch?['max_students'] ?? 30).toString());
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
      ]);

      if (mounted) {
        setState(() {
          _courses = results[0];
          _academicYears = results[1];
          _grades = results[2];
          _subjects = results[3];
          _branches = results[4];

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
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.existingBatch != null;

      try {
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
        };
        
        if (isEditing) {
          final batchId = int.tryParse((widget.existingBatch!['batch_id'] ?? 1).toString()) ?? 1;
          await AcademicsService.updateBatch(batchId, data);
        } else {
          await AcademicsService.addBatch(data);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'Batch updated successfully' : 'Batch created successfully', style: const TextStyle(color: AppTheme.surfaceWhite)),
              backgroundColor: AppTheme.successText,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Batch' : 'Add Batch'),
      ),
      body: _isFetchingRelations 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _batchNameController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Name',
                        hintText: 'e.g. JEE Main 2027 Morning',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Batch name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _batchCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Code',
                        hintText: 'e.g. JEE27M',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Batch code is required' : null,
                    ),
                    const SizedBox(height: 16),

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
                      const SizedBox(height: 16),
                    ],

                    // Relational ER Selector: Grade / Class
                    if (_grades.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedGradeId,
                        decoration: const InputDecoration(
                          labelText: 'Grade / Class Level',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        items: _grades.map((g) {
                          final id = int.tryParse(g['grade_id']?.toString() ?? '1') ?? 1;
                          final name = g['grade_name'] ?? g['grade_code'] ?? '';
                          return DropdownMenuItem<int>(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedGradeId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Relational ER Selector: Subject
                    if (_subjects.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Subject Curriculum',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                        items: _subjects.map((s) {
                          final id = int.tryParse(s['subject_id']?.toString() ?? '1') ?? 1;
                          final name = s['subject_name'] ?? s['subject_code'] ?? '';
                          return DropdownMenuItem<int>(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSubjectId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Relational ER Selector: Academic Year
                    if (_academicYears.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedYearId,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        items: _academicYears.map((ay) {
                          final id = int.tryParse(ay['academic_year_id']?.toString() ?? '1') ?? 1;
                          final name = ay['year_name'] ?? ay['year_code'] ?? '';
                          return DropdownMenuItem<int>(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedYearId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Relational ER Selector: Branch
                    if (_branches.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedBranchId,
                        decoration: const InputDecoration(
                          labelText: 'Campus Branch',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: _branches.map((b) {
                          final id = int.tryParse(b['branch_id']?.toString() ?? '1') ?? 1;
                          final name = b['branch_name'] ?? '';
                          return DropdownMenuItem<int>(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedBranchId = val),
                      ),
                      const SizedBox(height: 16),
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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: AppTheme.surfaceWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2))
                          : Text(isEditing ? 'Save Changes' : 'Create Batch', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
