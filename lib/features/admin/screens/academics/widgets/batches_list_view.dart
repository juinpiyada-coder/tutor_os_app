import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../services/academics_service.dart';
import '../../../services/directory_service.dart';
import '../add_batch_screen.dart';

class BatchesListView extends StatefulWidget {
  const BatchesListView({super.key});

  @override
  State<BatchesListView> createState() => _BatchesListViewState();
}

class _BatchesListViewState extends State<BatchesListView> {
  late Future<List<Map<String, dynamic>>> _batchesFuture;

  @override
  void initState() {
    super.initState();
    _batchesFuture = AcademicsService.getBatches();
  }

  void _confirmDeleteBatch(Map<String, dynamic> batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Batch?'),
          ],
        ),
        content: Text('Are you sure you want to delete batch "${batch['batch_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final batchId = int.tryParse((batch['batch_id'] ?? 1).toString()) ?? 1;
              await AcademicsService.deleteBatch(batchId);
              if (mounted) {
                setState(() {
                  _batchesFuture = AcademicsService.getBatches();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Batch deleted successfully.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openBatchTeacherModal(Map<String, dynamic> batch) {
    final batchId = int.tryParse((batch['batch_id'] ?? 1).toString()) ?? 1;
    final batchName = batch['batch_name'] ?? '';
    final batchCode = batch['batch_code'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _BatchTeacherSheet(
          batchId: batchId,
          batchName: batchName,
          batchCode: batchCode,
          onUpdated: () {
            setState(() {
              _batchesFuture = AcademicsService.getBatches();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _batchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading batches:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.urgentText),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 64, color: AppTheme.borderSubtle),
                const SizedBox(height: 16),
                Text('No batches found.', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        final batches = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: batches.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final batch = batches[index];
            final status = batch['status'] ?? '';
            final isActive = status == 'ACTIVE';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.level1Shadow,
                border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.batchBg,
                        child: Text(
                          (batch['batch_name'] ?? '').toString().isNotEmpty ? (batch['batch_name']).toString().substring(0, 1).toUpperCase() : '',
                          style: const TextStyle(
                            color: AppTheme.batchText,
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
                                    batch['batch_name'] ?? '',
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
                              'Code: ${batch['batch_code'] ?? ''} • Max Capacity: ${batch['max_students'] ?? '-'} Students',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Teacher Mapping Action
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.academicText,
                          backgroundColor: AppTheme.academicBg,
                          side: const BorderSide(color: Colors.transparent),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.people_outline_rounded, size: 15),
                        label: const Text('Faculty & Lead', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _openBatchTeacherModal(batch),
                      ),
                      Row(
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
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddBatchScreen(existingBatch: batch)),
                              );
                              if (res == true && mounted) {
                                setState(() {
                                  _batchesFuture = AcademicsService.getBatches();
                                });
                              }
                            },
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
                            onPressed: () => _confirmDeleteBatch(batch),
                          ),
                        ],
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

class _BatchTeacherSheet extends StatefulWidget {
  final int batchId;
  final String batchName;
  final String batchCode;
  final VoidCallback onUpdated;

  const _BatchTeacherSheet({
    required this.batchId,
    required this.batchName,
    required this.batchCode,
    required this.onUpdated,
  });

  @override
  State<_BatchTeacherSheet> createState() => _BatchTeacherSheetState();
}

class _BatchTeacherSheetState extends State<_BatchTeacherSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _assignedTeachers = [];
  List<Map<String, dynamic>> _availableStaff = [];
  int? _selectedStaffId;
  bool _setAsPrimary = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await AcademicsService.getBatchTeachers(widget.batchId);
      final staff = await DirectoryService.getStaff();
      if (mounted) {
        setState(() {
          _assignedTeachers = teachers;
          _availableStaff = staff;
          _isLoading = false;
          _selectedStaffId = null;
          _setAsPrimary = teachers.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignFaculty() async {
    if (_selectedStaffId == null) return;
    setState(() => _isSaving = true);
    final ok = await AcademicsService.assignTeacherToBatch(
      batchId: widget.batchId,
      staffId: _selectedStaffId!,
      isPrimary: _setAsPrimary,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty assigned to batch successfully!'),
          backgroundColor: AppTheme.successText,
        ),
      );
      widget.onUpdated();
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to assign faculty.'),
          backgroundColor: AppTheme.urgentText,
        ),
      );
    }
  }

  Future<void> _togglePrimary(int staffId, bool currentPrimary) async {
    setState(() => _isSaving = true);
    final ok = await AcademicsService.updateTeacherBatchRole(
      batchId: widget.batchId,
      staffId: staffId,
      isPrimary: !currentPrimary,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      widget.onUpdated();
      _loadData();
    }
  }

  Future<void> _removeFaculty(int staffId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unassign Faculty?'),
        content: Text('Remove $name from ${widget.batchName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      final ok = await AcademicsService.removeTeacherFromBatch(
        batchId: widget.batchId,
        staffId: staffId,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty unassigned from batch.'), backgroundColor: AppTheme.successText),
        );
        widget.onUpdated();
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceCard : Colors.white;

    // Filter available staff to exclude already assigned ones
    final assignedIds = _assignedTeachers.map((t) => int.tryParse((t['staff_id'] ?? 0).toString()) ?? 0).toSet();
    final selectableStaff = _availableStaff.where((s) {
      final sId = int.tryParse((s['user_id'] ?? s['staff_id'] ?? 0).toString()) ?? 0;
      return !assignedIds.contains(sId);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.academicBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_rounded, color: AppTheme.academicText, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Batch Faculty Mapping',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextHeading : AppTheme.textHeading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.batchName} (${widget.batchCode})',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt)),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currently Assigned Faculty List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ASSIGNED INSTRUCTORS (${_assignedTeachers.length})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_assignedTeachers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            'No faculty mapped to this batch yet.\nAssign a lead teacher below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ..._assignedTeachers.map((t) {
                        final staffId = int.tryParse((t['staff_id'] ?? 0).toString()) ?? 0;
                        final name = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim();
                        final isPrimary = t['is_primary'] == 1 || t['is_primary'] == true || t['is_primary'] == '1';
                        final designation = t['designation'] ?? '';
                        final email = t['email'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPrimary
                                ? (isDark ? const Color(0xFF1E2A4A) : const Color(0xFFF0F7FF))
                                : (isDark ? AppTheme.darkSurfaceSubtle : AppTheme.canvasBackground),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPrimary
                                  ? AppTheme.electricCobalt.withValues(alpha: 0.6)
                                  : AppTheme.borderSubtle.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isPrimary ? AppTheme.electricCobalt : AppTheme.academicBg,
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '',
                                  style: TextStyle(
                                    color: isPrimary ? Colors.white : AppTheme.academicText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isDark ? AppTheme.darkTextHeading : AppTheme.textHeading,
                                          ),
                                        ),
                                        if (isPrimary) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.electricCobalt,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'LEAD',
                                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$designation ${email.isNotEmpty ? '• $email' : ''}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Primary toggle button
                              IconButton(
                                icon: Icon(
                                  isPrimary ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: isPrimary ? const Color(0xFFEAB308) : AppTheme.textMuted,
                                ),
                                tooltip: isPrimary ? 'Primary Faculty' : 'Make Primary Lead',
                                onPressed: _isSaving ? null : () => _togglePrimary(staffId, isPrimary),
                              ),
                              // Unassign button
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.urgentText),
                                tooltip: 'Unassign',
                                onPressed: _isSaving ? null : () => _removeFaculty(staffId, name),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Add / Assign New Faculty Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Assign New Faculty to Batch',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedStaffId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Select Faculty / Teacher',
                              filled: true,
                              fillColor: cardBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: selectableStaff.map((s) {
                              final id = int.tryParse((s['user_id'] ?? s['staff_id'] ?? 1).toString()) ?? 1;
                              final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                              final designation = s['designation'] ?? s['role_code'] ?? '';
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text('$name ($designation)', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedStaffId = val),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Set as Primary / Lead Instructor', style: TextStyle(fontSize: 13)),
                            value: _setAsPrimary,
                            onChanged: (val) => setState(() => _setAsPrimary = val ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.electricCobalt,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: (_selectedStaffId == null || _isSaving) ? null : _assignFaculty,
                            icon: _isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: const Text('Assign to Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

