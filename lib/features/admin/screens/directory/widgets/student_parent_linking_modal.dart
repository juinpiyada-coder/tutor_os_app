import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../services/people_service.dart';

class StudentParentLinkingModal extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentParentLinkingModal({super.key, required this.student});

  static Future<void> show(BuildContext context, Map<String, dynamic> student) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudentParentLinkingModal(student: student),
    );
  }

  @override
  State<StudentParentLinkingModal> createState() => _StudentParentLinkingModalState();
}

class _StudentParentLinkingModalState extends State<StudentParentLinkingModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _linkedParents = [];
  List<Map<String, dynamic>> _allParents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final studentId = int.tryParse(widget.student['student_id']?.toString() ?? '0') ?? 0;
    final linked = await PeopleService.getParentsByStudent(studentId);
    final all = await PeopleService.getParents();
    if (mounted) {
      setState(() {
        _linkedParents = linked;
        _allParents = all;
        _isLoading = false;
      });
    }
  }

  void _openAddLinkSheet() {
    final studentId = int.tryParse(widget.student['student_id']?.toString() ?? '0') ?? 0;
    final linkedIds = _linkedParents.map((p) => int.tryParse(p['parent_id']?.toString() ?? '0')).toSet();
    final available = _allParents.where((p) {
      final pId = int.tryParse(p['parent_id']?.toString() ?? '0');
      return !linkedIds.contains(pId);
    }).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other unlinked parents available.')),
      );
      return;
    }

    int? selectedParentId = int.tryParse(available.first['parent_id']?.toString() ?? '0');
    String relCode = 'FATHER';
    bool isPrimary = _linkedParents.isEmpty;
    bool receiveNotifs = true;

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
                    'Link Parent / Guardian',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textHeading,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedParentId,
                    decoration: InputDecoration(
                      labelText: 'Select Parent',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: available.map((p) {
                      final pId = int.tryParse(p['parent_id']?.toString() ?? '0') ?? 0;
                      return DropdownMenuItem<int>(
                        value: pId,
                        child: Text('${p['first_name']} ${p['last_name']} (${p['phone'] ?? ''})'),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedParentId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: relCode,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'FATHER', child: Text('Father')),
                      DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
                      DropdownMenuItem(value: 'GUARDIAN', child: Text('Guardian')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (val) => setModalState(() => relCode = val ?? 'FATHER'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary Contact'),
                    value: isPrimary,
                    onChanged: (val) => setModalState(() => isPrimary = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Receives SMS & Email Alerts'),
                    value: receiveNotifs,
                    onChanged: (val) => setModalState(() => receiveNotifs = val),
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
                        if (selectedParentId == null) return;
                        Navigator.pop(modalCtx);
                        final success = await PeopleService.linkStudentParent(
                          studentId: studentId,
                          parentId: selectedParentId!,
                          relationshipCode: relCode,
                          isPrimary: isPrimary,
                          receivesNotifications: receiveNotifs,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Linked successfully!' : 'Failed to link')),
                          );
                          _loadData();
                        }
                      },
                      child: const Text('Link Parent'),
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
    final studentName = '${widget.student['first_name'] ?? 'Student'} ${widget.student['last_name'] ?? ''}'.trim();
    final studentLoc = widget.student['current_address'] ?? widget.student['address'] ?? widget.student['location'];
    final studentAvatar = widget.student['avatar_url'];
    final studentId = int.tryParse(widget.student['student_id']?.toString() ?? '0') ?? 0;

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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.surfaceSubtle,
                      backgroundImage: (studentAvatar != null && studentAvatar.isNotEmpty)
                          ? NetworkImage(studentAvatar)
                          : null,
                      child: (studentAvatar == null || studentAvatar.isEmpty)
                          ? Text(
                              studentName.isNotEmpty ? studentName[0] : 'S',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family & Guardians',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textHeading,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                studentName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                                ),
                              ),
                              if (studentLoc != null && studentLoc.toString().trim().isNotEmpty) ...[
                                const SizedBox(width: 6),
                                const Text('•', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                const SizedBox(width: 6),
                                const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.electricCobalt),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    studentLoc.toString(),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.electricCobalt, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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
                'Linked Parents (${_linkedParents.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppTheme.textHeading,
                ),
              ),
              TextButton.icon(
                onPressed: _openAddLinkSheet,
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Link Parent'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _linkedParents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.family_restroom_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No parents linked to this student.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _openAddLinkSheet,
                              child: const Text('Link Guardian'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _linkedParents.length,
                        itemBuilder: (context, index) {
                          final p = _linkedParents[index];
                          final pId = int.tryParse(p['parent_id']?.toString() ?? '0') ?? 0;
                          final pName = '${p['first_name'] ?? 'Parent'} ${p['last_name'] ?? ''}'.trim();
                          final rel = p['relationship_code'] ?? 'GUARDIAN';
                          final isPrimary = p['is_primary'] == 1 || p['is_primary'] == true;

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
                                child: Text(rel.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                              ),
                              title: Row(
                                children: [
                                  Text(pName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              subtitle: Text('$rel • Phone: ${p['phone'] ?? 'N/A'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.link_off, color: Colors.red, size: 20),
                                tooltip: 'Unlink',
                                onPressed: () async {
                                  if (pId > 0 && studentId > 0) {
                                    await PeopleService.unlinkStudentParent(
                                      studentId: studentId,
                                      parentId: pId,
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
