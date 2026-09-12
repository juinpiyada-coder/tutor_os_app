import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/academics_service.dart';
import '../../services/academic_structure_service.dart';

class CurriculumHierarchyScreen extends StatefulWidget {
  final int? initialSubjectId;
  const CurriculumHierarchyScreen({super.key, this.initialSubjectId});

  @override
  State<CurriculumHierarchyScreen> createState() => _CurriculumHierarchyScreenState();
}

class _CurriculumHierarchyScreenState extends State<CurriculumHierarchyScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  int? _selectedSubjectId;
  List<Map<String, dynamic>> _chapters = [];
  final Map<int, List<Map<String, dynamic>>> _topicsMap = {};
  final Set<int> _expandedChapters = {};

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.initialSubjectId;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final subjects = await AcademicsService.getSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        if (_selectedSubjectId == null && subjects.isNotEmpty) {
          _selectedSubjectId = int.tryParse(subjects.first['subject_id']?.toString() ?? '0');
        }
      });
      if (_selectedSubjectId != null && _selectedSubjectId! > 0) {
        await _loadChapters(_selectedSubjectId!);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadChapters(int subjectId) async {
    setState(() => _isLoading = true);
    final chapters = await AcademicStructureService.getChapters(subjectId);
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTopics(int chapterId) async {
    final topics = await AcademicStructureService.getTopics(chapterId);
    if (mounted) {
      setState(() {
        _topicsMap[chapterId] = topics;
      });
    }
  }

  // ===========================================================================
  // MODAL: CHAPTER
  // ===========================================================================
  void _openChapterModal([Map<String, dynamic>? item]) {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }
    final isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['chapter_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['chapter_name'] ?? '');
    final seqCtrl = TextEditingController(text: (item?['sequence_no'] ?? (_chapters.length + 1)).toString());
    String status = item?['status'] ?? 'ACTIVE';

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
                          isEdit ? 'Edit Chapter' : 'Add Chapter',
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
                        labelText: 'Chapter Code (e.g. CH-01)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Chapter Name (e.g. Thermodynamics)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sequence Order',
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
                          if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'subject_id': _selectedSubjectId,
                            'chapter_code': codeCtrl.text.trim(),
                            'chapter_name': nameCtrl.text.trim(),
                            'sequence_no': int.tryParse(seqCtrl.text.trim()) ?? 1,
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await AcademicStructureService.updateChapter(
                              int.parse(item['chapter_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await AcademicStructureService.addChapter(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Chapter saved!' : 'Action failed')),
                            );
                            _loadChapters(_selectedSubjectId!);
                          }
                        },
                        child: Text(isEdit ? 'Update Chapter' : 'Create Chapter'),
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
  // MODAL: TOPIC
  // ===========================================================================
  void _openTopicModal(int chapterId, [Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['topic_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['topic_name'] ?? '');
    final seqCtrl = TextEditingController(
      text: (item?['sequence_no'] ?? ((_topicsMap[chapterId]?.length ?? 0) + 1)).toString(),
    );
    String status = item?['status'] ?? 'ACTIVE';

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
                          isEdit ? 'Edit Topic' : 'Add Topic',
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
                        labelText: 'Topic Code (e.g. TOP-01)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Topic Name (e.g. First Law of Thermodynamics)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: seqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Sequence Order',
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
                          if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'chapter_id': chapterId,
                            'topic_code': codeCtrl.text.trim(),
                            'topic_name': nameCtrl.text.trim(),
                            'sequence_no': int.tryParse(seqCtrl.text.trim()) ?? 1,
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await AcademicStructureService.updateTopic(
                              int.parse(item['topic_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await AcademicStructureService.addTopic(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Topic saved!' : 'Action failed')),
                            );
                            _loadTopics(chapterId);
                          }
                        },
                        child: Text(isEdit ? 'Update Topic' : 'Create Topic'),
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
          'Curriculum Syllabus',
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
      floatingActionButton: _selectedSubjectId != null
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
              onPressed: () => _openChapterModal(),
              icon: const Icon(Icons.add),
              label: const Text('Add Chapter'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSubjectSelector(isDark),
                Expanded(
                  child: _chapters.isEmpty
                      ? _buildEmptyChapters()
                      : RefreshIndicator(
                          onRefresh: () => _loadChapters(_selectedSubjectId!),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _chapters.length,
                            itemBuilder: (context, index) {
                              return _buildChapterCard(_chapters[index], isDark);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubjectSelector(bool isDark) {
    if (_subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
        child: const Text('No subjects found. Please add subjects first in Academics.'),
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
          const Icon(Icons.menu_book, color: AppTheme.electricCobalt, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedSubjectId,
                isExpanded: true,
                dropdownColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppTheme.textHeading,
                ),
                items: _subjects.map((sub) {
                  final subId = int.tryParse(sub['subject_id']?.toString() ?? '0') ?? 0;
                  return DropdownMenuItem<int>(
                    value: subId,
                    child: Text('${sub['subject_name']} (${sub['subject_code'] ?? ''})'),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != _selectedSubjectId) {
                    setState(() => _selectedSubjectId = newId);
                    _loadChapters(newId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChapters() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Chapters Yet for This Subject',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _openChapterModal(),
            icon: const Icon(Icons.add),
            label: const Text('Add Chapter 1'),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter, bool isDark) {
    final chapterId = int.tryParse(chapter['chapter_id']?.toString() ?? '0') ?? 0;
    final isExpanded = _expandedChapters.contains(chapterId);
    final topics = _topicsMap[chapterId] ?? [];
    final topicCount = int.tryParse(chapter['topic_count']?.toString() ?? '0') ?? topics.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
              child: Text(
                '${chapter['sequence_no'] ?? 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
              ),
            ),
            title: Text(
              chapter['chapter_name'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  chapter['chapter_code'] ?? '',
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkAcademicBg : AppTheme.academicBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$topicCount Topics',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.academicText),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedChapters.remove(chapterId);
                      } else {
                        _expandedChapters.add(chapterId);
                        _loadTopics(chapterId);
                      }
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'add_topic') {
                      _openTopicModal(chapterId);
                    } else if (val == 'edit') {
                      _openChapterModal(chapter);
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Chapter?'),
                          content: Text('Are you sure you want to delete ${chapter['chapter_name']}?'),
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
                      if (confirm == true && chapterId > 0) {
                        await AcademicStructureService.deleteChapter(chapterId);
                        _loadChapters(_selectedSubjectId!);
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'add_topic', child: Row(children: [Icon(Icons.add, size: 16, color: AppTheme.electricCobalt), SizedBox(width: 8), Text('Add Topic')])),
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit Chapter')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete Chapter', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? AppTheme.darkCanvasBackground.withValues(alpha: 0.5) : AppTheme.canvasBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Topics & Syllabus Units',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => _openTopicModal(chapterId),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Topic', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  if (topics.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No topics added yet',
                          style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    ...topics.map((topic) {
                      final topicId = int.tryParse(topic['topic_id']?.toString() ?? '0') ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                '${topic['sequence_no'] ?? 1}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic['topic_name'] ?? '',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : AppTheme.textHeading,
                                    ),
                                  ),
                                  Text(
                                    topic['topic_code'] ?? '',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _openTopicModal(chapterId, topic),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Topic?'),
                                    content: Text('Delete ${topic['topic_name']}?'),
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
                                if (confirm == true && topicId > 0) {
                                  await AcademicStructureService.deleteTopic(topicId);
                                  _loadTopics(chapterId);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
