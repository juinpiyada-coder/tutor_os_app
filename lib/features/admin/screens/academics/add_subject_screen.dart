import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/academics_service.dart';

class AddSubjectScreen extends StatefulWidget {
  final Map<String, dynamic>? existingSubject;
  const AddSubjectScreen({super.key, this.existingSubject});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectNameController;
  late final TextEditingController _subjectCodeController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subjectNameController = TextEditingController(text: widget.existingSubject?['subject_name'] ?? '');
    _subjectCodeController = TextEditingController(text: widget.existingSubject?['subject_code'] ?? '');
    _descriptionController = TextEditingController(text: widget.existingSubject?['description'] ?? '');
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.existingSubject != null;

      try {
        final data = {
          'subject_name': _subjectNameController.text.trim(),
          'subject_code': _subjectCodeController.text.trim().toUpperCase(),
          'description': _descriptionController.text.trim(),
        };

        bool success;
        if (isEditing) {
          final subjectId = int.tryParse((widget.existingSubject!['subject_id'] ?? 1).toString()) ?? 1;
          success = await AcademicsService.updateSubject(subjectId, data);
        } else {
          success = await AcademicsService.addSubject(data);
        }

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEditing ? 'Subject updated successfully' : 'Subject created successfully',
                  style: const TextStyle(color: AppTheme.surfaceWhite),
                ),
                backgroundColor: AppTheme.successText,
              ),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save subject. Please try again.', style: TextStyle(color: AppTheme.surfaceWhite)),
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
    final isEditing = widget.existingSubject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectNameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g. Physics, Advanced Mathematics',
                  prefixIcon: Icon(Icons.auto_stories_outlined, color: AppTheme.electricCobalt),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Subject name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subjectCodeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code',
                  hintText: 'e.g. PHY101, MATH202',
                  prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.electricCobalt),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value == null || value.trim().isEmpty ? 'Subject code is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description / Overview',
                  hintText: 'Key topics, curriculum objectives, syllabus outline...',
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
                        isEditing ? 'Save Changes' : 'Create Subject',
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
