import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../services/academics_service.dart';
import '../add_curriculum_screen.dart';

class CurriculumListView extends StatefulWidget {
  const CurriculumListView({super.key});

  @override
  State<CurriculumListView> createState() => _CurriculumListViewState();
}

class _CurriculumListViewState extends State<CurriculumListView> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    setState(() {
      _coursesFuture = AcademicsService.getCourses();
    });
  }

  Future<void> _navigateToAddOrEdit([Map<String, dynamic>? course]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddCurriculumScreen(existingCourse: course)),
    );

    if (result == true) {
      _loadCourses();
    }
  }

  void _confirmDeleteCourse(Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Curriculum?'),
          ],
        ),
        content: Text('Are you sure you want to delete curriculum "${course['course_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final courseId = int.tryParse((course['course_id'] ?? 1).toString()) ?? 1;
              await AcademicsService.deleteCourse(courseId);
              if (mounted) {
                _loadCourses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Curriculum deleted successfully.'), backgroundColor: AppTheme.successText),
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
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading curriculum:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.urgentText),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 64, color: AppTheme.borderSubtle),
                const SizedBox(height: 16),
                Text('No curriculum/courses found.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddOrEdit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Curriculum'),
                ),
              ],
            ),
          );
        }

        final courses = snapshot.data!;
        return RefreshIndicator(
          color: AppTheme.electricCobalt,
          onRefresh: () async => _loadCourses(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = courses[index];
              final status = course['status'] ?? '';
              final isActive = status == 'ACTIVE';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.level1Shadow,
                  border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.academicBg,
                          child: Text(
                            (course['course_name'] ?? '').toString().isNotEmpty ? (course['course_name']).toString().substring(0, 1).toUpperCase() : '',
                            style: const TextStyle(
                              color: AppTheme.academicText,
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
                                      course['course_name'] ?? '',
                                      style: Theme.of(context).textTheme.titleMedium,
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
                                'Code: ${course['course_code'] ?? ''}${course['duration_months'] != null ? ' • ${course['duration_months']} Months' : ''}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              if (course['description'] != null && course['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  course['description'],
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _navigateToAddOrEdit(course),
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
                          onPressed: () => _confirmDeleteCourse(course),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

