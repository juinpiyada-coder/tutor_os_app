import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../services/academics_service.dart';

class SubjectsListView extends StatefulWidget {
  const SubjectsListView({super.key});

  @override
  State<SubjectsListView> createState() => _SubjectsListViewState();
}

class _SubjectsListViewState extends State<SubjectsListView> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    setState(() {
      _subjectsFuture = AcademicsService.getSubjects();
    });
  }

  void _openSubjectFormModal({Map<String, dynamic>? existingSubject}) {
    final isEditing = existingSubject != null;
    final nameController = TextEditingController(text: existingSubject?['subject_name'] ?? '');
    final codeController = TextEditingController(text: existingSubject?['subject_code'] ?? '');
    final descController = TextEditingController(text: existingSubject?['description'] ?? '');

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
                      isEditing ? 'Edit Subject' : 'Add New Subject',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'e.g. Physics, Advanced Mathematics',
                    prefixIcon: Icon(Icons.menu_book_outlined, color: AppTheme.electricCobalt),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    hintText: 'e.g. PHY101, MATH202',
                    prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.electricCobalt),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description / Curriculum Overview',
                    hintText: 'Key areas covered, syllabus objectives, etc.',
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
                    if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty) return;
                    final payload = {
                      'subject_name': nameController.text.trim(),
                      'subject_code': codeController.text.trim().toUpperCase(),
                      'description': descController.text.trim(),
                    };

                    if (isEditing) {
                      final subId = int.tryParse((existingSubject['subject_id'] ?? 1).toString()) ?? 1;
                      await AcademicsService.updateSubject(subId, payload);
                    } else {
                      await AcademicsService.addSubject(payload);
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadSubjects();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Subject updated successfully!' : 'Subject added to academic curriculum!'),
                        backgroundColor: AppTheme.successText,
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Subject', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteSubject(Map<String, dynamic> subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Subject?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${subject['subject_name']}"? Associated chapters and questions may be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final subId = int.tryParse((subject['subject_id'] ?? 1).toString()) ?? 1;
              await AcademicsService.deleteSubject(subId);
              if (mounted) {
                _loadSubjects();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject removed successfully.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading subjects:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.urgentText),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_outlined, size: 64, color: AppTheme.borderSubtle),
                const SizedBox(height: 16),
                Text('No subjects created yet.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _openSubjectFormModal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Subject'),
                ),
              ],
            ),
          );
        }

        final subjects = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            final status = subject['status'] ?? '';
            final isActive = status == 'ACTIVE';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.level1Shadow,
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.surfaceSubtle,
                        child: Text(
                          (subject['subject_name'] ?? '').toString().isNotEmpty ? (subject['subject_name']).toString().substring(0, 1).toUpperCase() : '',
                          style: const TextStyle(
                            color: AppTheme.electricCobalt,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject['subject_name'] ?? '',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppTheme.successBg : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: Text(
                                    status,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isActive ? AppTheme.successText : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${subject['subject_code'] ?? ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                            if (subject['description'] != null && subject['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                subject['description'],
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
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
                        onPressed: () => _openSubjectFormModal(existingSubject: subject),
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
                        onPressed: () => _confirmDeleteSubject(subject),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
