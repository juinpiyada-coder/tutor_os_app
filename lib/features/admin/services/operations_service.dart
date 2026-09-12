import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class OperationsService {
  /// Fetch all class schedules
  static Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_schedule'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load schedules');
      }
    } catch (e) {
      return [];
    }
  }

  /// Create a new schedule entry
  static Future<bool> addSchedule(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_schedule'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'day_of_week': data['day_of_week'] ?? 'MONDAY',
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'start_date': data['start_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
          'batch_id': data['batch_id'] ?? 1,
          'room_id': data['room_id'],
          'subject_name': data['subject_name'],
          'teacher_name': data['teacher_name'],
          'room_name': data['room_name'],
          'status': data['status'] ?? 'ACTIVE',
          'recurrence_status': 'ACTIVE',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing schedule entry
  static Future<bool> updateSchedule(int scheduleId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_schedule/$scheduleId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'day_of_week': data['day_of_week'] ?? 'MONDAY',
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'batch_id': data['batch_id'] ?? 1,
          'subject_name': data['subject_name'],
          'teacher_name': data['teacher_name'],
          'room_name': data['room_name'],
          'status': data['status'] ?? 'ACTIVE',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a schedule entry
  static Future<bool> deleteSchedule(int scheduleId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_schedule/$scheduleId'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch Staff Attendance records
  static Future<List<Map<String, dynamic>>> getStaffAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_staff_attendance'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      throw Exception('Empty or fallback needed');
    } catch (e) {
      return [];
    }
  }

  /// Fetch Student Attendance & Geo Check-In records
  static Future<List<Map<String, dynamic>>> getStudentAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_attendance'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Update staff attendance status
  static Future<bool> markStaffAttendance(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_staff_attendance'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'staff_id': data['staff_id'] ?? 1,
          'status': data['status'] ?? 'PRESENT',
          'check_in_time': data['check_in_time'] ?? DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return true;
    }
  }
}
