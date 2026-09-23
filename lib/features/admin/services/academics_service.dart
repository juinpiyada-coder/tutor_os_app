import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class AcademicsService {
  static Future<List<Map<String, dynamic>>> getBatches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_batch'),
        headers: ApiService.headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          if (decoded['data'] is List) {
            list = decoded['data'];
          } else if (decoded['batches'] is List) {
            list = decoded['batches'];
          }
        }
        
        final result = <Map<String, dynamic>>[];
        final seenIds = <int>{};
        for (var item in list) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            final id = int.tryParse((m['batch_id'] ?? m['id'] ?? '').toString());
            if (id != null && id > 0 && !seenIds.contains(id)) {
              seenIds.add(id);
              result.add({
                ...m,
                'batch_id': id,
                'batch_name': m['batch_name'] ?? m['name'] ?? 'Batch #$id',
                'batch_code': m['batch_code'] ?? 'BTC-$id',
              });
            }
          }
        }
        if (result.isNotEmpty) {
          return result;
        }
      }

      // Secondary fallback to /academic/batches
      final fallbackResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/academic/batches'),
        headers: ApiService.headers,
      );
      if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
        final dynamic decoded = jsonDecode(fallbackResponse.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        final result = <Map<String, dynamic>>[];
        final seenIds = <int>{};
        for (var item in list) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            final id = int.tryParse((m['batch_id'] ?? m['id'] ?? '').toString());
            if (id != null && id > 0 && !seenIds.contains(id)) {
              seenIds.add(id);
              result.add({
                ...m,
                'batch_id': id,
                'batch_name': m['batch_name'] ?? m['name'] ?? 'Batch #$id',
                'batch_code': m['batch_code'] ?? 'BTC-$id',
              });
            }
          }
        }
        return result;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_course'),
        headers: ApiService.headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load curriculum/courses');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> addBatch(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_batch'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to create batch: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> updateBatch(int batchId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_batch/$batchId'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteBatch(int batchId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_batch/$batchId'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_subject'),
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

  static Future<bool> addSubject(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_subject'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'institute_id': ApiService.safeInstituteId,
          'subject_code': data['subject_code'],
          'subject_name': data['subject_name'],
          'description': data['description'] ?? '',
          'status': 'ACTIVE',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateSubject(int subjectId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_subject/$subjectId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'subject_code': data['subject_code'],
          'subject_name': data['subject_name'],
          'description': data['description'] ?? '',
          'status': data['status'] ?? 'ACTIVE',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteSubject(int subjectId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_subject/$subjectId'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addCourse(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_course'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'institute_id': ApiService.safeInstituteId,
          'course_code': data['course_code'],
          'course_name': data['course_name'],
          'description': data['description'] ?? '',
          'duration_months': int.tryParse((data['duration_months'] ?? '12').toString()) ?? 12,
          'status': 'ACTIVE',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateCourse(int courseId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_course/$courseId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'course_code': data['course_code'],
          'course_name': data['course_name'],
          'description': data['description'] ?? '',
          'duration_months': int.tryParse((data['duration_months'] ?? '12').toString()) ?? 12,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteCourse(int courseId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_course/$courseId'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // BATCH TEACHER MAPPING (MAP_BATCH_TEACHER)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getBatchTeachers(int batchId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_batch_teacher?batch_id=$batchId'),
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

  static Future<bool> assignTeacherToBatch({
    required int batchId,
    required int staffId,
    bool isPrimary = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_batch_teacher'),
        headers: ApiService.headers,
        body: jsonEncode({
          'batch_id': batchId,
          'staff_id': staffId,
          'is_primary': isPrimary ? 1 : 0,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateTeacherBatchRole({
    required int batchId,
    required int staffId,
    required bool isPrimary,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/map_batch_teacher/$batchId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'staff_id': staffId,
          'is_primary': isPrimary ? 1 : 0,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeTeacherFromBatch({
    required int batchId,
    required int staffId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/map_batch_teacher/$batchId?staff_id=$staffId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // FACULTY LESSON PLANS (MASTER_LESSON_PLAN)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getLessonPlans({
    int? batchId,
    int? topicId,
    String? status,
  }) async {
    try {
      String query = '';
      if (batchId != null) query += '?batch_id=$batchId';
      if (topicId != null) query += '${query.isEmpty ? '?' : '&'}topic_id=$topicId';
      if (status != null && status != 'ALL') query += '${query.isEmpty ? '?' : '&'}status=$status';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_lesson_plan$query'),
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

  static Future<bool> createLessonPlan(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_lesson_plan'),
        headers: ApiService.headers,
        body: jsonEncode({
          'batch_id': data['batch_id'],
          'topic_id': data['topic_id'],
          'title': data['title'],
          'objectives': data['objectives'] ?? '',
          'planned_date': data['planned_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
          'status': data['status'] ?? 'PLANNED',
          'created_by_user_id': ApiService.currentUserId ?? 1,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateLessonPlan(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_lesson_plan/$id'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteLessonPlan(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_lesson_plan/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}



