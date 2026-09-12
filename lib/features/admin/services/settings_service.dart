import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

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
          return {
            'institute_id': inst['institute_id'],
            'tenant_id': inst['tenant_id'] ?? ApiService.currentTenantId,
            'institute_name': inst['institute_name'] ?? ApiService.currentInstituteName ?? '',
            'institute_code': inst['institute_code'] ?? ApiService.currentInstituteCode ?? '',
            'tagline': inst['legal_name'],
            'email': inst['email'],
            'phone': inst['phone'],
            'address': inst['address'],
            'city': inst['city'],
            'website': inst['website'],
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
  static Future<bool> addBranch(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_branch'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'branch_code': data['branch_code'],
          'branch_name': data['branch_name'],
          'address': data['location'],
          'phone': data['contact_phone'],
          'status': 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return true;
    }
  }

  /// Update an existing branch
  static Future<bool> updateBranch(int branchId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_branch/$branchId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'branch_code': data['branch_code'],
          'branch_name': data['branch_name'],
          'address': data['location'],
          'phone': data['contact_phone'],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return true;
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
}
