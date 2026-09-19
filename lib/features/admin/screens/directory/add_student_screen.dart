import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../services/directory_service.dart';
import '../../services/academics_service.dart';
import 'widgets/student_photo_upload_section.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Student controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _studentCodeController = TextEditingController();
  final _admissionNoController = TextEditingController();
  final _loginUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _avatarUrl = '';

  // Parent / Guardian controllers
  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  String _parentRelationship = 'FATHER';
  
  bool _isLoading = false;
  bool _isLoadingBatches = true;
  List<Map<String, dynamic>> _batches = [];
  int? _selectedBatchId;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final randomSuffix = (100 + (DateTime.now().millisecondsSinceEpoch % 900));
    _studentCodeController.text = 'STU-$randomSuffix';
    _loginUsernameController.text = 'STU-$randomSuffix';
    _passwordController.text = 'Tutor@$randomSuffix';
    
    _studentCodeController.addListener(() {
      if (_loginUsernameController.text.startsWith('STU-') || _loginUsernameController.text.isEmpty) {
        _loginUsernameController.text = _studentCodeController.text;
      }
    });

    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await AcademicsService.getBatches();
      if (mounted) {
        setState(() {
          _batches = batches;
          if (_batches.isNotEmpty) {
            _selectedBatchId = int.tryParse((_batches.first['batch_id'] ?? 0).toString());
          }
          _isLoadingBatches = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBatches = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentAddressController.dispose();
    _studentCodeController.dispose();
    _admissionNoController.dispose();
    _loginUsernameController.dispose();
    _passwordController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp({
    required String phone,
    required String studentName,
    required String username,
    required String email,
    required String password,
    required String batchName,
    String? parentEmail,
    String? parentName,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    String msgText = '🎓 *Welcome to TutorOS Portal!*\n\n'
        'Hello $studentName,\n'
        'Your student account has been enrolled successfully.\n\n'
        '📌 *Batch:* $batchName\n'
        '🔑 *Student Portal Login:*\n'
        '• *Username:* $username\n'
        '• *Email:* $email\n'
        '• *Password:* $password\n\n';

    if (parentEmail != null && parentEmail.isNotEmpty) {
      msgText += '👨‍👩‍👧 *Parent Portal Login:*\n'
          '• *Parent Email:* $parentEmail\n'
          '• *Parent Password:* 123456\n\n';
    }

    msgText += 'Best regards,\nAcademic Administration';

    final msg = Uri.encodeComponent(msgText);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e'), backgroundColor: AppTheme.urgentText),
        );
      }
    }
  }

  void _showCredentialsPopup({
    required String studentName,
    required String phone,
    required String username,
    required String email,
    required String password,
    required String batchName,
    String? parentName,
    String? parentEmail,
    String? parentPhone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.successText, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Student & Parent Enrolled!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textHeading),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$studentName has been enrolled in $batchName with active student & parent credentials.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 16),

                // Student Credentials Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.canvasBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STUDENT PORTAL LOGIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Username:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          SelectableText(username, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Login Email:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          SelectableText(email.isNotEmpty ? email : 'None', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Password:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          SelectableText(password, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Parent Credentials Card
                if (parentEmail != null && parentEmail.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PARENT PORTAL LOGIN (ACTIVE)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669), letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Parent Name:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            SelectableText(parentName ?? 'Parent', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Parent Email:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            SelectableText(parentEmail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Parent Password:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            SelectableText('123456', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Copy Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  icon: const Icon(Icons.copy, size: 16, color: AppTheme.textBody),
                  label: const Text('Copy All Credentials', style: TextStyle(fontSize: 13, color: AppTheme.textBody)),
                  onPressed: () {
                    String fullText = 'TutorOS Student Login\nUsername: $username\nEmail: $email\nPassword: $password\nBatch: $batchName';
                    if (parentEmail != null && parentEmail.isNotEmpty) {
                      fullText += '\n\nParent Portal Login\nParent Email: $parentEmail\nParent Password: 123456';
                    }
                    Clipboard.setData(ClipboardData(text: fullText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student & Parent credentials copied to clipboard!')),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // WhatsApp Send Button
                if (phone.isNotEmpty || (parentPhone != null && parentPhone.isNotEmpty))
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Share Credentials via WhatsApp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _launchWhatsApp(
                        phone: phone.isNotEmpty ? phone : (parentPhone ?? ''),
                        studentName: studentName,
                        username: username,
                        email: email,
                        password: password,
                        batchName: batchName,
                        parentEmail: parentEmail,
                        parentName: parentName,
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context, true);
              },
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final fName = _firstNameController.text.trim();
      final lName = _lastNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final studentCode = _studentCodeController.text.trim();
      final admissionNo = _admissionNoController.text.trim();
      final loginUsername = _loginUsernameController.text.trim().isNotEmpty
          ? _loginUsernameController.text.trim()
          : studentCode;
      final password = _passwordController.text.trim();

      // Parent details
      final parentName = _parentNameController.text.trim();
      final parentEmail = _parentEmailController.text.trim();
      final parentPhone = _parentPhoneController.text.trim();

      String batchName = '';
      if (_selectedBatchId != null && _batches.isNotEmpty) {
        final match = _batches.firstWhere(
          (b) => int.tryParse((b['batch_id'] ?? 0).toString()) == _selectedBatchId,
          orElse: () => {'batch_name': ''},
        );
        batchName = match['batch_name'] ?? '';
      }

      try {
        final data = <String, dynamic>{
          'first_name': fName,
          'last_name': lName,
          'email': email,
          'phone': phone,
          'current_address': _currentAddressController.text.trim(),
          'student_code': studentCode,
          'admission_no': admissionNo,
          'batch_id': _selectedBatchId,
          'username': loginUsername,
          'password': password,
          'avatar_url': _avatarUrl,
        };

        // If parent details provided, include in payload
        if (parentName.isNotEmpty || parentEmail.isNotEmpty || parentPhone.isNotEmpty) {
          data['parent_name'] = parentName.isNotEmpty ? parentName : '$lName Family';
          data['parent_email'] = parentEmail;
          data['parent_phone'] = parentPhone;
          data['parent_relationship'] = _parentRelationship;
        }
        
        await DirectoryService.addStudent(data);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showCredentialsPopup(
            studentName: '$fName $lName'.trim(),
            phone: phone,
            username: loginUsername,
            email: email,
            password: password,
            batchName: batchName,
            parentName: parentName,
            parentEmail: parentEmail,
            parentPhone: parentPhone,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e', style: const TextStyle(color: AppTheme.surfaceWhite)), backgroundColor: AppTheme.urgentText),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Add Student & Link Parent', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Student Photo Upload Section
              StudentPhotoUploadSection(
                initialAvatarUrl: _avatarUrl,
                onAvatarChanged: (url) {
                  setState(() {
                    _avatarUrl = url;
                  });
                },
              ),

              const SizedBox(height: 16),

              // 2. Academic & Batch Assignment Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_outlined, size: 18, color: AppTheme.electricCobalt),
                        SizedBox(width: 8),
                        Text('Batch & Admission Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Batch Selector Dropdown
                    _isLoadingBatches
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                        : DropdownButtonFormField<int>(
                            initialValue: _selectedBatchId,
                            decoration: const InputDecoration(
                              labelText: 'Assign Batch / Class *',
                              prefixIcon: Icon(Icons.groups_outlined, color: AppTheme.electricCobalt),
                              filled: true,
                              fillColor: AppTheme.canvasBackground,
                            ),
                            items: _batches.map((b) {
                              final bId = int.tryParse((b['batch_id'] ?? 0).toString()) ?? 0;
                              return DropdownMenuItem<int>(
                                value: bId,
                                child: Text(b['batch_name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBatchId = val;
                              });
                            },
                            validator: (val) => val == null ? 'Please select an academic batch' : null,
                          ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _studentCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Student ID / Code *',
                              hintText: 'e.g. STU-101',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.electricCobalt),
                              filled: true,
                              fillColor: AppTheme.canvasBackground,
                            ),
                            validator: (val) => Validators.validateRequired(val, 'Student Code'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _admissionNoController,
                            decoration: const InputDecoration(
                              labelText: 'Admission / Roll No *',
                              hintText: 'e.g. ADM-2024-001',
                              prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.electricCobalt),
                              filled: true,
                              fillColor: AppTheme.canvasBackground,
                            ),
                            validator: (val) => Validators.validateRequired(val, 'Admission Number'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Student Personal Profile Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: AppTheme.electricCobalt),
                        SizedBox(width: 8),
                        Text('Student Personal Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              hintText: 'e.g. Rahul',
                              prefixIcon: Icon(Icons.account_circle_outlined, color: AppTheme.electricCobalt),
                              filled: true,
                              fillColor: AppTheme.canvasBackground,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'First name is required';
                              if (val.trim().length < 2) return 'At least 2 characters';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              hintText: 'e.g. Sharma',
                              prefixIcon: Icon(Icons.account_circle_outlined, color: AppTheme.electricCobalt),
                              filled: true,
                              fillColor: AppTheme.canvasBackground,
                            ),
                            validator: (val) => Validators.validateRequired(val, 'Last Name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Student Mobile Phone *',
                        hintText: '10-digit mobile number',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.electricCobalt),
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.w600),
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validateIndianPhone(val, required: true),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Student Email Address *',
                        hintText: 'student@example.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.electricCobalt),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validateEmail(val, required: true),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _currentAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Residential Address *',
                        hintText: 'Street, Area, City, Pin Code',
                        prefixIcon: Icon(Icons.home_outlined, color: AppTheme.electricCobalt),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Address is required';
                        if (val.trim().length < 5) return 'Please enter a complete address (min 5 chars)';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Parent / Guardian Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.family_restroom_outlined, size: 18, color: AppTheme.electricCobalt),
                        SizedBox(width: 8),
                        Text('Parent / Guardian Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Link parent account to enable real-time tracking, reports, and WhatsApp alerts.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _parentRelationship,
                      decoration: const InputDecoration(
                        labelText: 'Relationship to Student *',
                        prefixIcon: Icon(Icons.people_outline, color: AppTheme.electricCobalt),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'FATHER', child: Text('Father')),
                        DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
                        DropdownMenuItem(value: 'GUARDIAN', child: Text('Guardian / Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _parentRelationship = val;
                          });
                        }
                      },
                      validator: (val) => val == null ? 'Please select relationship' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _parentNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Parent / Guardian Full Name *',
                        hintText: 'e.g. Ramesh Sharma',
                        prefixIcon: Icon(Icons.person_pin_outlined, color: AppTheme.electricCobalt),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validateRequired(val, 'Parent Name'),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _parentPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Parent Mobile Phone (For WhatsApp Reports)',
                        hintText: '10-digit mobile number',
                        prefixIcon: Icon(Icons.phone_android_outlined, color: AppTheme.electricCobalt),
                        prefixText: '+91 ',
                        prefixStyle: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.w600),
                        counterText: '',
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validateIndianPhone(val, required: false),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _parentEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Parent Portal Login Email',
                        hintText: 'parent@example.com (Generates Parent Login)',
                        prefixIcon: Icon(Icons.mark_email_read_outlined, color: AppTheme.electricCobalt),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validateEmail(val, required: false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Portal Login Setup Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 18, color: AppTheme.electricCobalt),
                        SizedBox(width: 8),
                        Text('Student Portal Login Credentials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _loginUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'Portal Login Username *',
                        hintText: 'e.g. STU-101',
                        prefixIcon: Icon(Icons.account_box_outlined, color: AppTheme.electricCobalt),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validateUsername(val, minLength: 3),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Initial Password *',
                        hintText: 'Min 6 characters',
                        prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.electricCobalt),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: AppTheme.textMuted),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: AppTheme.canvasBackground,
                      ),
                      validator: (val) => Validators.validatePassword(val, minLength: 6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCobalt,
                  foregroundColor: AppTheme.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.surfaceWhite, strokeWidth: 2))
                    : const Text('Save & Generate Portal Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
