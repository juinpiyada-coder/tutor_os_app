import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/universal_owner_header.dart';
import '../../../auth/screens/login_screen.dart';
import '../../services/settings_service.dart';
import '../../../../shared/widgets/avatar_image_helper.dart';
import '../directory/widgets/student_photo_upload_section.dart';
import 'roles_permissions_screen.dart';
import 'subscription_billing_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const SettingsScreen({super.key, this.onOpenDrawer});

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

  void _openOwnerPhotoUploadModal() {
    String currentPhoto = _profile['avatar_url'] ?? _profile['logo_url'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                        const Text(
                          'Owner & Institute Logo / Photo',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StudentPhotoUploadSection(
                      initialAvatarUrl: currentPhoto,
                      title: 'Center Logo & Owner Avatar',
                      subtitle: 'Upload a high-res center logo or choose an avatar',
                      onAvatarChanged: (url) {
                        setModalState(() {
                          currentPhoto = url;
                        });
                      },
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
                        if (currentPhoto.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select or upload a photo first.')),
                          );
                          return;
                        }
                        final res = await SettingsService.updateProfilePhoto(avatarUrl: currentPhoto);
                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (res['success'] == true) {
                          setState(() {
                            _profile['avatar_url'] = currentPhoto;
                            _profile['logo_url'] = currentPhoto;
                            final ws = (_profile['website'] ?? '').toString().toLowerCase();
                            if (ws.contains('avatar_') ||
                                ws.contains('/upload/') ||
                                ws.contains('data:image') ||
                                ws.contains(';base64,') ||
                                ws.endsWith('.png') ||
                                ws.endsWith('.jpg') ||
                                ws.endsWith('.webp')) {
                              _profile['website'] = '';
                            }
                          });
                          await _loadSettings();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile photo updated successfully!'), backgroundColor: AppTheme.successText),
                            );
                          }
                        } else {
                          setState(() {
                            _profile['avatar_url'] = res['avatar_url'] ?? '';
                            _profile['logo_url'] = res['avatar_url'] ?? '';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to update photo.'), backgroundColor: AppTheme.urgentText),
                          );
                        }
                      },
                      child: const Text('Save Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _openChangePasswordModal() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                        const Row(
                          children: [
                            Icon(Icons.lock_reset_rounded, color: AppTheme.electricCobalt, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Reset Admin Password',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Password must be at least 6 characters and contain letters, numbers, and symbols (e.g. Pass@123).',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: currentPassCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password *',
                        helperText: 'Min 6 chars with letters, numbers & symbols (e.g. Pass@123)',
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password *',
                        prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final curPass = currentPassCtrl.text.trim();
                              final newPass = newPassCtrl.text.trim();
                              final confPass = confirmPassCtrl.text.trim();

                              if (curPass.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your current password.')),
                                );
                                return;
                              }
                              final pwdErr = validatePassword(newPass, username: _profile['username']?.toString() ?? _profile['email']?.toString());
                              if (pwdErr != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(pwdErr), backgroundColor: AppTheme.urgentText),
                                );
                                return;
                              }
                              if (newPass != confPass) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('New passwords do not match.'), backgroundColor: AppTheme.urgentText),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              final res = await SettingsService.changePassword(
                                currentPassword: curPass,
                                newPassword: newPass,
                              );
                              setModalState(() => isSubmitting = false);

                              if (!mounted) return;
                              if (ctx.mounted) Navigator.pop(ctx);

                              if (res['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Password reset successfully!'),
                                    backgroundColor: AppTheme.successText,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Failed to reset password.'),
                                    backgroundColor: AppTheme.urgentText,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _openEditProfileModal() {
    final nameController = TextEditingController(text: _profile['institute_name']);
    final taglineController = TextEditingController(text: _profile['tagline']);
    final phoneController = TextEditingController(text: _profile['phone']);
    final emailController = TextEditingController(text: _profile['email']);
    final websiteController = TextEditingController(text: _profile['website']);
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: const InputDecoration(
                    labelText: 'Official Contact Phone',
                    hintText: '9876543210',
                    helperText: '10-digit Indian mobile starting with 6-9',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Official Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Official Website / Landing Page',
                    hintText: 'www.academy.com',
                    prefixIcon: Icon(Icons.language_outlined, size: 20),
                  ),
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
                    final phoneErr = validateIndianPhone(phoneController.text);
                    if (phoneErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
                      return;
                    }
                    final newInstName = nameController.text.trim();
                    final saved = await SettingsService.updateInstituteProfile({
                      'institute_name': newInstName,
                      'tagline': taglineController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'website': websiteController.text.trim(),
                      'address': addressController.text.trim(),
                    });
                    if (!mounted) return;
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (!saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save profile. Please check your connection and try again.'),
                          backgroundColor: AppTheme.urgentText,
                        ),
                      );
                      return;
                    }
                    await _loadSettings();
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
    final locationController = TextEditingController(text: existingBranch?['location'] ?? existingBranch?['address_line1'] ?? existingBranch?['address'] ?? '');
    final phoneController = TextEditingController(text: existingBranch?['contact_phone'] ?? existingBranch?['phone'] ?? '');
    final emailController = TextEditingController(text: existingBranch?['email'] ?? '');
    final passwordController = TextEditingController();
    String branchImageUrl = existingBranch?['image_url'] ?? '';
    bool obscurePassword = true;

    // Auto-generate branch code from coaching center name + sequential number
    // Format: [COACHINGCENTERNAME]-[001] (e.g., APEX-001 or FITJEE-001)
    String generateBranchCode() {
      final mainRaw = (_profile['institute_name'] ?? ApiService.currentInstituteName ?? '').toString().trim();
      String cleanBase = mainRaw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (cleanBase.isEmpty) {
        cleanBase = 'BR';
      } else if (cleanBase.length > 8) {
        // Keep prefix concise and memorable (first 8 uppercase chars if long)
        cleanBase = cleanBase.substring(0, 8);
      }

      // Calculate the next sequence number by checking existing branch codes
      int highestNum = 0;
      final numRegex = RegExp(r'-(\d+)$');
      for (final b in _branches) {
        final existingCode = (b['branch_code'] ?? '').toString();
        final match = numRegex.firstMatch(existingCode);
        if (match != null) {
          final parsed = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (parsed > highestNum) highestNum = parsed;
        }
      }
      final nextNum = ((highestNum > 0 ? highestNum : _branches.length) + 1).toString().padLeft(3, '0');
      return '$cleanBase-$nextNum';
    }

    if (!isEditing && codeController.text.trim().isEmpty) {
      codeController.text = generateBranchCode();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
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
                    const SizedBox(height: 12),

                    // Branch Campus Image / Logo Upload Section
                    StudentPhotoUploadSection(
                      initialAvatarUrl: branchImageUrl,
                      title: 'Branch Campus Photo / Logo',
                      subtitle: 'Upload campus building image or branch badge',
                      onAvatarChanged: (url) {
                        setModalState(() {
                          branchImageUrl = url;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Campus Name *',
                        hintText: 'e.g. Mumbai Central',
                        prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-_]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Branch Code *',
                        hintText: 'e.g. APEX-001',
                        helperText: 'Auto-associated with Coaching Center name + incremental number',
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.electricCobalt),
                          tooltip: 'Regenerate Code from Coaching Center name',
                          onPressed: () {
                            setModalState(() {
                              codeController.text = generateBranchCode();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / City Area Address',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      maxLength: 10,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: const InputDecoration(
                        labelText: 'Branch Contact Phone',
                        hintText: '9876543210',
                        helperText: '10-digit Indian mobile starting with 6-9',
                        counterText: '',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Branch Official Email',
                        hintText: 'branch@academy.com',
                        helperText: 'Valid email required if provided',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'Reset Branch Password (optional)' : 'Set Branch Access Password *',
                        helperText: 'Min 6 chars with letters, numbers & symbols (e.g. Pass@123)',
                        helperMaxLines: 2,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Branch Name is required.')),
                          );
                          return;
                        }
                        if (codeController.text.trim().isEmpty) {
                          codeController.text = generateBranchCode();
                        }
                        if (phoneController.text.trim().isNotEmpty) {
                          final branchPhoneErr = Validators.validateIndianPhone(phoneController.text, required: false);
                          if (branchPhoneErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(branchPhoneErr), backgroundColor: AppTheme.urgentText));
                            return;
                          }
                        }
                        // Email validation – if provided, must be valid (uses Validators.validateEmail)
                        if (emailController.text.trim().isNotEmpty) {
                          final emailErr = Validators.validateEmail(emailController.text.trim(), required: false);
                          if (emailErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(emailErr), backgroundColor: AppTheme.urgentText));
                            return;
                          }
                        }
                        final branchPass = passwordController.text.trim();
                        if (branchPass.isNotEmpty) {
                          final branchPassErr = validatePassword(branchPass);
                          if (branchPassErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(branchPassErr), backgroundColor: AppTheme.urgentText));
                            return;
                          }
                        }
                        final branchPayload = {
                          'branch_code': codeController.text.trim(),
                          'branch_name': nameController.text.trim(),
                          'location': locationController.text.trim(),
                          'contact_phone': phoneController.text.trim(),
                          'email': emailController.text.trim(),
                          'image_url': branchImageUrl,
                          if (branchPass.isNotEmpty) 'password': branchPass,
                        };

                        Map<String, dynamic> res;
                        if (isEditing) {
                          final bId = int.tryParse((existingBranch['branch_id'] ?? 1).toString()) ?? 1;
                          res = await SettingsService.updateBranch(bId, branchPayload);
                        } else {
                          res = await SettingsService.addBranch(branchPayload);
                        }

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _loadSettings();
                        if (mounted) {
                          final isOk = res['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? (isOk ? (isEditing ? 'Branch updated successfully!' : 'Branch added successfully with credentials!') : 'Failed to save branch')),
                              backgroundColor: isOk ? AppTheme.successText : AppTheme.urgentText,
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Add Branch Campus', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        title: 'Settings & Center Config',
        subtitle: 'Profile Logo, Multi-Campuses, Billing & Credentials',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Institute Profile Card (with Owner Image Upload)
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
    final avatarUrl = _profile['avatar_url'] ?? _profile['logo_url'] ?? '';

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
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _openOwnerPhotoUploadModal,
                        child: ValueListenableBuilder<String?>(
                          valueListenable: ApiService.avatarNotifier,
                          builder: (context, liveAvatar, _) {
                            final effectiveAvatar = (liveAvatar != null && liveAvatar.isNotEmpty)
                                ? liveAvatar
                                : avatarUrl;
                            final imageProvider = AvatarImageHelper.getImageProvider(effectiveAvatar);
                            return CircleAvatar(
                              radius: 26,
                              backgroundColor: AppTheme.primaryNavy,
                              backgroundImage: imageProvider,
                              onBackgroundImageError: (exception, stackTrace) {},
                              child: (imageProvider == null)
                                  ? const Icon(Icons.school, color: Colors.white, size: 26)
                                  : null,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _openOwnerPhotoUploadModal,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.electricCobalt,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined, color: AppTheme.electricCobalt, size: 20),
                    tooltip: 'Upload Owner / Institute Photo',
                    onPressed: _openOwnerPhotoUploadModal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.electricCobalt, size: 20),
                    tooltip: 'Edit Institute Profile',
                    onPressed: _openEditProfileModal,
                  ),
                ],
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
          final branchImg = b['image_url']?.toString() ?? '';
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: isPrimary ? AppTheme.academicBg : AppTheme.surfaceSubtle,
                    child: (branchImg.isNotEmpty)
                        ? Image.network(
                            branchImg,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.apartment_rounded,
                              color: isPrimary ? AppTheme.academicText : AppTheme.primaryNavy,
                              size: 22,
                            ),
                          )
                        : Icon(
                            Icons.apartment_rounded,
                            color: isPrimary ? AppTheme.academicText : AppTheme.primaryNavy,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              b['branch_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (b['branch_code'] != null && b['branch_code'].toString().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.softBlue,
                                border: Border.all(color: AppTheme.borderSubtle),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b['branch_code'].toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.electricCobalt,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              b['location'] ?? b['address_line1'] ?? b['address'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (b['contact_phone'] != null && b['contact_phone'].toString().isNotEmpty)
                  Text(b['contact_phone'].toString(), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
            subtitle: const Text('Update owner credentials & access security', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openChangePasswordModal,
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_a_photo_outlined, color: AppTheme.electricCobalt),
            title: const Text('Update Owner / Center Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Upload avatar, logo or campus branding', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openOwnerPhotoUploadModal,
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
