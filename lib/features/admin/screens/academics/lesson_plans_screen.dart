import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/universal_owner_header.dart';
import '../../services/academics_service.dart';
import '../../services/academic_structure_service.dart';

class LessonPlansScreen extends StatefulWidget {
  final int? initialBatchId;
  final VoidCallback? onOpenDrawer;
  const LessonPlansScreen({super.key, this.initialBatchId, this.onOpenDrawer});

  @override
  State<LessonPlansScreen> createState() => _LessonPlansScreenState();
}

class _LessonPlansScreenState extends State<LessonPlansScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lessonPlans = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _topics = [];

  int? _selectedBatchFilter;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _selectedBatchFilter = widget.initialBatchId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await AcademicsService.getLessonPlans(
        batchId: _selectedBatchFilter,
        status: _selectedStatus,
      );
      final batches = await AcademicsService.getBatches();
      final topics = await AcademicStructureService.getTopics();

      if (mounted) {
        setState(() {
          _lessonPlans = plans;
          _batches = batches;
          _topics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAddEditModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(text: item?['title'] ?? '');
    final objectivesCtrl = TextEditingController(text: item?['objectives'] ?? '');
    
    int? batchId = int.tryParse((item?['batch_id'] ?? _selectedBatchFilter ?? (_batches.isNotEmpty ? _batches.first['batch_id'] : 1)).toString());
    int? topicId = item?['topic_id'] != null ? int.tryParse(item!['topic_id'].toString()) : null;
    String status = item?['status'] ?? 'PLANNED';
    DateTime plannedDate = item?['planned_date'] != null 
        ? DateTime.tryParse(item!['planned_date'].toString()) ?? DateTime.now()
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.academicBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.academicText, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEdit ? 'Edit Lesson Plan' : 'Create Lesson Plan',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextHeading : AppTheme.textHeading,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Batch Selector
                    DropdownButtonFormField<int>(
                      initialValue: batchId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Assigned Batch *',
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _batches.map((b) {
                        final bId = int.tryParse((b['batch_id'] ?? 1).toString()) ?? 1;
                        return DropdownMenuItem<int>(
                          value: bId,
                          child: Text('${b['batch_name']} (${b['batch_code'] ?? ''})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => batchId = val),
                    ),
                    const SizedBox(height: 12),

                    // Topic Selector (Optional)
                    DropdownButtonFormField<int?>(
                      initialValue: topicId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Curriculum Topic (Optional)',
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('— None (General Lesson) —', style: TextStyle(color: AppTheme.textMuted)),
                        ),
                        ..._topics.map((t) {
                          final tId = int.tryParse((t['topic_id'] ?? 1).toString()) ?? 1;
                          return DropdownMenuItem<int?>(
                            value: tId,
                            child: Text('${t['topic_name']} (${t['topic_code'] ?? ''})', overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (val) => setModalState(() => topicId = val),
                    ),
                    const SizedBox(height: 12),

                    // Lesson Title
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Lesson Title *',
                        hintText: 'e.g. Newton\'s 2nd Law & Friction Applications',
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Objectives
                    TextField(
                      controller: objectivesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Lesson Objectives & Notes',
                        hintText: 'Key concepts to cover, homework pointers, demonstrations...',
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date & Status Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: plannedDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setModalState(() => plannedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Planned Date',
                                filled: true,
                                fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                              ),
                              child: Text(
                                '${plannedDate.year}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              filled: true,
                              fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PLANNED', child: Text('PLANNED')),
                              DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                              DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                            ],
                            onChanged: (val) => setModalState(() => status = val ?? 'PLANNED'),
                          ),
                        ),
                      ],
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
                        if (titleCtrl.text.trim().isEmpty || batchId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a lesson title and select a batch.')),
                          );
                          return;
                        }

                        Navigator.pop(modalCtx);
                        final payload = {
                          'batch_id': batchId,
                          'topic_id': topicId,
                          'title': titleCtrl.text.trim(),
                          'objectives': objectivesCtrl.text.trim(),
                          'planned_date': '${plannedDate.year}-${plannedDate.month.toString().padLeft(2, '0')}-${plannedDate.day.toString().padLeft(2, '0')}',
                          'status': status,
                        };

                        if (isEdit) {
                          final id = int.tryParse((item['lesson_plan_id'] ?? 1).toString()) ?? 1;
                          await AcademicsService.updateLessonPlan(id, payload);
                        } else {
                          await AcademicsService.createLessonPlan(payload);
                        }

                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Lesson plan updated successfully!' : 'Lesson plan created successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Create Lesson Plan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Lesson Plan?'),
        content: Text('Are you sure you want to delete "${item['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final id = int.tryParse((item['lesson_plan_id'] ?? 1).toString()) ?? 1;
              await AcademicsService.deleteLessonPlan(id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson plan removed.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _cycleStatus(Map<String, dynamic> item) async {
    final curStatus = item['status'] ?? 'PLANNED';
    String nextStatus;
    if (curStatus == 'PLANNED') {
      nextStatus = 'IN_PROGRESS';
    } else if (curStatus == 'IN_PROGRESS') {
      nextStatus = 'COMPLETED';
    } else {
      nextStatus = 'PLANNED';
    }

    final id = int.tryParse((item['lesson_plan_id'] ?? 1).toString()) ?? 1;
    await AcademicsService.updateLessonPlan(id, {'status': nextStatus});
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        title: 'Faculty Lesson Plans',
        subtitle: 'Curriculum coverage, lesson delivery & topics',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : Column(
              children: [
                // Filter Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                  child: Column(
                    children: [
                      // Batch Dropdown Filter
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: _selectedBatchFilter,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Filter by Batch',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All Batches'),
                                ),
                                ..._batches.map((b) {
                                  final id = int.tryParse((b['batch_id'] ?? 1).toString()) ?? 1;
                                  return DropdownMenuItem<int?>(
                                    value: id,
                                    child: Text('${b['batch_name']} (${b['batch_code'] ?? ''})', overflow: TextOverflow.ellipsis),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedBatchFilter = val);
                                _loadData();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Status Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'].map((st) {
                            final isSel = _selectedStatus == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(st == 'ALL' ? 'All Plans' : st.replaceAll('_', ' ')),
                                selected: isSel,
                                selectedColor: AppTheme.electricCobalt,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : (isDark ? AppTheme.darkTextHeading : AppTheme.textHeading),
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _selectedStatus = st);
                                    _loadData();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Plans List
                Expanded(
                  child: _lessonPlans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_outlined, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'No lesson plans found.',
                                style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.electricCobalt,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create First Lesson Plan'),
                                onPressed: () => _openAddEditModal(),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lessonPlans.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _lessonPlans[index];
                            final status = item['status'] ?? '';
                            final isCompleted = status == 'COMPLETED';
                            final inProgress = status == 'IN_PROGRESS';

                            Color statusColor = isCompleted
                                ? AppTheme.successText
                                : (inProgress ? const Color(0xFFEAB308) : AppTheme.electricCobalt);
                            Color statusBg = isCompleted
                                ? AppTheme.successBg
                                : (inProgress ? const Color(0xFFFEF9C3) : const Color(0xFFEFF6FF));

                            if (status == 'CANCELLED') {
                              statusColor = AppTheme.urgentText;
                              statusBg = AppTheme.urgentBg;
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.35)),
                                boxShadow: AppTheme.level1Shadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isCompleted
                                              ? Icons.check_circle_rounded
                                              : (inProgress ? Icons.timelapse_rounded : Icons.calendar_today_rounded),
                                          color: statusColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item['title'] ?? '',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? AppTheme.darkTextHeading : AppTheme.textHeading,
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => _cycleStatus(item),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusBg,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          status.replaceAll('_', ' '),
                                                          style: TextStyle(
                                                            color: statusColor,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Icon(Icons.sync_alt_rounded, size: 10, color: statusColor),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.academicBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    item['batch_name'] ?? '',
                                                    style: const TextStyle(color: AppTheme.academicText, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                if (item['topic_name'] != null) ...[
                                                  const SizedBox(width: 6),
                                                  Text('• ${item['topic_name']}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item['objectives'] != null && item['objectives'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      item['objectives'].toString(),
                                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textBody),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.event_outlined, size: 14, color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Planned: ${item['planned_date'] ?? ''}',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.electricCobalt),
                                            onPressed: () => _openAddEditModal(item),
                                            tooltip: 'Edit Plan',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.urgentText),
                                            onPressed: () => _confirmDelete(item),
                                            tooltip: 'Delete Plan',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(),
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Lesson Plan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
