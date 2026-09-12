import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class PeopleService {
  // ===========================================================================
  // 1. PARENTS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getParents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_parent'),
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

  static Future<bool> addParent(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_parent'),
        headers: ApiService.headers,
        body: jsonEncode({
          'first_name': data['first_name'],
          'last_name': data['last_name'] ?? '',
          'phone': data['phone'],
          'alternate_phone': data['alternate_phone'] ?? '',
          'email': data['email'],
          'occupation': data['occupation'] ?? '',
          'parent_code': data['parent_code'] ?? '',
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateParent(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_parent/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'first_name': data['first_name'],
          'last_name': data['last_name'] ?? '',
          'phone': data['phone'],
          'alternate_phone': data['alternate_phone'] ?? '',
          'email': data['email'],
          'occupation': data['occupation'] ?? '',
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteParent(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_parent/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 2. STUDENT - PARENT MAPPING
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getParentsByStudent(int studentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_student_parent?student_id=$studentId'),
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

  static Future<bool> linkStudentParent({
    required int studentId,
    required int parentId,
    String relationshipCode = 'GUARDIAN',
    bool isPrimary = true,
    bool receivesNotifications = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_student_parent'),
        headers: ApiService.headers,
        body: jsonEncode({
          'student_id': studentId,
          'parent_id': parentId,
          'relationship_code': relationshipCode,
          'is_primary': isPrimary ? 1 : 0,
          'receives_notifications': receivesNotifications ? 1 : 0,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unlinkStudentParent({
    required int studentId,
    required int parentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/map_student_parent/$studentId?parent_id=$parentId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 3. STUDENT ACADEMIC ENROLLMENT (ROLL & GRADE ASSIGNMENT)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getStudentAcademics({
    int? studentId,
    int? yearId,
    int? gradeId,
  }) async {
    try {
      String query = '';
      if (studentId != null) query += '?student_id=$studentId';
      if (yearId != null) query += '${query.isEmpty ? '?' : '&'}academic_year_id=$yearId';
      if (gradeId != null) query += '${query.isEmpty ? '?' : '&'}grade_id=$gradeId';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_student_academic$query'),
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

  static Future<bool> enrollStudentAcademic(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_student_academic'),
        headers: ApiService.headers,
        body: jsonEncode({
          'student_id': data['student_id'],
          'academic_year_id': data['academic_year_id'],
          'grade_id': data['grade_id'],
          'roll_no': data['roll_no'] ?? '',
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStudentAcademic(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_student_academic/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'academic_year_id': data['academic_year_id'],
          'grade_id': data['grade_id'],
          'roll_no': data['roll_no'] ?? '',
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteStudentAcademic(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_student_academic/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 4. STAFF BRANCH ASSIGNMENT
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getStaffBranches(int staffId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_staff_branch?staff_id=$staffId'),
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

  static Future<bool> assignStaffBranch({
    required int staffId,
    required int branchId,
    bool isPrimary = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_staff_branch'),
        headers: ApiService.headers,
        body: jsonEncode({
          'staff_id': staffId,
          'branch_id': branchId,
          'is_primary': isPrimary ? 1 : 0,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeStaffBranch({
    required int staffId,
    required int branchId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/map_staff_branch/$staffId?branch_id=$branchId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
