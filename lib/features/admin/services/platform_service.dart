import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class PlatformService {
  // ===========================================================================
  // 1. ROLES
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_role'),
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

  static Future<bool> addRole(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_role'),
        headers: ApiService.headers,
        body: jsonEncode({
          'role_name': data['role_name'],
          'role_code': data['role_code'] ?? '',
          'role_scope': 'TENANT',
          'is_system_role': 0,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateRole(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_role/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'role_name': data['role_name'],
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteRole(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_role/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 2. PERMISSIONS & RBAC MATRIX
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getPermissions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_permission'),
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

  static Future<List<Map<String, dynamic>>> getRolePermissions(int roleId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_role_permission?role_id=$roleId'),
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

  static Future<bool> grantPermission(int roleId, int permissionId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_role_permission'),
        headers: ApiService.headers,
        body: jsonEncode({
          'role_id': roleId,
          'permission_id': permissionId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokePermission(int roleId, int permissionId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/map_role_permission/$roleId?permission_id=$permissionId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 3. PLANS & SUBSCRIPTIONS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_plan'),
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

  static Future<List<Map<String, dynamic>>> getSubscriptions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_subscription'),
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

  static Future<bool> subscribePlan({
    required int planId,
    bool autoRenew = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_subscription'),
        headers: ApiService.headers,
        body: jsonEncode({
          'plan_id': planId,
          'start_date': DateTime.now().toIso8601String().split('T')[0],
          'end_date': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
          'status': 'ACTIVE',
          'auto_renew': autoRenew ? 1 : 0,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSubscriptionInvoices({int? subscriptionId}) async {
    try {
      String query = subscriptionId != null ? '?subscription_id=$subscriptionId' : '';
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_subscription_invoice$query'),
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
}
