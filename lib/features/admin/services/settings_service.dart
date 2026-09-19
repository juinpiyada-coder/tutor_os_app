import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../../../../core/services/storage_service.dart';

class SettingsService {
  /// Fetch Institute / Tenant Profile details
  static Future<Map<String, dynamic>> getInstituteProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_institute'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> institutes = jsonDecode(response.body);
        if (institutes.isNotEmpty) {
          final inst = institutes.first as Map<String, dynamic>;
          final logoUrl = inst['logo_url'] ?? ApiService.currentAvatarUrl ?? '';
          if (logoUrl.toString().isNotEmpty) {
            ApiService.currentAvatarUrl = logoUrl.toString();
          }
          return {
            'institute_id': inst['institute_id'],
            'tenant_id': inst['tenant_id'] ?? ApiService.currentTenantId,
            'institute_name': inst['institute_name'] ?? ApiService.currentInstituteName ?? '',
            'institute_code': inst['institute_code'] ?? ApiService.currentInstituteCode ?? '',
            'tagline': inst['legal_name'] ?? inst['tagline'] ?? '',
            'email': inst['email'],
            'phone': inst['phone'],
            'address': inst['address'],
            'city': inst['city'],
            'website': inst['website'],
            'logo_url': logoUrl,
            'avatar_url': logoUrl,
            'plan_name': inst['plan_name'],
            'active_students_limit': inst['active_students_limit'],
            'sms_gateway_active': inst['sms_gateway_active'] ?? false,
            'academic_year': inst['academic_year'],
          };
        }
      }
      throw Exception('Fallback profile');
    } catch (e) {
      return {
        'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
        'institute_name': ApiService.currentInstituteName ?? '',
        'tagline': '',
        'email': '',
        'phone': '',
        'address': '',
        'city': '',
        'logo_url': ApiService.currentAvatarUrl ?? '',
        'avatar_url': ApiService.currentAvatarUrl ?? '',
        'website': '',
        'plan_name': '',
        'active_students_limit': '',
        'sms_gateway_active': false,
        'academic_year': '',
      };
    }
  }

  /// Update institute details
  static Future<bool> updateInstituteProfile(Map<String, dynamic> data) async {
    try {
      final instId = ApiService.currentInstituteId ?? ApiService.safeInstituteId;
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_institute/$instId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'institute_name': data['institute_name'],
          'legal_name': data['tagline'],
          'email': data['email'],
          'phone': data['phone'],
          'website': data['website'],
        }),
      );
      if (response.statusCode == 200 && data['institute_name'] != null) {
        ApiService.currentInstituteName = data['institute_name'];
      }
      return response.statusCode == 200;
    } catch (e) {
      return true;
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

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ApiService.currentAvatarUrl = avatarUrl;
        if (ApiService.currentTenantId != null && ApiService.currentUserId != null) {
          StorageService.saveSession(
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
        return {'success': true, 'avatar_url': avatarUrl, 'message': 'Photo updated successfully!'};
      } else {
        return {'success': false, 'message': decoded['message'] ?? 'Failed to update avatar.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}

