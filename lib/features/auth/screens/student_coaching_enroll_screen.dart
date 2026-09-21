import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../features/student/screens/student_dashboard.dart';
import '../../admin/screens/directory/widgets/student_photo_upload_section.dart';

class StudentCoachingEnrollScreen extends StatefulWidget {
  const StudentCoachingEnrollScreen({super.key});

  @override
  State<StudentCoachingEnrollScreen> createState() => _StudentCoachingEnrollScreenState();
}

class _StudentCoachingEnrollScreenState extends State<StudentCoachingEnrollScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  List<Map<String, dynamic>> _institutes = [];
  Map<String, dynamic>? _selectedInstitute;
  List<Map<String, dynamic>> _batches = [];
  bool _isLoadingBatches = false;
  int? _selectedBatchId;
  final _customBatchController = TextEditingController();

  // Student Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  String _parentRelationship = 'FATHER';
  String _avatarUrl = '';

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  int _currentStep = 0; // 0: Find Coaching, 1: Student Details, 2: Parent & Review

  @override
  void initState() {
    super.initState();
    _fetchInstitutes('');
    _firstNameController.addListener(_autoSuggestUsername);
  }

  void _autoSuggestUsername() {
    if (_usernameController.text.isEmpty || _usernameController.text.startsWith('stu_')) {
      final name = _firstNameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (name.isNotEmpty) {
        final suffix = DateTime.now().millisecondsSinceEpoch % 1000;
        _usernameController.text = 'stu_${name}_$suffix';
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _customBatchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchInstitutes(query.trim());
    });
  }

  Future<void> _fetchInstitutes(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ApiService.searchCoachingCenters(query);
      if (mounted) {
        setState(() {
          _institutes = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectInstitute(Map<String, dynamic> institute) async {
    final previewBatches = (institute['batches'] is List)
        ? (institute['batches'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    setState(() {
      _selectedInstitute = institute;
      _isLoadingBatches = true;
      _batches = previewBatches;
      _selectedBatchId = previewBatches.isNotEmpty
          ? int.tryParse(previewBatches.first['batch_id'].toString())
          : null;
    });

    try {
      final instId = int.parse((institute['institute_id'] ?? 0).toString());
      final batches = await ApiService.getCoachingBatches(instId);
      if (mounted) {
        setState(() {
          if (batches.isNotEmpty) {
            _batches = batches;
          }
          if (_batches.isNotEmpty) {
            final valid = _batches.any((b) => (int.tryParse(b['batch_id'].toString()) ?? 0) == _selectedBatchId);
            if (!valid) {
              _selectedBatchId = int.tryParse((_batches.first['batch_id'] ?? 0).toString());
            }
          } else {
            _selectedBatchId = null;
          }
          _isLoadingBatches = false;
          _currentStep = 1; // Move to details step
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingBatches = false;
          _currentStep = 1;
        });
      }
    }
  }

  Future<void> _submitEnrollment() async {
    if (_selectedInstitute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Coaching Center first.')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? batchNameToSend;
    int? batchIdToSend;

    if (_selectedBatchId != null && _selectedBatchId! > 0) {
      batchIdToSend = _selectedBatchId;
      final found = _batches.firstWhere(
        (b) => (int.tryParse(b['batch_id'].toString()) ?? 0) == _selectedBatchId,
        orElse: () => <String, dynamic>{},
      );
      batchNameToSend = found['batch_name']?.toString() ?? 'Batch #$_selectedBatchId';
    } else if (_customBatchController.text.trim().isNotEmpty) {
      batchIdToSend = null;
      batchNameToSend = _customBatchController.text.trim();
    } else {
      batchIdToSend = null;
      batchNameToSend = 'General Batch';
    }

    final payload = <String, dynamic>{
      'institute_id': _selectedInstitute!['institute_id'],
      'tenant_id': _selectedInstitute!['tenant_id'],
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
      'avatar_url': _avatarUrl,
      'batch_id': batchIdToSend,
      'custom_batch_name': batchNameToSend,
      'batch_name': batchNameToSend,
    };

    if (_parentNameController.text.trim().isNotEmpty || _parentPhoneController.text.trim().isNotEmpty) {
      payload['parent_name'] = _parentNameController.text.trim();
      payload['parent_phone'] = _parentPhoneController.text.trim();
      payload['parent_relationship'] = _parentRelationship;
    }

    try {
      final res = await ApiService.studentSelfEnroll(payload);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog(res);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.urgentText,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> res) {
    final instituteName = _selectedInstitute?['institute_name'] ?? 'Coaching Center';
    final studentName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.successText, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Enrollment Confirmed! 🎉',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textHeading),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome $studentName! You are now enrolled in $instituteName.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Username:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(_usernameController.text.trim(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Student Portal:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const Text('Active Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successText)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const StudentDashboard()),
                      (route) => false,
                    );
                  },
                  child: const Text('Go to Student Dashboard 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textHeading),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Student Coaching Enrollment',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textHeading),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                _buildStepPill(0, '1. Find Coaching', Icons.search_rounded),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                _buildStepPill(1, '2. Student Details', Icons.person_outline_rounded),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                _buildStepPill(2, '3. Review', Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ),
      ),
      body: _currentStep == 0
          ? _buildSearchStep()
          : (_currentStep == 1 ? _buildDetailsStep() : _buildReviewStep()),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStepPill(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.softBlue : (isDone ? AppTheme.successBg : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDone ? Icons.check_rounded : icon,
              size: 14,
              color: isActive ? AppTheme.electricCobalt : (isDone ? AppTheme.successText : AppTheme.textMuted),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.electricCobalt : (isDone ? AppTheme.successText : AppTheme.textMuted),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryNavy, AppTheme.electricCobalt],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Find Your Coaching Center',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Search by coaching name, institute code, or city to enroll in your classes.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
              ),
              const SizedBox(height: 14),
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search "Apex Academy", "Physics Hub", "Mumbai"...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.electricCobalt),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchInstitutes('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Results Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _searchController.text.trim().isEmpty ? 'Featured Coaching Centers' : 'Search Results (${_institutes.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
            ),
            if (_isSearching)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.electricCobalt),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_institutes.isEmpty && !_isSearching)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                const Text(
                  'No Coaching Centers Found',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try searching by a different name, city, or institute code.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._institutes.map((inst) => _buildInstituteCard(inst)),
      ],
    );
  }

  Widget _buildInstituteCard(Map<String, dynamic> inst) {
    final name = inst['institute_name'] ?? 'Coaching Center';
    final code = inst['institute_code'] ?? '';
    final city = inst['city'] ?? '';
    final state = inst['state'] ?? '';
    final location = [city, state].where((s) => s.isNotEmpty).join(', ');
    final batches = (inst['batches'] as List?) ?? [];
    final isSelected = _selectedInstitute?['institute_id'] == inst['institute_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectInstitute(inst),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Institute Avatar Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.electricCobalt.withValues(alpha: 0.8),
                          AppTheme.primaryNavy,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.softBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text(location, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 10),

              // Active Batches Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups_outlined, size: 15, color: AppTheme.electricCobalt),
                      const SizedBox(width: 6),
                      Text(
                        batches.isNotEmpty ? '${batches.length} Active Batches Available' : 'Open Enrollment',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textBody),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppTheme.successText : AppTheme.electricCobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _selectInstitute(inst),
                    child: Text(
                      isSelected ? 'Selected ✓' : 'Enroll Here →',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildDetailsStep() {
    final instituteName = _selectedInstitute?['institute_name'] ?? 'Coaching Center';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selected Center Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.softBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.electricCobalt.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.electricCobalt, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Enrolling Into:', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                      Text(instituteName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Photo Upload Section
          StudentPhotoUploadSection(
            initialAvatarUrl: _avatarUrl,
            onAvatarChanged: (url) {
              setState(() {
                _avatarUrl = url;
              });
            },
            title: 'Your Photo (Optional)',
            subtitle: 'Upload a clear portrait or choose a fun avatar',
          ),
          const SizedBox(height: 16),

          // Dynamic Coaching Center Real Batch Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_rounded, color: AppTheme.electricCobalt, size: 18),
                        SizedBox(width: 8),
                        Text('Target Batch / Class *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                      ],
                    ),
                    if (_batches.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_batches.length} Available Batches',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successText),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoadingBatches)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                else if (_batches.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    key: ValueKey('batch_dropdown_${_selectedInstitute?['institute_id']}_$_selectedBatchId'),
                    initialValue: _selectedBatchId != null && _batches.any((b) => (int.tryParse(b['batch_id'].toString()) ?? 0) == _selectedBatchId)
                        ? _selectedBatchId
                        : (_batches.isNotEmpty ? (int.tryParse(_batches.first['batch_id'].toString()) ?? 0) : null),
                    decoration: InputDecoration(
                      labelText: 'Select Coaching Center Batch *',
                      hintText: 'Choose from active batches',
                      prefixIcon: const Icon(Icons.class_outlined, color: AppTheme.electricCobalt),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: AppTheme.canvasBackground,
                    ),
                    isExpanded: true,
                    items: _batches.map((b) {
                      final id = int.tryParse(b['batch_id'].toString()) ?? 0;
                      final name = b['batch_name'] ?? 'Batch $id';
                      final code = (b['batch_code'] != null && b['batch_code'].toString().isNotEmpty) ? ' • ${b['batch_code']}' : '';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.electricCobalt),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$name$code',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textHeading),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBatchId = val;
                      });
                    },
                    validator: (val) => (val == null || val == 0) ? 'Please select a batch' : null,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the active batch you want to join in this coaching center.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.canvasBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.electricCobalt, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This coaching center has not added active batches yet. Enter your desired class name below to enroll:',
                            style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customBatchController,
                    decoration: InputDecoration(
                      labelText: 'Batch / Course / Class Name *',
                      hintText: 'e.g. Class 10 Foundation, JEE 2025, NEET Batch',
                      prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.electricCobalt),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: AppTheme.canvasBackground,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter batch or class name' : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: AppTheme.electricCobalt, size: 18),
                    SizedBox(width: 8),
                    Text('Student Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                  ],
                ),
                const SizedBox(height: 16),

                // First & Last Name
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: _inputDecoration('First Name *', Icons.person_outline),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: _inputDecoration('Last Name', Icons.person_outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Phone & Email - 10-digit Indian validation
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: _inputDecoration('Mobile Phone (for WhatsApp updates) *', Icons.phone_outlined).copyWith(
                    hintText: '9876543210',
                    helperText: '10-digit Indian mobile starting with 6-9',
                    counterText: '',
                  ),
                  validator: (v) => Validators.validateIndianPhone(v, required: true),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email Address (Optional)', Icons.email_outlined),
                ),
                const SizedBox(height: 12),

                // Username & Password
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Login Username *', Icons.badge_outlined),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 chars' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Create Portal Password *',
                    helperText: 'Min 6 chars with letters, numbers & symbols (e.g. Pass@123)',
                    helperMaxLines: 2,
                    labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
                    filled: true,
                    fillColor: AppTheme.canvasBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (v) => validatePassword(v, username: _usernameController.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parent Guardian Details (Optional)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.family_restroom_rounded, color: AppTheme.electricCobalt, size: 18),
                    SizedBox(width: 8),
                    Text('Parent / Guardian Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Tuition center can send attendance & fee receipts to parent WhatsApp.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _parentNameController,
                  decoration: _inputDecoration('Parent / Guardian Full Name', Icons.person_outline),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _parentPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: _inputDecoration('Parent WhatsApp Phone', Icons.phone_outlined).copyWith(
                    hintText: '9876543210',
                    helperText: '10-digit Indian mobile starting with 6-9',
                    counterText: '',
                  ),
                  validator: (v) => Validators.validateIndianPhone(v, required: false),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _parentRelationship,
                  decoration: _inputDecoration('Relationship', Icons.people_outline),
                  items: const [
                    DropdownMenuItem(value: 'FATHER', child: Text('Father')),
                    DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
                    DropdownMenuItem(value: 'GUARDIAN', child: Text('Guardian')),
                  ],
                  onChanged: (v) => setState(() => _parentRelationship = v ?? 'FATHER'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final instituteName = _selectedInstitute?['institute_name'] ?? 'Coaching Center';
    final studentName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    final customBatch = _customBatchController.text.trim();
    String batchDisplay = 'General Batch';

    if (_batches.isEmpty) {
      batchDisplay = customBatch.isNotEmpty ? customBatch : 'General Batch';
    } else if (_selectedBatchId != null) {
      final found = _batches.firstWhere((b) => int.tryParse(b['batch_id'].toString()) == _selectedBatchId, orElse: () => {'batch_name': 'General Batch'});
      batchDisplay = found['batch_name'] ?? 'General Batch';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: AppTheme.electricCobalt, size: 22),
                  SizedBox(width: 8),
                  Text('Confirm Enrollment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading)),
                ],
              ),
              const SizedBox(height: 16),
              _buildReviewRow('Coaching Center', instituteName, Icons.school_outlined),
              _buildReviewRow('Selected Batch / Class', batchDisplay, Icons.class_outlined),
              _buildReviewRow('Student Name', studentName, Icons.person_outline),
              _buildReviewRow('Phone Number', _phoneController.text.trim(), Icons.phone_outlined),
              _buildReviewRow('Login Username', _usernameController.text.trim(), Icons.badge_outlined),
              if (_parentNameController.text.trim().isNotEmpty)
                _buildReviewRow('Parent Contact', '${_parentNameController.text.trim()} (${_parentPhoneController.text.trim()})', Icons.family_restroom_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.electricCobalt, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By enrolling, your profile will be created in this coaching center and you will have immediate access to your courses and timetable.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
      prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderSubtle)),
      filled: true,
      fillColor: AppTheme.canvasBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget? _buildBottomBar() {
    if (_currentStep == 0) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            onPressed: () {
              setState(() => _currentStep--);
            },
            child: const Text('Back', style: TextStyle(color: AppTheme.textBody, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentStep == 1) {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _currentStep = 2);
                        }
                      } else if (_currentStep == 2) {
                        _submitEnrollment();
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _currentStep == 1 ? 'Continue to Review →' : 'Complete Enrollment 🚀',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
