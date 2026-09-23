import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../../../../core/services/storage_service.dart';

class SettingsService {
  /// Fetch Institute / Tenant Profile details
  static Future<Map<String, dynamic>> getInstituteProfile() async {
    try {
      final tenantId = ApiService.currentTenantId ?? 1;
      final userId = ApiService.currentUserId;
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/institute-profile?tenant_id=$tenantId&user_id=$userId'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final Map<String, dynamic> inst = (decoded is Map && decoded['data'] != null)
            ? Map<String, dynamic>.from(decoded['data'])
            : (decoded is Map ? Map<String, dynamic>.from(decoded) : {});

        String website = inst['website']?.toString() ?? '';
        String rawAvatar = (inst['avatar_url'] != null && inst['avatar_url'].toString().trim().isNotEmpty)
            ? inst['avatar_url'].toString().trim()
            : (inst['logo_url'] != null && inst['logo_url'].toString().trim().isNotEmpty)
                ? inst['logo_url'].toString().trim()
                : '';

        // If website field was contaminated with an avatar image URL/path, recover avatar and clear website
        if (website.contains('avatar_') || website.contains('/upload/') || website.endsWith('.png') || website.endsWith('.jpg') || website.endsWith('.webp')) {
          if (rawAvatar.isEmpty) {
            rawAvatar = website;
          }
          website = '';
        }

        final logoUrl = rawAvatar.isNotEmpty ? rawAvatar : (ApiService.currentAvatarUrl ?? '');
        if (logoUrl.isNotEmpty) {
          ApiService.currentAvatarUrl = logoUrl;
        }
        if (inst['institute_name'] != null && inst['institute_name'].toString().isNotEmpty) {
          ApiService.currentInstituteName = inst['institute_name'].toString();
        }
        return {
          'institute_id': inst['institute_id'] ?? ApiService.currentInstituteId ?? 1,
          'tenant_id': inst['tenant_id'] ?? ApiService.currentTenantId ?? 1,
          'institute_name': inst['institute_name'] ?? ApiService.currentInstituteName ?? 'Coaching Center',
          'institute_code': inst['institute_code'] ?? ApiService.currentInstituteCode ?? 'INS-1',
          'tagline': inst['tagline'] ?? '',
          'email': inst['email'] ?? '',
          'phone': inst['phone'] ?? '',
          'address': inst['address'] ?? '',
          'city': inst['city'] ?? '',
          'website': website,
          'logo_url': logoUrl,
          'avatar_url': logoUrl,
          'plan_name': inst['plan_name'] ?? 'Growth Pro',
          'active_students_limit': inst['active_students_limit'] ?? 'Unlimited',
          'sms_gateway_active': inst['sms_gateway_active'] ?? true,
          'academic_year': inst['academic_year'] ?? '2026-2027',
        };
      }
      throw Exception('Fallback profile');
    } catch (e) {
      return {
        'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
        'institute_name': ApiService.currentInstituteName ?? 'Coaching Center',
        'tagline': '',
        'email': '',
        'phone': '',
        'address': '',
        'city': '',
        'logo_url': ApiService.currentAvatarUrl ?? '',
        'avatar_url': ApiService.currentAvatarUrl ?? '',
        'website': '',
        'plan_name': 'Growth Pro',
        'active_students_limit': 'Unlimited',
        'sms_gateway_active': true,
        'academic_year': '2026-2027',
      };
    }
  }

  /// Update institute details
  static Future<bool> updateInstituteProfile(Map<String, dynamic> data) async {
    try {
      final tenantId = ApiService.currentTenantId ?? 1;

      // Ensure website is never contaminated with an image URL
      String websiteVal = data['website']?.toString() ?? '';
      if (websiteVal.contains('avatar_') || websiteVal.contains('/upload/')) {
        websiteVal = '';
      }

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/auth/institute-profile'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': tenantId,
          'institute_name': data['institute_name'],
          'tagline': data['tagline'],
          'email': data['email'],
          'phone': data['phone'],
          'website': websiteVal,
          'address': data['address'],
        }),
      );
      if (response.statusCode == 200 && data['institute_name'] != null) {
        ApiService.currentInstituteName = data['institute_name'];
      }
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch Institute Branches
  static Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_branch'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a new branch
  static Future<Map<String, dynamic>> addBranch(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_branch'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'branch_code': data['branch_code'],
          'branch_name': data['branch_name'],
          'address_line1': data['location'] ?? data['address'],
          'contact_phone': data['contact_phone'] ?? data['phone'],
          'email': data['email'],
          'image_url': data['image_url'],
          'password': data['password'],
          'status': 'ACTIVE',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Branch added successfully!'};
      }
      try {
        final decoded = jsonDecode(response.body);
        return {'success': false, 'message': decoded['message'] ?? 'Failed to add branch (${response.statusCode})'};
      } catch (_) {
        return {'success': false, 'message': 'Failed to add branch (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Update an existing branch
  static Future<Map<String, dynamic>> updateBranch(int branchId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_branch/$branchId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'branch_code': data['branch_code'],
          'branch_name': data['branch_name'],
          'address_line1': data['location'] ?? data['address'],
          'contact_phone': data['contact_phone'] ?? data['phone'],
          'email': data['email'],
          'image_url': data['image_url'],
          'password': data['password'],
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Branch updated successfully!'};
      }
      return {'success': false, 'message': 'Failed to update branch (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete a branch
  static Future<bool> deleteBranch(int branchId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_branch/$branchId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return true;
    }
  }

  /// Change Owner / Admin Password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    int? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/change-password'),
        headers: ApiService.headers,
        body: jsonEncode({
          'user_id': userId ?? ApiService.currentUserId,
          'tenant_id': ApiService.currentTenantId,
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Password changed successfully!'};
      } else {
        return {'success': false, 'message': decoded['message'] ?? 'Failed to update password.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Update Owner / Institute Profile Photo / Logo
  static Future<Map<String, dynamic>> updateProfilePhoto({
    required String avatarUrl,
    int? userId,
  }) async {
    // 1. Optimistically update reactive state & local storage (rolled back on failure)
    final previousAvatar = ApiService.currentAvatarUrl;
    ApiService.currentAvatarUrl = avatarUrl;
    if (ApiService.currentTenantId != null && ApiService.currentUserId != null) {
      await StorageService.saveSession(
        tenantId: ApiService.currentTenantId!,
        userId: ApiService.currentUserId!,
        instituteId: ApiService.currentInstituteId,
        token: ApiService.currentToken,
        role: ApiService.currentRole,
        firstName: ApiService.currentFirstName,
        lastName: ApiService.currentLastName,
        avatarUrl: avatarUrl,
        instituteName: ApiService.currentInstituteName,
        instituteCode: ApiService.currentInstituteCode,
      );
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/update-avatar'),
        headers: ApiService.headers,
        body: jsonEncode({
          'user_id': userId ?? ApiService.currentUserId,
          'tenant_id': ApiService.currentTenantId,
          'avatar_url': avatarUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return {'success': true, 'avatar_url': avatarUrl, 'message': decoded['message'] ?? 'Photo updated successfully!'};
      }

      ApiService.currentAvatarUrl = previousAvatar;
      String message = 'Failed to save photo on server (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        message = decoded['message'] ?? message;
      } catch (_) {}
      return {'success': false, 'avatar_url': previousAvatar, 'message': message};
    } catch (e) {
      ApiService.currentAvatarUrl = previousAvatar;
      return {'success': false, 'avatar_url': previousAvatar, 'message': 'Network error: unable to save photo.'};
    }
  }
}

