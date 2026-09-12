import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import 'academics_service.dart';

class AcademicStructureService {
  // Batches
  static Future<List<Map<String, dynamic>>> getBatches() => AcademicsService.getBatches();
  static Future<List<Map<String, dynamic>>> getSubjects() => AcademicsService.getSubjects();

  // ===========================================================================
  // 1. ACADEMIC YEARS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getAcademicYears() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_academic_year'),
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

  static Future<bool> addAcademicYear(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_academic_year'),
        headers: ApiService.headers,
        body: jsonEncode({
          'year_code': data['year_code'],
          'year_name': data['year_name'],
          'start_date': data['start_date'],
          'end_date': data['end_date'],
          'is_current': data['is_current'] == true ? 1 : 0,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateAcademicYear(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_academic_year/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'year_code': data['year_code'],
          'year_name': data['year_name'],
          'start_date': data['start_date'],
          'end_date': data['end_date'],
          'is_current': data['is_current'] == true ? 1 : 0,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAcademicYear(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_academic_year/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 2. GRADES / CLASSES
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getGrades() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_grade'),
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

  static Future<bool> addGrade(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_grade'),
        headers: ApiService.headers,
        body: jsonEncode({
          'grade_code': data['grade_code'],
          'grade_name': data['grade_name'],
          'sequence_no': int.tryParse(data['sequence_no'].toString()) ?? 0,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateGrade(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_grade/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'grade_code': data['grade_code'],
          'grade_name': data['grade_name'],
          'sequence_no': int.tryParse(data['sequence_no'].toString()) ?? 0,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteGrade(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_grade/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 3. COURSE-SUBJECT MAPPING
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getMappedSubjects(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_course_subject?course_id=$courseId'),
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

  static Future<bool> mapSubjectToCourse({
    required int courseId,
    required int subjectId,
    int sequenceNo = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_course_subject'),
        headers: ApiService.headers,
        body: jsonEncode({
          'course_id': courseId,
          'subject_id': subjectId,
          'sequence_no': sequenceNo,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unmapSubjectFromCourse({
    required int courseId,
    required int subjectId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/map_course_subject/$courseId?subject_id=$subjectId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 4. CHAPTERS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getChapters(int subjectId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_chapter?subject_id=$subjectId'),
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

  static Future<bool> addChapter(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_chapter'),
        headers: ApiService.headers,
        body: jsonEncode({
          'subject_id': data['subject_id'],
          'chapter_code': data['chapter_code'],
          'chapter_name': data['chapter_name'],
          'sequence_no': int.tryParse(data['sequence_no'].toString()) ?? 1,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateChapter(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_chapter/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'chapter_code': data['chapter_code'],
          'chapter_name': data['chapter_name'],
          'sequence_no': int.tryParse(data['sequence_no'].toString()) ?? 1,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteChapter(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_chapter/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 5. TOPICS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getTopics([int? chapterId]) async {
    try {
      final url = chapterId != null
          ? '${ApiService.baseUrl}/master_curriculum_topic?chapter_id=$chapterId'
          : '${ApiService.baseUrl}/master_curriculum_topic';
      final response = await http.get(
        Uri.parse(url),
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

  static Future<bool> addTopic(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_topic'),
        headers: ApiService.headers,
        body: jsonEncode({
          'chapter_id': data['chapter_id'],
          'topic_code': data['topic_code'],
          'topic_name': data['topic_name'],
          'sequence_no': int.tryParse(data['sequence_no'].toString()) ?? 1,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateTopic(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_topic/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'topic_code': data['topic_code'],
          'topic_name': data['topic_name'],
          'sequence_no': int.tryParse(data['sequence_no'].toString()) ?? 1,
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteTopic(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_curriculum_topic/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 6. ROOMS & LABS
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_room'),
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

  static Future<bool> addRoom(Map<String, dynamic> data) async {
    try {
      final body = <String, dynamic>{
        if (data['branch_id'] != null) 'branch_id': data['branch_id'],
        'room_code': data['room_code'],
        'room_name': data['room_name'],
        'capacity': int.tryParse(data['capacity'].toString()) ?? 30,
        'is_lab': data['is_lab'] == true ? 1 : 0,
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'geofence_radius_m': int.tryParse(data['geofence_radius_m']?.toString() ?? '') ?? 50,
        'status': data['status'] ?? 'AVAILABLE',
      };
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_room'),
        headers: ApiService.headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateRoom(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_room/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'room_code': data['room_code'],
          'room_name': data['room_name'],
          'capacity': int.tryParse(data['capacity'].toString()) ?? 30,
          'is_lab': data['is_lab'] == true ? 1 : 0,
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'geofence_radius_m': int.tryParse(data['geofence_radius_m']?.toString() ?? '') ?? 50,
          'status': data['status'] ?? 'AVAILABLE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteRoom(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_room/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
