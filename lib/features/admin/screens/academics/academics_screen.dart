import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import 'widgets/batches_list_view.dart';
import 'widgets/curriculum_list_view.dart';
import 'widgets/subjects_list_view.dart';
import 'add_batch_screen.dart';
import 'add_subject_screen.dart';
import 'add_curriculum_screen.dart';
import 'academic_structure_screen.dart';
import 'curriculum_hierarchy_screen.dart';
import 'course_syllabus_builder_screen.dart';
import 'lesson_plans_screen.dart';

class AcademicsScreen extends StatefulWidget {
  const AcademicsScreen({super.key});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget? _buildFloatingActionButton() {
    String label;
    IconData icon;
    Widget Function() screenBuilder;

    switch (_tabController.index) {
      case 0:
        label = 'Add Batch';
        icon = Icons.add_circle_outline_rounded;
        screenBuilder = () => const AddBatchScreen();
        break;
      case 1:
        label = 'Add Subject';
        icon = Icons.auto_stories_rounded;
        screenBuilder = () => const AddSubjectScreen();
        break;
      case 2:
        label = 'Add Curriculum';
        icon = Icons.menu_book_rounded;
        screenBuilder = () => const AddCurriculumScreen();
        break;
      default:
        return null;
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.level3Shadow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screenBuilder()),
          );

          if (result == true) {
            setState(() {});
          }
        },
        elevation: 0,
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: AppTheme.surfaceWhite,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Academics', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Academic Tools',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (val) {
              if (val == 'structure') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AcademicStructureScreen()),
                );
              } else if (val == 'syllabus') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CurriculumHierarchyScreen()),
                );
              } else if (val == 'course_builder') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CourseSyllabusBuilderScreen()),
                );
              } else if (val == 'lesson_plans') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LessonPlansScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'structure',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: AppTheme.electricCobalt, size: 18),
                    SizedBox(width: 10),
                    Text('Academic Years & Grades'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'syllabus',
                child: Row(
                  children: [
                    Icon(Icons.layers, color: AppTheme.electricCobalt, size: 18),
                    SizedBox(width: 10),
                    Text('Chapters & Topics Syllabus'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'course_builder',
                child: Row(
                  children: [
                    Icon(Icons.link, color: AppTheme.electricCobalt, size: 18),
                    SizedBox(width: 10),
                    Text('Course Syllabus Builder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'lesson_plans',
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in_rounded, color: AppTheme.electricCobalt, size: 18),
                    SizedBox(width: 10),
                    Text('Faculty Lesson Plans'),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: ThemeToggleSwitch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          labelStyle: Theme.of(context).textTheme.titleMedium,
          tabs: const [
            Tab(icon: Icon(Icons.class_outlined), text: 'Batches'),
            Tab(icon: Icon(Icons.auto_stories_outlined), text: 'Subjects'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Curriculum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BatchesListView(key: UniqueKey()),
          SubjectsListView(key: UniqueKey()),
          CurriculumListView(key: UniqueKey()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}

