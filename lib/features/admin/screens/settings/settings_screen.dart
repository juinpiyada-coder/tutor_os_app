import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../../auth/screens/login_screen.dart';
import '../../services/settings_service.dart';
import 'roles_permissions_screen.dart';
import 'subscription_billing_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SettingsService.getInstituteProfile();
      final branches = await SettingsService.getBranches();
      if (mounted) {
        setState(() {
          _profile = profile;
          _branches = branches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditProfileModal() {
    final nameController = TextEditingController(text: _profile['institute_name']);
    final taglineController = TextEditingController(text: _profile['tagline']);
    final phoneController = TextEditingController(text: _profile['phone']);
    final emailController = TextEditingController(text: _profile['email']);
    final addressController = TextEditingController(text: _profile['address']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Institute Details',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Institute Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: taglineController,
                  decoration: const InputDecoration(labelText: 'Tagline / Motto'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Official Contact Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Official Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Campus Address'),
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
                    await SettingsService.updateInstituteProfile({
                      'institute_name': nameController.text.trim(),
                      'tagline': taglineController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'address': addressController.text.trim(),
                    });
                    if (!mounted) return;
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    setState(() {
                      _profile['institute_name'] = nameController.text.trim();
                      _profile['tagline'] = taglineController.text.trim();
                      _profile['phone'] = phoneController.text.trim();
                      _profile['email'] = emailController.text.trim();
                      _profile['address'] = addressController.text.trim();
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Institute profile updated successfully!'), backgroundColor: AppTheme.successText),
                      );
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openBranchFormModal({Map<String, dynamic>? existingBranch}) {
    final isEditing = existingBranch != null;
    final codeController = TextEditingController(text: existingBranch?['branch_code'] ?? '');
    final nameController = TextEditingController(text: existingBranch?['branch_name'] ?? '');
    final locationController = TextEditingController(text: existingBranch?['location'] ?? existingBranch?['address'] ?? '');
    final phoneController = TextEditingController(text: existingBranch?['contact_phone'] ?? existingBranch?['phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Branch Campus' : 'Add New Branch Campus',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Branch Code (e.g. BR-EAST)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Branch Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location / City Area'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Branch Contact Phone'),
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
                    if (nameController.text.trim().isEmpty) return;
                    final branchPayload = {
                      'branch_code': codeController.text.trim(),
                      'branch_name': nameController.text.trim(),
                      'location': locationController.text.trim(),
                      'contact_phone': phoneController.text.trim(),
                    };

                    if (isEditing) {
                      final bId = int.tryParse((existingBranch['branch_id'] ?? 1).toString()) ?? 1;
                      await SettingsService.updateBranch(bId, branchPayload);
                    } else {
                      await SettingsService.addBranch(branchPayload);
                    }

                    if (!mounted) return;
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    _loadSettings();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Branch updated successfully!' : 'Branch added successfully!'),
                          backgroundColor: AppTheme.successText,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Add Branch', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteBranch(Map<String, dynamic> b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Branch?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${b['branch_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final bId = int.tryParse((b['branch_id'] ?? 1).toString()) ?? 1;
              await SettingsService.deleteBranch(bId);
              if (mounted) {
                _loadSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Branch removed.'), backgroundColor: AppTheme.successText),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        body: Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Settings & Configuration',
            style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        actions: const [
          ThemeToggleSwitch(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Institute Profile Card
            _buildProfileCard(),
            const SizedBox(height: 20),

            // 2. Subscription Tier / Plan Info
            _buildPlanCard(),
            const SizedBox(height: 20),

            // 3. Branches / Multi-Center Management
            _buildBranchesSection(),
            const SizedBox(height: 20),

            // 4. System & Account Actions
            _buildSystemSettings(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.level1Shadow,
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile['institute_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading),
                      ),
                      Text(
                        _profile['tagline'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.electricCobalt),
                onPressed: _openEditProfileModal,
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.email_outlined, 'Email', _profile['email'] ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone_outlined, 'Phone', _profile['phone'] ?? '+91 98765 43210'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, 'Address', _profile['address'] ?? ''),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.language_outlined, 'Website', _profile['website'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildPlanCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionBillingScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryNavy, AppTheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.level2Shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCobalt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('ENTERPRISE TIER',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Row(
                  children: [
                    Text('Manage Billing', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'TutorOS Pro Multi-Branch',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Academic Session ${_profile['academic_year'] ?? '2026-2027'} • Active Subscription',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPlanBadge('Capacity: 500 Students'),
                _buildPlanBadge('SMS & WhatsApp Active'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBranchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Branch Campuses', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16)),
            TextButton.icon(
              onPressed: () => _openBranchFormModal(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Branch'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._branches.map((b) {
          final isPrimary = b['is_primary'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPrimary ? AppTheme.academicBg : AppTheme.surfaceSubtle,
                  child: Icon(Icons.apartment_rounded,
                      color: isPrimary ? AppTheme.academicText : AppTheme.primaryNavy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(b['branch_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Main HQ',
                                  style: TextStyle(color: AppTheme.successText, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(b['location'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Text(b['contact_phone'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.electricCobalt),
                  onPressed: () => _openBranchFormModal(existingBranch: b),
                  tooltip: 'Edit Branch',
                ),
                if (!isPrimary)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.urgentText),
                    onPressed: () => _confirmDeleteBranch(b),
                    tooltip: 'Delete Branch',
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSystemSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.level1Shadow,
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Security & Access Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          if (ApiService.isSuperAdmin) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.electricCobalt, size: 20),
              ),
              title: const Text('Roles & Access Permissions (RBAC)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Manage custom roles, system roles & module permissions', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RolesPermissionsScreen()),
                );
              },
            ),
            const Divider(height: 1),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card_rounded, color: AppTheme.successText, size: 20),
            ),
            title: const Text('SaaS Subscription & Billing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Quota meters, plan tier upgrade & invoice receipts', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionBillingScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_reset_outlined, color: AppTheme.electricCobalt),
            title: const Text('Change Admin Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset instructions dispatched to registered email.')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: AppTheme.urgentText),
            title: const Text('Sign Out of TutorOS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.urgentText)),
            onTap: () {
              ApiService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppTheme.textHeading, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
