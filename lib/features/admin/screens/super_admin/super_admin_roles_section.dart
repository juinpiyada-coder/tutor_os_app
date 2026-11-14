import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/platform_service.dart';

class SuperAdminRolesSection extends StatefulWidget {
  final bool isDark;
  const SuperAdminRolesSection({super.key, required this.isDark});

  @override
  State<SuperAdminRolesSection> createState() => SuperAdminRolesSectionState();
}

class SuperAdminRolesSectionState extends State<SuperAdminRolesSection> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    setState(() => _isLoading = true);
    final list = await PlatformService.getRoles();
    if (mounted) {
      setState(() {
        _roles = list;
        _isLoading = false;
      });
    }
  }

  void openAddEditRoleModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final roleId = isEdit ? int.tryParse(item['role_id']?.toString() ?? '0') ?? 0 : 0;
    final nameCtrl = TextEditingController(text: item?['role_name'] ?? '');
    final codeCtrl = TextEditingController(text: item?['role_code'] ?? '');
    String status = item?['status'] ?? 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = widget.isDark;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: dark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          isEdit ? 'Edit System Role' : 'Create Platform / Academy Role',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : AppTheme.textHeading,
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
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Role Display Name *',
                        hintText: 'e.g. Academic Counselor',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      enabled: !isEdit,
                      decoration: InputDecoration(
                        labelText: 'Role Code *',
                        hintText: 'e.g. COUNSELOR',
                        prefixIcon: const Icon(Icons.code_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
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
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Role name is required')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'role_name': nameCtrl.text.trim(),
                            'role_code': codeCtrl.text.trim().isNotEmpty
                                ? codeCtrl.text.trim().toUpperCase()
                                : nameCtrl.text.trim().replaceAll(' ', '_').toUpperCase(),
                            'status': status,
                          };

                          final ok = isEdit
                              ? await PlatformService.updateRole(roleId, payload)
                              : await PlatformService.addRole(payload);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Role saved successfully' : 'Failed to save role'),
                                backgroundColor: ok ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                            loadRoles();
                          }
                        },
                        child: Text(isEdit ? 'Update Role' : 'Create Role', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void confirmDeleteRole(Map<String, dynamic> role) {
    final roleId = int.tryParse(role['role_id']?.toString() ?? '0') ?? 0;
    final isSystem = role['is_system_role'] == 1 || role['is_system_role'] == true;
    if (isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete core platform system roles')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role?'),
        content: Text('Are you sure you want to remove role "${role['role_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await PlatformService.deleteRole(roleId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Role deleted' : 'Failed to delete role'),
                    backgroundColor: ok ? AppTheme.successText : AppTheme.urgentText,
                  ),
                );
                loadRoles();
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
    final dark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform RBAC & Roles',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : AppTheme.textHeading,
                  ),
                ),
                Text(
                  'Manage user access roles and role scopes across all institutes',
                  style: TextStyle(fontSize: 13, color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => openAddEditRoleModal(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Role', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_roles.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(Icons.security_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('No Roles Found', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => openAddEditRoleModal(),
                    child: const Text('Add Role'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _roles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = _roles[index];
              final isSystem = r['is_system_role'] == 1 || r['is_system_role'] == true;
              final isActive = (r['status'] ?? 'ACTIVE') == 'ACTIVE';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: dark ? AppTheme.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppTheme.electricCobalt, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                r['role_name'] ?? 'Role',
                                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              if (isSystem) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('SYSTEM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r['role_code'] ?? '',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.successBg : AppTheme.urgentBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r['status'] ?? 'ACTIVE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? AppTheme.successText : AppTheme.urgentText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => openAddEditRoleModal(r),
                    ),
                    if (!isSystem)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.urgentText),
                        onPressed: () => confirmDeleteRole(r),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
