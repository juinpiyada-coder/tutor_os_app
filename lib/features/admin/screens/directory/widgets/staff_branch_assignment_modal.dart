import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../services/people_service.dart';

class StaffBranchAssignmentModal extends StatefulWidget {
  final Map<String, dynamic> staff;
  const StaffBranchAssignmentModal({super.key, required this.staff});

  static Future<void> show(BuildContext context, Map<String, dynamic> staff) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StaffBranchAssignmentModal(staff: staff),
    );
  }

  @override
  State<StaffBranchAssignmentModal> createState() => _StaffBranchAssignmentModalState();
}

class _StaffBranchAssignmentModalState extends State<StaffBranchAssignmentModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignedBranches = [];
  List<Map<String, dynamic>> _allBranches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final staffId = int.tryParse(widget.staff['staff_id']?.toString() ?? '0') ?? 0;
    final assigned = await PeopleService.getStaffBranches(staffId);
    final all = await PeopleService.getBranches();
    if (mounted) {
      setState(() {
        _assignedBranches = assigned;
        _allBranches = all;
        _isLoading = false;
      });
    }
  }

  void _openAddBranchSheet() {
    final staffId = int.tryParse(widget.staff['staff_id']?.toString() ?? '0') ?? 0;
    final assignedIds = _assignedBranches.map((b) => int.tryParse(b['branch_id']?.toString() ?? '0')).toSet();
    final available = _allBranches.where((b) {
      final bId = int.tryParse(b['branch_id']?.toString() ?? '0');
      return !assignedIds.contains(bId);
    }).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff is already assigned to all campus branches!')),
      );
      return;
    }

    int? selectedBranchId = int.tryParse(available.first['branch_id']?.toString() ?? '0');
    bool isPrimary = _assignedBranches.isEmpty;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Campus Branch',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedBranchId,
                    decoration: InputDecoration(
                      labelText: 'Select Campus Branch',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: available.map((b) {
                      final bId = int.tryParse(b['branch_id']?.toString() ?? '0') ?? 0;
                      return DropdownMenuItem<int>(
                        value: bId,
                        child: Text('${b['branch_name']} (${b['branch_code'] ?? 'BR'})'),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedBranchId = val),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as Primary Branch'),
                    value: isPrimary,
                    onChanged: (val) => setModalState(() => isPrimary = val),
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
                        if (selectedBranchId == null) return;
                        Navigator.pop(modalCtx);
                        final success = await PeopleService.assignStaffBranch(
                          staffId: staffId,
                          branchId: selectedBranchId!,
                          isPrimary: isPrimary,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Branch assigned!' : 'Failed to assign')),
                          );
                          _loadData();
                        }
                      },
                      child: const Text('Assign Branch'),
                    ),
                  ),
                ],
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
    final staffName = '${widget.staff['first_name'] ?? 'Staff'} ${widget.staff['last_name'] ?? ''}'.trim();
    final staffId = int.tryParse(widget.staff['staff_id']?.toString() ?? '0') ?? 0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Branch Allocation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textHeading,
                      ),
                    ),
                    Text(
                      staffName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Branches (${_assignedBranches.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.textHeading,
                ),
              ),
              TextButton.icon(
                onPressed: _openAddBranchSheet,
                icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                label: const Text('Assign Branch'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assignedBranches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apartment_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No branches assigned to this staff member.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _openAddBranchSheet,
                              child: const Text('Assign Campus Branch'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _assignedBranches.length,
                        itemBuilder: (context, index) {
                          final b = _assignedBranches[index];
                          final bId = int.tryParse(b['branch_id']?.toString() ?? '0') ?? 0;
                          final bName = b['branch_name'] ?? 'Branch #$bId';
                          final bCode = b['branch_code'] ?? 'BR';
                          final isPrimary = b['is_primary'] == 1 || b['is_primary'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
                              ),
                            ),
                            color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
                                child: const Icon(Icons.business, color: AppTheme.electricCobalt, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Text(bName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (isPrimary) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Primary', style: TextStyle(fontSize: 10, color: AppTheme.successText, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text('Code: $bCode • City: ${b['city'] ?? 'Main'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                tooltip: 'Remove Branch',
                                onPressed: () async {
                                  if (bId > 0 && staffId > 0) {
                                    await PeopleService.removeStaffBranch(
                                      staffId: staffId,
                                      branchId: bId,
                                    );
                                    _loadData();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
