import 'package:flutter/material.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/validators.dart';
import '../../../services/directory_service.dart';
import '../../../../teacher/screens/teacher_dashboard.dart';
import '../add_staff_screen.dart';
import 'directory_list_tile.dart';
import 'staff_branch_assignment_modal.dart';
import 'student_photo_upload_section.dart';

class StaffListView extends StatefulWidget {
  const StaffListView({super.key});

  @override
  State<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<StaffListView> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _filteredStaff = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStaff();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = _staff.where((member) {
        final name = '${member['first_name']} ${member['last_name']}'.toLowerCase();
        final role = (member['role_name'] ?? member['role_code'] ?? member['role'] ?? '').toString().toLowerCase();
        final username = (member['username'] ?? '').toString().toLowerCase();
        final email = (member['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || role.contains(query) || username.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchStaff() async {
    try {
      final staffList = await DirectoryService.getStaff();
      if (mounted) {
        setState(() {
          _staff = staffList;
          _filteredStaff = staffList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openEditStaffModal(Map<String, dynamic> member) {
    final firstNameController = TextEditingController(text: member['first_name'] ?? '');
    final lastNameController = TextEditingController(text: member['last_name'] ?? '');
    final emailController = TextEditingController(text: member['email'] ?? '');
    final phoneController = TextEditingController(text: member['phone'] ?? '');
    String currentAvatarUrl = member['avatar_url']?.toString() ?? '';
    final staffId = int.tryParse((member['staff_id'] ?? member['id'] ?? 0).toString()) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Faculty / Staff Member',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StudentPhotoUploadSection(
                      initialAvatarUrl: currentAvatarUrl,
                      title: 'Teacher / Staff Photo',
                      subtitle: 'Update portrait photo or select an avatar',
                      onAvatarChanged: (url) {
                        setModalState(() {
                          currentAvatarUrl = url;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameController,
                            decoration: const InputDecoration(labelText: 'First Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: AppTheme.surfaceWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (firstNameController.text.trim().isEmpty) return;
                        final phoneErr = validateIndianPhone(phoneController.text);
                        if (phoneErr != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
                          return;
                        }
                        final updateData = <String, dynamic>{
                          'first_name': firstNameController.text.trim(),
                          'last_name': lastNameController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'avatar_url': currentAvatarUrl,
                        };

                        Navigator.pop(ctx);
                        if (staffId > 0) {
                          await DirectoryService.updateStaff(staffId, updateData);
                        }
                        if (mounted) {
                          _fetchStaff();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Staff details updated successfully.'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _confirmDeleteStaff(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Staff?'),
          ],
        ),
        content: Text('Are you sure you want to remove staff member "${member['first_name']} ${member['last_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = int.tryParse((member['user_id'] ?? member['id'] ?? 1).toString()) ?? 1;
              await DirectoryService.deleteStaff(userId);
              if (mounted) {
                _fetchStaff();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Staff member removed.'), backgroundColor: AppTheme.successText),
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
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              hintText: 'Search staff by name or role...',
              filled: true,
              fillColor: AppTheme.surfaceWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.electricCobalt, width: 1),
              ),
            ),
          ),
        ),
        
        // List
        Expanded(
          child: _filteredStaff.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
                  itemCount: _filteredStaff.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _filteredStaff[index];
                    final roleDisplay = (member['role_name'] ?? member['role_code'] ?? member['role'] ?? '')
                        .toString()
                        .replaceAll('_', ' ')
                        .toUpperCase();
                    final username = member['username'] != null ? '@${member['username']}' : null;

                    return DirectoryListTile(
                      firstName: member['first_name'] ?? '',
                      lastName: member['last_name'] ?? '',
                      status: member['status'] ?? '',
                      email: member['email'] ?? '',
                      phone: member['phone'] ?? '',
                      subtitle1: roleDisplay,
                      subtitle2: username,
                      avatarUrl: member['avatar_url'],
                      onTap: () => StaffBranchAssignmentModal.show(context, member),
                      onEdit: () => _openEditStaffModal(member),
                      onDelete: () => _confirmDeleteStaff(member),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No Staff Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
              ),
              const SizedBox(height: 8),
              Text(
                'No staff members match "$searchQuery". Try searching with a different name, role, or email.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (ApiService.isSoloTutor) {
      return _buildSoloTutorModeCard();
    }

    return _buildCoachingCenterEmptyStaffCard();
  }

  Widget _buildCoachingCenterEmptyStaffCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: AppTheme.level1Shadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 48,
                  color: AppTheme.electricCobalt,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Staff Members Added Yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add teachers, faculty, and administrative staff to manage your coaching center, assign batches, and coordinate classes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddStaffScreen()),
                  );
                  if (result == true || result == null) {
                    _fetchStaff();
                  }
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoloTutorModeCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: AppTheme.level1Shadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  size: 48,
                  color: AppTheme.electricCobalt,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Solo Tutor Academy Mode Active',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are currently operating as the Primary Instructor & Administrator. Extra staff is not required to create batches, schedule classrooms, or conduct exams.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.successText),
                        SizedBox(width: 6),
                        Text(
                          'Direct Batch Teaching',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successText),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.academicBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.academicText),
                        SizedBox(width: 6),
                        Text(
                          'Zero Payroll Clutter',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.academicText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddStaffScreen()),
                      );
                      if (result == true || result == null) {
                        _fetchStaff();
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricCobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherDashboard()),
                      );
                    },
                    icon: const Icon(Icons.cast_for_education_rounded, size: 18),
                    label: const Text('Open Teaching Desk', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.electricCobalt,
                      side: const BorderSide(color: AppTheme.electricCobalt),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
