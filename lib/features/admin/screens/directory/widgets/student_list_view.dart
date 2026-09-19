import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/validators.dart';
import '../../../services/directory_service.dart';
import 'directory_list_tile.dart';
import 'student_parent_linking_modal.dart';
import 'student_photo_upload_section.dart';

class StudentListView extends StatefulWidget {
  const StudentListView({super.key});

  @override
  State<StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<StudentListView> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
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
      _filteredStudents = _students.where((student) {
        final name = '${student['first_name']} ${student['last_name']}'.toLowerCase();
        final batch = (student['batch'] ?? '').toLowerCase();
        return name.contains(query) || batch.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchStudents() async {
    try {
      final students = await DirectoryService.getStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _filteredStudents = students;
          _errorMessage = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _students = [];
          _filteredStudents = [];
          _errorMessage = '';
          _isLoading = false;
        });
      }
    }
  }

  void _openEditStudentModal(Map<String, dynamic> student) {
    final firstNameController = TextEditingController(text: student['first_name'] ?? '');
    final lastNameController = TextEditingController(text: student['last_name'] ?? '');
    final emailController = TextEditingController(text: student['email'] ?? '');
    final phoneController = TextEditingController(text: student['phone'] ?? '');
    final addressController = TextEditingController(text: student['current_address'] ?? student['address'] ?? student['location'] ?? '');
    String currentAvatarUrl = student['avatar_url'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        Text('Edit Student Details',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryNavy)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StudentPhotoUploadSection(
                      initialAvatarUrl: currentAvatarUrl,
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
                            decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Current Location / City / Address',
                        hintText: 'e.g. Sector 18, Noida / New Delhi',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.electricCobalt),
                      ),
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
                        if (firstNameController.text.trim().isEmpty) return;
                        final phoneErr = validateIndianPhone(phoneController.text);
                        if (phoneErr != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final studentId = int.tryParse((student['student_id'] ?? 1).toString()) ?? 1;
                        await DirectoryService.updateStudent(studentId, {
                          'first_name': firstNameController.text.trim(),
                          'last_name': lastNameController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'current_address': addressController.text.trim(),
                          'avatar_url': currentAvatarUrl,
                        });
                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _fetchStudents();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Student profile & location updated!'), backgroundColor: AppTheme.successText),
                        );
                      },
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _toggleStudentStatus(Map<String, dynamic> student) async {
    final studentId = int.tryParse((student['student_id'] ?? 1).toString()) ?? 1;
    final currentStatus = (student['status'] ?? 'ACTIVE').toString();
    final newStatus = currentStatus.toUpperCase() == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final isDeactivating = newStatus == 'INACTIVE';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isDeactivating ? Icons.block_outlined : Icons.check_circle_outline_rounded,
              color: isDeactivating ? AppTheme.urgentText : AppTheme.successText,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('${isDeactivating ? "Deactivate" : "Activate"} Student?'),
          ],
        ),
        content: Text(
          'Are you sure you want to ${isDeactivating ? "deactivate" : "activate"} "${student['first_name']} ${student['last_name']}"?\n\n'
          '${isDeactivating ? "Deactivated students cannot access their portal or attend classes." : "Activating this student will restore access to classes and portals."}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? AppTheme.urgentText : AppTheme.successText,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isDeactivating ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await DirectoryService.toggleStudentStatus(studentId, currentStatus);
      if (mounted) {
        _fetchStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Student status changed to $newStatus.'
                  : 'Failed to update student status.',
            ),
            backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
          ),
        );
      }
    }
  }

  void _confirmDeleteStudent(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Delete Student?'),
          ],
        ),
        content: Text('Are you sure you want to delete "${student['first_name']} ${student['last_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final studentId = int.tryParse((student['student_id'] ?? 1).toString()) ?? 1;
              await DirectoryService.deleteStudent(studentId);
              if (mounted) {
                _fetchStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student deleted.'), backgroundColor: AppTheme.successText),
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
              hintText: 'Search students by name or batch...',
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
          child: _filteredStudents.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_outlined, size: 48, color: AppTheme.electricCobalt),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.trim().isNotEmpty ? 'No Matching Students Found' : 'No Students Enrolled Yet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.trim().isNotEmpty
                              ? 'No students match "${_searchController.text.trim()}". Try searching with a different name or batch.'
                              : 'Enroll students to manage batch assignments, attendance records, parent links, and course progress.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13.5, color: AppTheme.textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
                  itemCount: _filteredStudents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    final studentLoc = student['current_address'] ?? student['address'] ?? student['location'];
                    final parentName = (student['parent_name'] ?? '').toString().trim();
                    final parentPhone = (student['parent_phone'] ?? '').toString().trim();
                    final subtitle2 = parentName.isNotEmpty
                        ? 'Parent: $parentName${parentPhone.isNotEmpty ? " ($parentPhone)" : ""}'
                        : (parentPhone.isNotEmpty ? 'Parent Phone: $parentPhone' : null);
                    return DirectoryListTile(
                      firstName: student['first_name'] ?? '',
                      lastName: student['last_name'] ?? '',
                      status: student['status'] ?? '',
                      email: student['email'] ?? '',
                      phone: student['phone'] ?? '',
                      subtitle1: student['batch'] ?? '',
                      subtitle2: subtitle2,
                      location: studentLoc,
                      avatarUrl: student['avatar_url'],
                      onTap: () async {
                        await StudentParentLinkingModal.show(context, student);
                        if (mounted) {
                          _fetchStudents();
                        }
                      },
                      onEdit: () => _openEditStudentModal(student),
                      onDelete: () => _confirmDeleteStudent(student),
                      onToggleStatus: () => _toggleStudentStatus(student),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
