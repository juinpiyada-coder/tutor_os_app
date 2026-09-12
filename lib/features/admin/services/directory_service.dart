import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class DirectoryService {
  static Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_student'),
        headers: ApiService.headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStaff() async {
    try {
      final response = await http.get(
        // Query the dedicated master_staff table
        Uri.parse('${ApiService.baseUrl}/master_staff'),
        headers: ApiService.headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>().where((staff) {
          // If logged in as coaching center admin, exclude super admin or solo owner duplicates
          final role = (staff['role_code'] ?? staff['designation'] ?? staff['role'] ?? 'TEACHER').toString().toUpperCase();
          if (role == 'STUDENT' || role == 'PARENT') return false;
          if (role == 'SUPER_ADMIN') return false;
          return true;
        }).toList();
      } else {
        throw Exception('Failed to load staff');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> addStudent(Map<String, dynamic> data) async {
    try {
      final payload = {
        'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
        'status': 'ACTIVE',
        'student_code': data['student_code'],
        'admission_no': data['admission_no'],
        'first_name': data['first_name'],
        'last_name': data['last_name'],
        'email': data['email'],
        'phone': data['phone'],
      };

      if (data['batch_id'] != null) {
        payload['batch_id'] = data['batch_id'];
      }
      if (data['password'] != null && data['password'].toString().isNotEmpty) {
        payload['password'] = data['password'];
      }
      if (data['username'] != null && data['username'].toString().isNotEmpty) {
        payload['username'] = data['username'];
      }
      if (data['avatar_url'] != null && data['avatar_url'].toString().isNotEmpty) {
        payload['avatar_url'] = data['avatar_url'];
      }
      if (data['current_address'] != null && data['current_address'].toString().isNotEmpty) {
        payload['current_address'] = data['current_address'];
      } else if (data['location'] != null && data['location'].toString().isNotEmpty) {
        payload['current_address'] = data['location'];
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_student'),
        headers: ApiService.headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to add student');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> addStaff(Map<String, dynamic> data) async {
    try {
      // Utilizing the existing signup endpoint to create a user and assign a role
      await ApiService.signup(
        data['username'],
        data['email'],
        data['password'],
        data['first_name'],
        data['role_code'] ?? 'TEACHER',
        lastName: data['last_name'],
        phone: data['phone'],
        avatarUrl: data['avatar_url'],
      );
      
      return true;
    } catch (e) {
      throw Exception('Failed to add staff: $e');
    }
  }

  static Future<bool> updateStaff(int staffId, Map<String, dynamic> data) async {
    try {
      final payload = <String, dynamic>{};
      if (data['first_name'] != null) payload['first_name'] = data['first_name'];
      if (data['last_name'] != null) payload['last_name'] = data['last_name'];
      if (data['email'] != null) payload['email'] = data['email'];
      if (data['phone'] != null) payload['phone'] = data['phone'];
      if (data['avatar_url'] != null) payload['avatar_url'] = data['avatar_url'];

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_staff/$staffId'),
        headers: ApiService.headers,
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateStudent(int studentId, Map<String, dynamic> data) async {
    try {
      final payload = {
        'first_name': data['first_name'],
        'last_name': data['last_name'],
        'email': data['email'],
        'phone': data['phone'],
      };
      if (data['batch_id'] != null) payload['batch_id'] = data['batch_id'];
      if (data['avatar_url'] != null) payload['avatar_url'] = data['avatar_url'];
      if (data['current_address'] != null) payload['current_address'] = data['current_address'];
      if (data['location'] != null) payload['current_address'] = data['location'];

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_student/$studentId'),
        headers: ApiService.headers,
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteStudent(int studentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_student/$studentId'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteStaff(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_user/$userId'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> uploadAvatar(dynamic bytes, String fileName) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'png';
      final base64Data = base64Encode(bytes);
      final dataUri = 'data:image/$ext;base64,$base64Data';

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/upload'),
        headers: ApiService.headers,
        body: jsonEncode({
          'base64': dataUri,
          'file_name': fileName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['url'] != null) {
          return data['url'].toString();
        }
      }
      return dataUri;
    } catch (e) {
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'png';
      return 'data:image/$ext;base64,${base64Encode(bytes)}';
    }
  }
}

