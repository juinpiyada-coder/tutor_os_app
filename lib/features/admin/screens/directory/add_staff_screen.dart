import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../services/directory_service.dart';
import '../../services/settings_service.dart';
import 'widgets/student_photo_upload_section.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'TEACHER';
  int? _selectedBranchId;
  String _avatarUrl = '';

  bool _isLoading = false;
  bool _isLoadingBranches = true;
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await SettingsService.getBranches();
      setState(() {
        _branches = branches;
        _isLoadingBranches = false;
        if (branches.isNotEmpty) {
          _selectedBranchId = int.tryParse(branches.first['branch_id']?.toString() ?? '0');
        }
      });
    } catch (e) {
      setState(() => _isLoadingBranches = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        'role_code': _selectedRole,
      };
      if (_selectedBranchId != null) data['branch_id'] = _selectedBranchId;
      if (_avatarUrl.isNotEmpty) data['avatar_url'] = _avatarUrl;

      await DirectoryService.addStaff(data);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member added successfully!', style: TextStyle(color: AppTheme.surfaceWhite)),
            backgroundColor: AppTheme.successText,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(color: AppTheme.surfaceWhite)),
            backgroundColor: AppTheme.urgentText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Staff / Faculty'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudentPhotoUploadSection(
                initialAvatarUrl: _avatarUrl,
                title: 'Teacher / Staff Photo',
                subtitle: 'Upload a portrait photo or select an avatar for this educator',
                onAvatarChanged: (url) {
                  setState(() {
                    _avatarUrl = url;
                  });
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        hintText: 'Enter first name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'First name is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        hintText: 'Enter last name',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  hintText: 'Enter unique login username',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (value) => Validators.validateUsername(value, minLength: 3),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => Validators.validateEmail(value, required: true),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '10-digit mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '+91 ',
                  counterText: '',
                ),
                validator: (v) => Validators.validateIndianPhone(v, required: false),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password *',
                  hintText: 'Set a password',
                  helperText: 'Min 6 chars with letters, numbers & symbols (e.g. Pass@123)',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => Validators.validatePassword(value, minLength: 6),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Staff Role *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'TEACHER', child: Text('Teacher / Faculty')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin / Coordinator')),
                  DropdownMenuItem(value: 'ACCOUNTANT', child: Text('Accountant')),
                  DropdownMenuItem(value: 'COUNSELOR', child: Text('Counselor')),
                  DropdownMenuItem(value: 'SUPPORT', child: Text('Support Staff')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (_isLoadingBranches)
                const LinearProgressIndicator()
              else if (_branches.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Primary Campus Branch',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: _branches.map((b) {
                    final id = int.tryParse(b['branch_id']?.toString() ?? '0') ?? 0;
                    final name = b['branch_name'] ?? '';
                    final code = b['branch_code'] ?? '';
                    return DropdownMenuItem<int>(value: id, child: Text('$name ($code)'));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedBranchId = value),
                ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: AppTheme.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2))
                    : const Text('Save Staff Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

