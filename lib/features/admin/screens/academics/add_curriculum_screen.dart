import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/academics_service.dart';

class AddCurriculumScreen extends StatefulWidget {
  final Map<String, dynamic>? existingCourse;
  const AddCurriculumScreen({super.key, this.existingCourse});

  @override
  State<AddCurriculumScreen> createState() => _AddCurriculumScreenState();
}

class _AddCurriculumScreenState extends State<AddCurriculumScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseNameController;
  late final TextEditingController _courseCodeController;
  late final TextEditingController _durationMonthsController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _courseNameController = TextEditingController(text: widget.existingCourse?['course_name'] ?? '');
    _courseCodeController = TextEditingController(text: widget.existingCourse?['course_code'] ?? '');
    _durationMonthsController = TextEditingController(
      text: (widget.existingCourse?['duration_months'] ?? 12).toString(),
    );
    _descriptionController = TextEditingController(text: widget.existingCourse?['description'] ?? '');
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _durationMonthsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.existingCourse != null;

      try {
        final data = {
          'course_name': _courseNameController.text.trim(),
          'course_code': _courseCodeController.text.trim().toUpperCase(),
          'duration_months': int.tryParse(_durationMonthsController.text.trim()) ?? 12,
          'description': _descriptionController.text.trim(),
        };

        bool success;
        if (isEditing) {
          final courseId = int.tryParse((widget.existingCourse!['course_id'] ?? 1).toString()) ?? 1;
          success = await AcademicsService.updateCourse(courseId, data);
        } else {
          success = await AcademicsService.addCourse(data);
        }

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing ? 'Curriculum updated successfully' : 'Curriculum created successfully',
                  style: const TextStyle(color: AppTheme.surfaceWhite),
                ),
                backgroundColor: AppTheme.successText,
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save curriculum. Please try again.', style: TextStyle(color: AppTheme.surfaceWhite)),
                backgroundColor: AppTheme.urgentText,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e', style: const TextStyle(color: AppTheme.surfaceWhite)),
              backgroundColor: AppTheme.urgentText,
            ),
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
    final isEditing = widget.existingCourse != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Curriculum' : 'Add Curriculum'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Curriculum / Course Name',
                  hintText: 'e.g. 2-Year Integrated IIT-JEE Program',
                  prefixIcon: Icon(Icons.menu_book_outlined, color: AppTheme.electricCobalt),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Curriculum name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Curriculum Code',
                  hintText: 'e.g. JEE-INT-2YR',
                  prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.electricCobalt),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value == null || value.trim().isEmpty ? 'Curriculum code is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _durationMonthsController,
                decoration: const InputDecoration(
                  labelText: 'Duration (in Months)',
                  hintText: 'e.g. 12 or 24',
                  prefixIcon: Icon(Icons.calendar_month_outlined, color: AppTheme.electricCobalt),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Duration is required';
                  if (int.tryParse(value.trim()) == null) return 'Must be a valid number of months';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description / Syllabus Scope',
                  hintText: 'Target grades, subjects included, weekly schedule breakdown...',
                  alignLabelWithHint: true,
                ),
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
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Curriculum',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
