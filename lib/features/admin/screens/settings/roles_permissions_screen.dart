import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/platform_service.dart';

class RolesPermissionsScreen extends StatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  State<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends State<RolesPermissionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _allPermissions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final roles = await PlatformService.getRoles();
    final permissions = await PlatformService.getPermissions();
    if (mounted) {
      setState(() {
        _roles = roles;
        _allPermissions = permissions;
        _isLoading = false;
      });
    }
  }

  void _openAddEditRoleModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['role_name'] ?? '');
    final codeCtrl = TextEditingController(text: item?['role_code'] ?? '');
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
                          isEdit ? 'Edit Role' : 'Create Custom Role',
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
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Role Name (e.g. Vice Principal or Accountant)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isEdit) ...[
                      TextField(
                        controller: codeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Role Code (e.g. ROLE_ACCOUNTANT)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter role name')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'role_name': nameCtrl.text.trim(),
                            'role_code': codeCtrl.text.trim(),
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await PlatformService.updateRole(
                              int.parse(item['role_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await PlatformService.addRole(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Role saved!' : 'Action failed')),
                            );
                            _loadData();
                          }
                        },
                        child: Text(isEdit ? 'Update Role' : 'Create Role'),
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

  void _openPermissionsMatrix(Map<String, dynamic> role) async {
    final roleId = int.tryParse(role['role_id']?.toString() ?? '0') ?? 0;
    final roleName = role['role_name'] ?? '';
    final isSystemRole = role['is_system_role'] == 1 || role['is_system_role'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: PlatformService.getRolePermissions(roleId),
              builder: (context, snapshot) {
                final grantedList = snapshot.data ?? [];
                final grantedIds = grantedList.map((g) => int.tryParse(g['permission_id']?.toString() ?? '0')).toSet();

                // Group permissions by module
                final Map<String, List<Map<String, dynamic>>> modules = {};
                for (var p in _allPermissions) {
                  final m = (p['module_code'] ?? '').toString().toUpperCase();
                  modules.putIfAbsent(m, () => []).add(p);
                }

                return Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                                  'RBAC Permissions Matrix',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppTheme.textHeading,
                                  ),
                                ),
                                Text(
                                  '$roleName (${grantedIds.length} granted)',
                                  style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      if (isSystemRole)
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkWarningBg : AppTheme.warningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: AppTheme.warningText),
                              SizedBox(width: 8),
                              Text('System Role: Core permissions are enforced.', style: TextStyle(fontSize: 11, color: AppTheme.warningText, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      const Divider(),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : modules.isEmpty
                                ? const Center(child: Text('No permissions catalog found.'))
                                : ListView.builder(
                                    itemCount: modules.keys.length,
                                    itemBuilder: (context, idx) {
                                      final moduleName = modules.keys.elementAt(idx);
                                      final perms = modules[moduleName]!;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              moduleName,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.electricCobalt,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...perms.map((p) {
                                              final pId = int.tryParse(p['permission_id']?.toString() ?? '0') ?? 0;
                                              final isGranted = grantedIds.contains(pId);

                                              return CheckboxListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(
                                                  p['permission_name'] ?? p['permission_code'] ?? '',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                                subtitle: Text(
                                                  p['action_code'] ?? '',
                                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                                                ),
                                                value: isGranted,
                                                activeColor: AppTheme.electricCobalt,
                                                onChanged: (val) async {
                                                  if (val == true) {
                                                    await PlatformService.grantPermission(roleId, pId);
                                                  } else {
                                                    await PlatformService.revokePermission(roleId, pId);
                                                  }
                                                  setSheetState(() {});
                                                  _loadData();
                                                },
                                              );
                                            }),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
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
          'Roles & Access Control',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        onPressed: () => _openAddEditRoleModal(),
        icon: const Icon(Icons.add_moderator),
        label: const Text('Add Role'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  return _buildRoleCard(_roles[index], isDark);
                },
              ),
            ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> item, bool isDark) {
    final roleId = int.tryParse(item['role_id']?.toString() ?? '0') ?? 0;
    final isSystem = item['is_system_role'] == 1 || item['is_system_role'] == true;
    final permCount = item['permission_count'] ?? 0;
    final userCount = item['user_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _openPermissionsMatrix(item),
        leading: CircleAvatar(
          backgroundColor: isSystem ? AppTheme.electricCobalt.withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1),
          child: Icon(
            isSystem ? Icons.security : Icons.person_outline,
            color: isSystem ? AppTheme.electricCobalt : Colors.purple,
          ),
        ),
        title: Row(
          children: [
            Text(
              item['role_name'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSystem ? (isDark ? AppTheme.darkAcademicBg : AppTheme.academicBg) : Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isSystem ? 'SYSTEM' : 'CUSTOM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSystem ? AppTheme.academicText : Colors.purple,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Text(
                'Code: ${item['role_code'] ?? ''}',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
              ),
              const SizedBox(width: 12),
              Text(
                '• $permCount Perms',
                style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                '• $userCount Users',
                style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.key, color: AppTheme.electricCobalt, size: 20),
              tooltip: 'Configure Permissions',
              onPressed: () => _openPermissionsMatrix(item),
            ),
            if (!isSystem)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) async {
                  if (val == 'edit') {
                    _openAddEditRoleModal(item);
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Role?'),
                        content: Text('Delete ${item['role_name']}?'),
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
                    if (confirm == true && roleId > 0) {
                      await PlatformService.deleteRole(roleId);
                      _loadData();
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
      ),
    );
  }
}
