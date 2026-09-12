import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/avatar_image_helper.dart';
import '../../../services/directory_service.dart';

class StudentPhotoUploadSection extends StatefulWidget {
  final String initialAvatarUrl;
  final ValueChanged<String> onAvatarChanged;
  final String title;
  final String subtitle;

  const StudentPhotoUploadSection({
    super.key,
    this.initialAvatarUrl = '',
    required this.onAvatarChanged,
    this.title = 'Student Photo',
    this.subtitle = 'Upload a clear portrait or choose a preset avatar',
  });

  @override
  State<StudentPhotoUploadSection> createState() => _StudentPhotoUploadSectionState();
}

class _StudentPhotoUploadSectionState extends State<StudentPhotoUploadSection> {
  late String _currentAvatarUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=150&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.initialAvatarUrl;
  }

  @override
  void didUpdateWidget(covariant StudentPhotoUploadSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAvatarUrl != oldWidget.initialAvatarUrl) {
      _currentAvatarUrl = widget.initialAvatarUrl;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final Uint8List bytes = await pickedFile.readAsBytes();
      final uploadedUrl = await DirectoryService.uploadAvatar(bytes, pickedFile.name);

      if (mounted) {
        setState(() {
          _isUploading = false;
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            _currentAvatarUrl = uploadedUrl;
            widget.onAvatarChanged(_currentAvatarUrl);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: AppTheme.successText,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking/uploading image: $e'),
            backgroundColor: AppTheme.urgentText,
          ),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Student Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppTheme.electricCobalt),
                  ),
                  title: const Text('Choose from Gallery / Files', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select a JPG, PNG, or WEBP image', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppTheme.electricCobalt),
                  ),
                  title: const Text('Take a Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Use your device camera', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removePhoto() {
    setState(() {
      _currentAvatarUrl = '';
      widget.onAvatarChanged('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = _currentAvatarUrl.trim().isNotEmpty;
    final imageProvider = AvatarImageHelper.getImageProvider(_currentAvatarUrl);

    return Container(
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
          Row(
            children: [
              const Icon(Icons.photo_camera_rounded, size: 20, color: AppTheme.electricCobalt),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textHeading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),

          // Avatar Preview & Upload Action Buttons Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Preview Circle
              GestureDetector(
                onTap: _isUploading ? null : _showImageSourceOptions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceSubtle,
                        border: Border.all(
                          color: hasAvatar ? AppTheme.electricCobalt : AppTheme.borderSubtle,
                          width: 2.5,
                        ),
                        boxShadow: hasAvatar
                            ? [
                                BoxShadow(
                                  color: AppTheme.electricCobalt.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                        image: imageProvider != null
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.electricCobalt,
                                ),
                              ),
                            )
                          : (!hasAvatar
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: AppTheme.textMuted,
                                )
                              : null),
                    ),
                    // Small Camera Badge Overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCobalt,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surfaceWhite, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Action Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _showImageSourceOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricCobalt,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.upload_rounded, size: 16),
                          label: Text(
                            hasAvatar ? 'Change Photo' : 'Upload Photo',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (hasAvatar)
                          OutlinedButton.icon(
                            onPressed: _isUploading ? null : _removePhoto,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.urgentText,
                              side: const BorderSide(color: Color(0xFFFECDD3)),
                              backgroundColor: const Color(0xFFFFF1F2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text(
                              'Remove',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Supports JPG, PNG, WEBP (Max 5MB)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 12),

          // Preset Avatars Quick Select
          const Text(
            'Or select a preset avatar:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presetAvatars.map((url) {
                final isSelected = _currentAvatarUrl == url;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentAvatarUrl = url;
                      widget.onAvatarChanged(url);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle,
                              width: isSelected ? 3 : 1.5,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppTheme.electricCobalt,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
