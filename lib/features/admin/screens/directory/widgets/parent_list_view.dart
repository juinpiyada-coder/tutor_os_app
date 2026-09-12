import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../services/people_service.dart';

class ParentListView extends StatefulWidget {
  const ParentListView({super.key});

  @override
  State<ParentListView> createState() => ParentListViewState();
}

class ParentListViewState extends State<ParentListView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _parents = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadParents();
  }

  Future<void> loadParents() async {
    setState(() => _isLoading = true);
    final list = await PeopleService.getParents();
    if (mounted) {
      setState(() {
        _parents = list;
        _isLoading = false;
      });
    }
  }

  void openAddEditParentModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final fNameCtrl = TextEditingController(text: item?['first_name'] ?? '');
    final lNameCtrl = TextEditingController(text: item?['last_name'] ?? '');
    final phoneCtrl = TextEditingController(text: item?['phone'] ?? '');
    final altPhoneCtrl = TextEditingController(text: item?['alternate_phone'] ?? '');
    final emailCtrl = TextEditingController(text: item?['email'] ?? '');
    final occCtrl = TextEditingController(text: item?['occupation'] ?? '');
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
                          isEdit ? 'Edit Parent / Guardian' : 'Add Parent / Guardian',
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Last Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Primary Phone Number *',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: altPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Alternate Phone',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: occCtrl,
                      decoration: InputDecoration(
                        labelText: 'Occupation / Profession',
                        prefixIcon: const Icon(Icons.work_outline),
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
                        DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
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
                          if (fNameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter First Name and Phone')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'first_name': fNameCtrl.text.trim(),
                            'last_name': lNameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'alternate_phone': altPhoneCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'occupation': occCtrl.text.trim(),
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await PeopleService.updateParent(
                              int.parse(item['parent_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await PeopleService.addParent(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Parent saved successfully!' : 'Action failed')),
                            );
                            loadParents();
                          }
                        },
                        child: Text(isEdit ? 'Update Parent' : 'Register Parent'),
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

    final filtered = _parents.where((p) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.toLowerCase();
      final phone = (p['phone'] ?? '').toString().toLowerCase();
      final code = (p['parent_code'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || phone.contains(q) || code.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search parents by name, phone, code...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: isDark ? AppTheme.darkSurfaceCard : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: loadParents,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildParentCard(filtered[index], isDark);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Parents Found',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
            ),
            onPressed: () => openAddEditParentModal(),
            icon: const Icon(Icons.add),
            label: const Text('Add Parent'),
          ),
        ],
      ),
    );
  }

  Widget _buildParentCard(Map<String, dynamic> item, bool isDark) {
    final parentId = int.tryParse(item['parent_id']?.toString() ?? '0') ?? 0;
    final fullName = '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
    final parentCode = item['parent_code'] ?? '';
    final phone = item['phone'] ?? '';
    final occupation = item['occupation'] ?? '';
    final email = item['email'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppTheme.electricCobalt),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textHeading,
                          ),
                        ),
                        Text(
                          '$parentCode • $occupation',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      openAddEditParentModal(item);
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Parent?'),
                          content: Text('Are you sure you want to delete $fullName?'),
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
                      if (confirm == true && parentId > 0) {
                        await PeopleService.deleteParent(parentId);
                        loadParents();
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(phone, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                if (email.isNotEmpty) ...[
                  const SizedBox(width: 14),
                  Icon(Icons.email_outlined, size: 14, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
