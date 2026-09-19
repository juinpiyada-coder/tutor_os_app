import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class AssessmentsService {
  /// Fetch all exams
  static Future<List<Map<String, dynamic>>> getExams() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_exam'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          if (map['title'] == null && map['exam_name'] != null) {
            map['title'] = map['exam_name'];
          }
          if (map['exam_name'] == null && map['title'] != null) {
            map['exam_name'] = map['title'];
          }
          if (map['exam_date'] == null && map['start_at'] != null) {
            map['exam_date'] = map['start_at'].toString().split(' ')[0];
          }
          return map;
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a new exam and return its generated exam_id if successful
  static Future<int?> createExam(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_exam'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'title': data['title'],
          'exam_name': data['title'],
          'batch_name': data['batch_name'],
          'batch_id': data['batch_id'] ?? 1,
          'exam_date': data['exam_date'] ?? DateTime.now().toIso8601String().split('T')[0],
          'duration_minutes': data['duration_minutes'] ?? 60,
          'total_marks': data['total_marks'] ?? 100,
          'pass_marks': data['pass_marks'] ?? 35,
          'status': 'PUBLISHED',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['id'] != null) {
          return int.tryParse(decoded['id'].toString());
        } else if (decoded is int) {
          return decoded;
        } else if (decoded is String) {
          return int.tryParse(decoded);
        }
        return 1;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing exam
  static Future<bool> updateExam(int examId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_exam/$examId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'title': data['title'],
          'exam_name': data['title'],
          'batch_name': data['batch_name'],
          'duration_minutes': data['duration_minutes'] ?? 60,
          'total_marks': data['total_marks'] ?? 100,
          'pass_marks': data['pass_marks'] ?? 35,
          'status': data['status'] ?? 'PUBLISHED',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Attach selected questions from Question Bank to an Exam
  static Future<bool> mapQuestionsToExam({
    required int examId,
    required List<Map<String, dynamic>> questions,
    bool replace = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_exam_question'),
        headers: ApiService.headers,
        body: jsonEncode({
          'exam_id': examId,
          'questions': questions,
          'replace': replace,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Get all questions mapped to a specific exam
  static Future<List<Map<String, dynamic>>> getExamQuestions(int examId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_exam_question?exam_id=$examId'),
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

  /// Fetch all assignments
  static Future<List<Map<String, dynamic>>> getAssignments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_assignment'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            if (map['description'] == null && map['instructions'] != null) {
              map['description'] = map['instructions'];
            }
            if (map['due_date'] == null && map['due_at'] != null) {
              map['due_date'] = map['due_at'].toString().split(' ')[0];
            }
            return map;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a new assignment
  static Future<bool> createAssignment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_assignment'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'title': data['title'],
          'instructions': data['description'] ?? (data['instructions'] ?? ''),
          'description': data['description'] ?? (data['instructions'] ?? ''),
          'batch_id': data['batch_id'] ?? 1,
          'due_at': data['due_at'] ?? (data['due_date'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0]),
          'max_marks': data['max_marks'] ?? 100,
          'status': 'PUBLISHED',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing assignment
  static Future<bool> updateAssignment(int assignmentId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_assignment/$assignmentId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'title': data['title'],
          'instructions': data['description'] ?? (data['instructions'] ?? ''),
          'description': data['description'] ?? (data['instructions'] ?? ''),
          'status': data['status'] ?? 'PUBLISHED',
          if (data['due_at'] != null || data['due_date'] != null)
            'due_at': data['due_at'] ?? data['due_date'],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all questions for an exam or subject
  static Future<List<Map<String, dynamic>>> getQuestions({int? examId}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_question'),
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

  /// Create a Question with multiple choice options and correct answer
  static Future<bool> createQuestionWithOptions(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_question'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'question_text': data['question_text'],
          'question_type': data['question_type'] ?? 'MCQ',
          'marks': data['marks'] ?? 2,
          'difficulty_level': data['difficulty_level'] ?? 'MEDIUM',
          'subject': data['subject'] ?? 'General Studies',
          'subject_id': data['subject_id'],
          'options': data['options'],
          'correct_answer': data['correct_answer'],
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing question
  static Future<bool> updateQuestion(int questionId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_question/$questionId'),
        headers: ApiService.headers,
        body: jsonEncode({
          'question_text': data['question_text'],
          'question_type': data['question_type'] ?? 'MCQ',
          'marks': data['marks'] ?? 2,
          'difficulty_level': data['difficulty_level'] ?? 'MEDIUM',
          'subject': data['subject'] ?? 'General Studies',
          'options': data['options'],
          'correct_answer': data['correct_answer'],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a question by ID
  static Future<bool> deleteQuestion(int questionId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_question/$questionId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete an exam
  static Future<bool> deleteExam(int examId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_exam/$examId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete an assignment
  static Future<bool> deleteAssignment(int assignmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_assignment/$assignmentId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

