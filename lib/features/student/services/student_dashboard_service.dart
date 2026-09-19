import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class StudentDashboardService {
  /// Fetch aggregated student dashboard summary metrics
  static Future<Map<String, dynamic>> getStudentDashboardData() async {
    try {
      final classes = await getClasses();
      final assignments = await getAssignments();
      final exams = await getExams();
      final attendance = await getAttendance();

      int totalAttendance = attendance.length;
      int presentCount = attendance.where((a) {
        final st = (a['attendance_status'] ?? a['status'] ?? '').toString().toUpperCase();
        return st == 'PRESENT' || st == 'VERIFIED' || st == 'PENDING_VERIFICATION';
      }).length;
      String attendancePct = totalAttendance > 0 
          ? '${((presentCount / totalAttendance) * 100).toStringAsFixed(0)}%' 
          : '0%';

      final pendingAssignments = assignments.where((a) {
        final st = (a['status'] ?? '').toString().toUpperCase();
        return st != 'SUBMITTED' && st != 'GRADED';
      }).toList();

      String recentScore = '';
      String recentExamTitle = '';
      final completedExams = exams.where((e) {
        final st = (e['status'] ?? '').toString().toUpperCase();
        return st == 'COMPLETED' || st == 'PASSED' || st == 'FAILED';
      }).toList();

      if (completedExams.isNotEmpty) {
        final first = completedExams.first;
        final sc = first['score'] ?? first['marks_obtained'] ?? first['percentage'];
        if (sc != null) {
          recentScore = sc.toString().endsWith('%') ? sc.toString() : '$sc%';
        }
        recentExamTitle = (first['title'] ?? first['exam_name'] ?? first['subject'] ?? '').toString();
      }

      final stats = {
        'attendancePct': attendancePct,
        'attendanceSummary': totalAttendance > 0 ? '$presentCount of $totalAttendance sessions ($attendancePct)' : 'No attendance recorded',
        'avgScore': recentScore.isNotEmpty ? recentScore : 'N/A',
        'totalAssignments': assignments.length,
        'pendingAssignments': pendingAssignments.length,
        'totalExams': exams.length,
        'completedExams': completedExams.length,
        'classesCount': classes.length,
      };

      return {
        'stats': stats,
        'attendanceRate': attendancePct,
        'attendanceSummary': stats['attendanceSummary'],
        'classesCount': classes.length,
        'assignmentsDue': pendingAssignments.length.toString(),
        'recentTestScore': recentScore,
        'recentExamTitle': recentExamTitle,
        'upcomingClasses': classes,
        'assignments': assignments,
        'exams': exams,
        'attendance': attendance,
      };
    } catch (e) {
      return {
        'stats': {
          'attendancePct': '0%',
          'attendanceSummary': 'No attendance recorded',
          'avgScore': 'N/A',
          'totalAssignments': 0,
          'pendingAssignments': 0,
          'totalExams': 0,
          'completedExams': 0,
          'classesCount': 0,
        },
        'attendanceRate': '0%',
        'attendanceSummary': 'No attendance recorded',
        'classesCount': 0,
        'assignmentsDue': '0',
        'recentTestScore': '',
        'recentExamTitle': '',
        'upcomingClasses': <Map<String, dynamic>>[],
        'assignments': <Map<String, dynamic>>[],
        'exams': <Map<String, dynamic>>[],
        'attendance': <Map<String, dynamic>>[],
      };
    }
  }

  // 1. Classes & Daily Routine / Live Sessions API
  static Future<List<Map<String, dynamic>>> getClasses() async {
    List<Map<String, dynamic>> combined = [];
    try {
      // Fetch recurring daily class routine from master_schedule
      final schedRes = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_schedule'),
        headers: ApiService.headers,
      );
      if (schedRes.statusCode == 200) {
        final dynamic schedData = jsonDecode(schedRes.body);
        if (schedData is List && schedData.isNotEmpty) {
          for (final item in schedData) {
            final m = Map<String, dynamic>.from(item as Map);
            final title = m['subject_name'] ?? m['batch_name'] ?? 'Class Lecture';
            final subject = m['subject_name'] ?? _deriveSubject(title.toString());
            final startTime = m['start_time'] ?? '09:00 AM';
            final endTime = m['end_time'] ?? '10:00 AM';
            final day = m['day_of_week'] ?? 'Today';
            combined.add({
              ...m,
              'session_id': m['schedule_id'] ?? m['id'] ?? 1,
              'title': '$title ($day)',
              'subject': subject.toString().isNotEmpty ? subject : 'General Studies',
              'teacher': m['teacher_name'] ?? 'Faculty Instructor',
              'room': m['room_name'] ?? 'Lecture Hall 101',
              'time': '$startTime - $endTime',
              'status': m['status'] ?? 'SCHEDULED',
              'meet_url': m['meet_url'] ?? 'https://meet.google.com/new',
            });
          }
        }
      }
    } catch (_) {}

    try {
      // Also fetch live class sessions from txn_class_session
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_class_session'),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          for (final e in data) {
            final item = Map<String, dynamic>.from(e as Map);
            final title = item['topic'] ?? item['title'] ?? item['session_title'] ?? 'Live Session';
            final subject = item['subject'] ?? _deriveSubject(title.toString());
            combined.insert(0, {
              ...item,
              'session_id': item['session_id'] ?? item['id'],
              'title': title,
              'subject': subject.toString().isNotEmpty ? subject : 'General Studies',
              'teacher': item['teacher_name'] ?? item['faculty'] ?? 'Faculty Instructor',
              'room': item['room'] ?? item['room_no'] ?? 'Online Studio',
              'time': item['start_time'] ?? item['time'] ?? 'Today',
              'status': item['status'] ?? 'LIVE',
              'meet_url': item['meet_url'] ?? item['meeting_link'] ?? 'https://meet.google.com/new',
            });
          }
        }
      }
    } catch (_) {}

    return combined;
  }

  // 2. Study Materials & Curriculum Notes API
  static Future<List<Map<String, dynamic>>> getStudyMaterials() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_material'),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((e) {
            final item = Map<String, dynamic>.from(e as Map);
            final title = item['title'] ?? item['material_name'] ?? '';
            final subject = item['subject'] ?? _deriveSubject(title.toString());
            return {
              ...item,
              'doc_id': item['material_id'] ?? item['id'],
              'title': title,
              'subject': subject,
              'file_type': item['file_type'] ?? 'PDF',
              'size': item['file_size'] ?? '1.2 MB',
              'downloads': item['download_count'] ?? 0,
              'date': item['created_at']?.toString().split('T')[0] ?? '',
              'file_url': item['file_url'],
            };
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // 3. Assignments API
  static Future<List<Map<String, dynamic>>> getAssignments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_assignment'),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.map((e) {
            final item = Map<String, dynamic>.from(e as Map);
            final title = item['title'] ?? item['assignment_name'] ?? '';
            final subject = item['subject'] ?? _deriveSubject(title.toString());
            return {
              ...item,
              'assignment_id': item['assignment_id'] ?? item['id'],
              'title': title,
              'subject': subject,
              'due_date': item['due_date'],
              'status': item['status'] ?? 'PENDING',
              'total_marks': item['total_marks'] ?? 100,
              'description': item['description'] ?? item['instructions'] ?? '',
              'score': item['score'] ?? item['grade'],
              'feedback': item['feedback'],
            };
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // 4. Submit Assignment API
  static Future<bool> submitAssignment(int assignmentId, String submissionText, {String? attachmentUrl}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_assignment_submission'),
        headers: ApiService.headers,
        body: jsonEncode({
          'assignment_id': assignmentId,
          'student_id': ApiService.currentUserId ?? 1,
          'submission_text': submissionText,
          'file_url': attachmentUrl,
          'submitted_at': DateTime.now().toIso8601String(),
          'status': 'SUBMITTED',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // 5. Tests & Exams API
  static Future<List<Map<String, dynamic>>> getExams() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_exam'),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final title = map['title'] ?? map['exam_name'] ?? '';
            
            final subject = map['subject'] ?? _deriveSubject(title.toString());
            final durationVal = map['duration_minutes'] ?? map['duration'];
            final durationStr = durationVal != null
                ? (durationVal.toString().contains('m') ? durationVal.toString() : '${durationVal}m')
                : null;
            final dateVal = map['exam_date'] ?? map['date'] ?? map['start_at'];
            final cleanDate = (dateVal == null || dateVal.toString().contains('TBD') || dateVal.toString().isEmpty)
                ? null
                : dateVal.toString().split(' ')[0];

            return {
              ...map,
              'exam_id': map['exam_id'] ?? map['id'],
              'title': title,
              'subject': subject,
              'batch_name': map['batch_name'],
              'date': cleanDate,
              'duration': durationStr,
              'duration_minutes': durationVal != null ? int.tryParse(durationVal.toString().replaceAll(RegExp(r'[^0-9]'), '')) : null,
              'total_marks': map['total_marks'] ?? 100,
              'pass_marks': map['pass_marks'] ?? 40,
              'total_questions': map['total_questions'] ?? 10,
              'status': (map['status'] == null || map['status'] == 'PUBLISHED') ? 'LIVE' : map['status'],
              'syllabus': map['syllabus'],
            };
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  // 6. Exam Questions API
  static Future<List<Map<String, dynamic>>> getExamQuestions(int examId) async {
    try {
      final mapResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_exam_question?exam_id=$examId'),
        headers: ApiService.headers,
      );
      List<dynamic> data = [];
      if (mapResponse.statusCode == 200) {
        final decoded = jsonDecode(mapResponse.body);
        if (decoded is List) data = decoded;
      }

      if (data.isEmpty) {
        final qResponse = await http.get(
          Uri.parse('${ApiService.baseUrl}/master_question'),
          headers: ApiService.headers,
        );
        if (qResponse.statusCode == 200) {
          final decoded = jsonDecode(qResponse.body);
          if (decoded is List) data = decoded;
        }
      }

      if (data.isNotEmpty) {
        return data.map((item) {
          final q = Map<String, dynamic>.from(item as Map);
          List<dynamic> options = (q['options'] is List) ? List.from(q['options']) : [];

          return {
            ...q,
            'question_id': q['question_id'] ?? q['id'],
            'question_text': q['question_text'] ?? '',
            'marks': q['marks'] ?? q['default_marks'] ?? 4,
            'subject': q['subject'] ?? '',
            'options': options,
            'explanation': q['explanation'],
          };
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  // 7. Submit Exam Attempt API
  static Future<bool> submitExamAttempt({
    required int examId,
    required int score,
    required int totalMarks,
    required Map<int, dynamic> answers,
    int? timeSpentSeconds,
  }) async {
    try {
      final isPassed = (score / (totalMarks == 0 ? 1 : totalMarks)) >= 0.4;
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_exam_attempt'),
        headers: ApiService.headers,
        body: jsonEncode({
          'exam_id': examId,
          'student_id': ApiService.currentUserId ?? 1,
          'score': score,
          'total_marks': totalMarks,
          'percentage': ((score / (totalMarks == 0 ? 1 : totalMarks)) * 100).toStringAsFixed(1),
          'status': isPassed ? 'PASSED' : 'FAILED',
          'time_spent_seconds': timeSpentSeconds ?? 1200,
          'attempted_at': DateTime.now().toIso8601String(),
          'answers_json': jsonEncode(answers),
        }),
      );

      // Also record result in txn_result if available
      http.post(
        Uri.parse('${ApiService.baseUrl}/txn_result'),
        headers: ApiService.headers,
        body: jsonEncode({
          'exam_id': examId,
          'student_id': ApiService.currentUserId ?? 1,
          'marks_obtained': score,
          'max_marks': totalMarks,
          'grade': isPassed ? 'A' : 'C',
          'remarks': isPassed ? 'Exam Passed' : 'Needs Review',
        }),
      ).catchError((_) => http.Response('', 500));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // 8. Doubts & Discussion Forum API
  static Future<List<Map<String, dynamic>>> getDoubts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_doubt'),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return data.map((e) {
            final item = Map<String, dynamic>.from(e as Map);
            return {
              ...item,
              'doubt_id': item['doubt_id'] ?? item['id'],
              'title': item['title'] ?? item['query'] ?? '',
              'subject': item['subject'] ?? '',
              'date': item['created_at']?.toString().split('T')[0] ?? '',
              'status': item['status'] ?? 'OPEN',
              'teacher_reply': item['teacher_reply'] ?? item['response'],
              'teacher': item['teacher_name'],
            };
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> askDoubt(String title, String description, {String? subject}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_doubt'),
        headers: ApiService.headers,
        body: jsonEncode({
          'student_id': ApiService.currentUserId ?? 1,
          'title': title,
          'description': description,
          'subject': subject ?? '',
          'status': 'OPEN',
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> postDoubtReply(int doubtId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_doubt_message'),
        headers: ApiService.headers,
        body: jsonEncode({
          'doubt_id': doubtId,
          'sender_id': ApiService.currentUserId ?? 1,
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // 9. Attendance API & Student Check-In Flow
  static Future<bool> submitClassCheckIn({
    required int classSessionId,
    required int batchId,
    required String subject,
    double? latitude,
    double? longitude,
    String? locationName,
    String? photoUrl,
  }) async {
    try {
      final locStamp = locationName ?? 'Campus A (Room 102)';
      final coordStr = (latitude != null && longitude != null)
          ? ' [Coords: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}]'
          : '';
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_attendance'),
        headers: ApiService.headers,
        body: jsonEncode({
          'student_id': ApiService.currentUserId ?? 1,
          'class_session_id': classSessionId,
          'batch_id': batchId,
          'attendance_status': 'PENDING_VERIFICATION',
          'session_type': 'CLASSROOM',
          'marked_by': ApiService.currentUserId ?? 1,
          'notes': 'Student geo-tagged check-in at $locStamp$coordStr for $subject',
          'photo_url': photoUrl,
          'latitude': latitude,
          'longitude': longitude,
          'location_name': locStamp,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_attendance'),
        headers: ApiService.headers,
      );
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }

  // Subject derivation helper
  static String _deriveSubject(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('math') || lower.contains('calculus') || lower.contains('algebra') || lower.contains('integral') || lower.contains('trig')) {
      return 'Mathematics';
    } else if (lower.contains('physic') || lower.contains('optics') || lower.contains('wave') || lower.contains('flux') || lower.contains('emf')) {
      return 'Physics';
    } else if (lower.contains('chem') || lower.contains('organic') || lower.contains('reaction') || lower.contains('periodic')) {
      return 'Chemistry';
    } else if (lower.contains('bio') || lower.contains('cell') || lower.contains('genetics') || lower.contains('botany')) {
      return 'Biology';
    }
    return '';
  }
}
