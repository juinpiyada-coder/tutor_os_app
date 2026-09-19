import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
  
  static int? currentTenantId;
  static int? currentInstituteId;  // Real institute_id (separate from tenant_id)
  static int? currentBranchId;     // Real branch_id for branch-level data isolation
  static int? currentUserId;
  static String? currentToken;
  static String? currentRole;
  static String? currentFirstName;
  static String? currentLastName;
  static String? currentEmail;
  static String? currentAvatarUrl;
  static String? currentInstituteName;
  static String? currentInstituteCode;
  static String? currentBranchName;

  /// Role checking helpers
  static bool get isSuperAdmin => (currentRole ?? '').toUpperCase() == 'SUPER_ADMIN';
  static bool get isSoloTutor => (currentRole ?? '').toUpperCase() == 'SOLO_TUTOR';
  static bool get isAdmin => (currentRole ?? '').toUpperCase() == 'ADMIN' || isSuperAdmin || isSoloTutor;
  static bool get isBranchAdmin => (currentRole ?? '').toUpperCase() == 'BRANCH_ADMIN';
  static bool get isTeacher => (currentRole ?? '').toUpperCase() == 'TEACHER' || isSoloTutor;
  static bool get isStudent => (currentRole ?? '').toUpperCase() == 'STUDENT';
  static bool get isParent => (currentRole ?? '').toUpperCase() == 'PARENT';

  /// Safe tenant ID — throws if not logged in (never falls back to 1)
  static int get tenantId {
    if (currentTenantId == null) throw StateError('Not logged in: tenant_id is null');
    return currentTenantId!;
  }

  /// Safe institute ID — falls back to tenantId if institute not loaded yet
  static int get safeInstituteId => currentInstituteId ?? currentTenantId ?? 0;

  /// Safe branch ID
  static int? get safeBranchId => currentBranchId;

  static Map<String, String> get headers {
    final Map<String, String> h = {
      'Content-Type': 'application/json',
    };
    if (currentTenantId != null) {
      h['X-Tenant-Id'] = currentTenantId.toString();
    }
    if (currentBranchId != null) {
      h['X-Branch-Id'] = currentBranchId.toString();
    }
    if (currentToken != null) {
      h['Authorization'] = 'Bearer $currentToken';
    }
    return h;
  }

  static void setSession({
    required int tenantId,
    required int userId,
    int? instituteId,
    int? branchId,
    String? token,
    String? role,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? instituteName,
    String? instituteCode,
    String? branchName,
  }) {
    currentTenantId = tenantId;
    currentInstituteId = instituteId;
    currentBranchId = branchId;
    currentUserId = userId;
    currentToken = token;
    currentRole = role;
    currentFirstName = firstName;
    currentLastName = lastName;
    currentAvatarUrl = avatarUrl;
    currentInstituteName = instituteName;
    currentInstituteCode = instituteCode;
    currentBranchName = branchName;

    // Persist to dual storage
    StorageService.saveSession(
      tenantId: tenantId,
      userId: userId,
      instituteId: instituteId,
      branchId: branchId,
      token: token,
      role: role,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      instituteName: currentInstituteName,
      instituteCode: currentInstituteCode,
      branchName: currentBranchName,
    );
  }

  static Future<void> initSessionFromStorage() async {
    final session = await StorageService.loadSession();
    if (session != null && session['tenant_id'] != null) {
      currentTenantId = int.tryParse(session['tenant_id'].toString());
      currentInstituteId = session['institute_id'] != null ? int.tryParse(session['institute_id'].toString()) : null;
      currentBranchId = session['branch_id'] != null ? int.tryParse(session['branch_id'].toString()) : null;
      currentUserId = int.tryParse(session['user_id'].toString());
      currentToken = session['token'];
      currentRole = session['role'];
      currentFirstName = session['first_name'];
      currentLastName = session['last_name'];
      currentAvatarUrl = session['avatar_url'];
      currentInstituteName = session['institute_name'];
      currentInstituteCode = session['institute_code'];
      currentBranchName = session['branch_name'];
    }
  }

  static void logout() {
    currentTenantId = null;
    currentInstituteId = null;
    currentBranchId = null;
    currentUserId = null;
    currentToken = null;
    currentRole = null;
    currentFirstName = null;
    currentLastName = null;
    currentAvatarUrl = null;
    currentInstituteName = null;
    currentInstituteCode = null;
    currentBranchName = null;
    StorageService.clearAll();
  }

  static Future<Map<String, dynamic>> login(String username, String password, {int? tenantId}) async {
    try {
      final Map<String, dynamic> body = {
        'username': username,
        'password': password,
      };
      if (tenantId != null) {
        body['tenant_id'] = tenantId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        final Map<String, dynamic> data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(rawData['data'])
            : (rawData is Map<String, dynamic> ? rawData : {});

        final Map<String, dynamic>? user = (data['user'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['user'])
            : ((rawData is Map<String, dynamic> && rawData['user'] is Map<String, dynamic>)
                ? Map<String, dynamic>.from(rawData['user'])
                : null);

        final String? token = data['token'] ?? (rawData is Map<String, dynamic> ? rawData['token'] : null);

        if (user != null && user['tenant_id'] != null) {
          setSession(
            tenantId: int.parse(user['tenant_id'].toString()),
            userId: int.parse((user['user_id'] ?? user['id']).toString()),
            instituteId: user['institute_id'] != null ? int.tryParse(user['institute_id'].toString()) : null,
            branchId: user['branch_id'] != null ? int.tryParse(user['branch_id'].toString()) : null,
            token: token,
            role: user['role'],
            firstName: user['first_name'],
            lastName: user['last_name'],
            avatarUrl: user['avatar_url'] ?? user['logo_url'],
            instituteName: user['institute_name'],
            instituteCode: user['institute_code'],
            branchName: user['branch_name'],
          );
        }

        // Return a unified response structure ensuring both top-level and nested access work seamlessly
        return {
          'token': token,
          'user': user ?? data,
          'data': data,
          'status': rawData is Map<String, dynamic> ? rawData['status'] : 'success',
          'message': rawData is Map<String, dynamic> ? rawData['message'] : 'Login successful',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> signup(
    String username,
    String email,
    String password,
    String firstName,
    String roleCode, {
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'tenant_id': currentTenantId ?? safeInstituteId,
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'role_code': roleCode,
      };
      if (lastName != null && lastName.isNotEmpty) payload['last_name'] = lastName;
      if (phone != null && phone.isNotEmpty) payload['phone'] = phone;
      if (avatarUrl != null && avatarUrl.isNotEmpty) payload['avatar_url'] = avatarUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: headers,
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = jsonDecode(response.body);
        final Map<String, dynamic> data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(rawData['data'])
            : (rawData is Map<String, dynamic> ? rawData : {});

        final String? token = data['token'] ?? (rawData is Map<String, dynamic> ? rawData['token'] : null);
        final Map<String, dynamic>? user = (data['user'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['user'])
            : null;

        final tenantIdVal = user?['tenant_id'] ?? data['tenant_id'] ?? rawData['tenant_id'];
        final userIdVal = user?['user_id'] ?? user?['id'] ?? data['user_id'] ?? data['id'] ?? rawData['user_id'];

        if (tenantIdVal != null && userIdVal != null) {
          setSession(
            tenantId: int.parse(tenantIdVal.toString()),
            userId: int.parse(userIdVal.toString()),
            instituteId: (user?['institute_id'] ?? data['institute_id']) != null
                ? int.tryParse((user?['institute_id'] ?? data['institute_id']).toString())
                : null,
            branchId: (user?['branch_id'] ?? data['branch_id']) != null
                ? int.tryParse((user?['branch_id'] ?? data['branch_id']).toString())
                : null,
            token: token,
            role: user?['role'] ?? data['role'] ?? roleCode,
            firstName: user?['first_name'] ?? data['first_name'] ?? firstName,
            lastName: user?['last_name'] ?? data['last_name'] ?? lastName,
            avatarUrl: user?['avatar_url'] ?? data['avatar_url'] ?? avatarUrl,
            instituteName: user?['institute_name'] ?? data['institute_name'],
            instituteCode: user?['institute_code'] ?? data['institute_code'],
            branchName: user?['branch_name'] ?? data['branch_name'],
          );
        }

        return {
          'token': token,
          'user': user ?? data,
          'data': data,
          'status': rawData is Map<String, dynamic> ? rawData['status'] : 'success',
          'message': rawData is Map<String, dynamic> ? rawData['message'] : 'Signup successful',
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          final msg = error['message'] ?? error['error'] ?? 'Failed to signup';
          throw Exception(msg);
        } catch (jsonErr) {
          if (jsonErr is Exception && jsonErr.toString().contains('Failed to signup') == false) {
            rethrow;
          }
          throw Exception('Failed to signup (${response.statusCode})');
        }
      }
    } catch (e) {
      final clean = e.toString().replaceAll(RegExp(r'^(Exception:\s*)+'), '');
      throw clean;
    }
  }

  static Future<Map<String, dynamic>> registerCoachingCenter({
    required String instituteName,
    required String username,
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
    String? website,
    bool isSoloTutor = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-coaching'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'institute_name': instituteName,
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'website': website,
          'is_solo_tutor': isSoloTutor,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = jsonDecode(response.body);
        final Map<String, dynamic> data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(rawData['data'])
            : (rawData is Map<String, dynamic> ? rawData : {});

        final String? token = data['token'] ?? (rawData is Map<String, dynamic> ? rawData['token'] : null);
        final Map<String, dynamic>? user = (data['user'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['user'])
            : null;

        final tenantIdVal = user?['tenant_id'] ?? data['tenant_id'] ?? rawData['tenant_id'];
        final userIdVal = user?['user_id'] ?? user?['id'] ?? data['user_id'] ?? data['id'] ?? rawData['user_id'];

        if (tenantIdVal != null && userIdVal != null) {
          setSession(
            tenantId: int.parse(tenantIdVal.toString()),
            userId: int.parse(userIdVal.toString()),
            instituteId: (user?['institute_id'] ?? data['institute_id']) != null
                ? int.tryParse((user?['institute_id'] ?? data['institute_id']).toString())
                : null,
            branchId: (user?['branch_id'] ?? data['branch_id']) != null
                ? int.tryParse((user?['branch_id'] ?? data['branch_id']).toString())
                : null,
            token: token,
            role: user?['role'] ?? data['role'] ?? (isSoloTutor ? 'SOLO_TUTOR' : 'ADMIN'),
            firstName: user?['first_name'] ?? data['first_name'] ?? firstName,
            lastName: user?['last_name'] ?? data['last_name'] ?? lastName,
            avatarUrl: user?['avatar_url'] ?? data['avatar_url'],
            instituteName: user?['institute_name'] ?? data['institute_name'] ?? instituteName,
            instituteCode: user?['institute_code'] ?? data['institute_code'],
            branchName: user?['branch_name'] ?? data['branch_name'],
          );
        }
        return {
          'token': token,
          'user': user ?? data,
          'data': data,
          'tenant_id': tenantIdVal,
          'user_id': userIdVal,
          'role': user?['role'] ?? data['role'] ?? (isSoloTutor ? 'SOLO_TUTOR' : 'ADMIN'),
          'status': rawData is Map<String, dynamic> ? rawData['status'] : 'success',
          'message': rawData is Map<String, dynamic> ? rawData['message'] : 'Registration successful',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to register coaching center');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Platform Super Admin: Fetch all registered coaching centers and metrics
  static Future<Map<String, dynamic>> getSuperAdminStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/super_admin/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load Super Admin stats');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetch Solo Tutor (Educator + Admin) Unified Analytics & Teaching Schedule
  static Future<Map<String, dynamic>> getSoloDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/solo'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load Solo Tutor dashboard metrics');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Register Dedicated Solo Tutor Coaching Center (Admin + Teacher in one)
  static Future<Map<String, dynamic>> registerSoloCoachingCenter({
    required String instituteName,
    required String username,
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
    String? website,
    String? primarySubject,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register-coaching'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'institute_name': instituteName,
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'website': website,
          'is_solo_tutor': true,
          'role': 'SOLO_TUTOR',
          'primary_subject': primarySubject ?? 'General Studies',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawData = jsonDecode(response.body);
        final Map<String, dynamic> data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(rawData['data'])
            : (rawData is Map<String, dynamic> ? rawData : {});

        final String? token = data['token'] ?? (rawData is Map<String, dynamic> ? rawData['token'] : null);
        final Map<String, dynamic>? user = (data['user'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['user'])
            : null;

        final tenantIdVal = user?['tenant_id'] ?? data['tenant_id'] ?? rawData['tenant_id'];
        final userIdVal = user?['user_id'] ?? user?['id'] ?? data['user_id'] ?? data['id'] ?? rawData['user_id'];

        if (tenantIdVal != null && userIdVal != null) {
          setSession(
            tenantId: int.parse(tenantIdVal.toString()),
            userId: int.parse(userIdVal.toString()),
            instituteId: (user?['institute_id'] ?? data['institute_id']) != null
                ? int.tryParse((user?['institute_id'] ?? data['institute_id']).toString())
                : null,
            branchId: (user?['branch_id'] ?? data['branch_id']) != null
                ? int.tryParse((user?['branch_id'] ?? data['branch_id']).toString())
                : null,
            token: token,
            role: user?['role'] ?? data['role'] ?? 'SOLO_TUTOR',
            firstName: user?['first_name'] ?? data['first_name'] ?? firstName,
            lastName: user?['last_name'] ?? data['last_name'] ?? lastName,
            avatarUrl: user?['avatar_url'] ?? data['avatar_url'],
            instituteName: user?['institute_name'] ?? data['institute_name'] ?? instituteName,
            instituteCode: user?['institute_code'] ?? data['institute_code'],
            branchName: user?['branch_name'] ?? data['branch_name'],
          );
        }
        return {
          'token': token,
          'user': user ?? data,
          'data': data,
          'tenant_id': tenantIdVal,
          'user_id': userIdVal,
          'role': user?['role'] ?? data['role'] ?? 'SOLO_TUTOR',
          'status': rawData is Map<String, dynamic> ? rawData['status'] : 'success',
          'message': rawData is Map<String, dynamic> ? rawData['message'] : 'Registration successful',
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to register Solo Tutor center');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Platform Super Admin: Update coaching center status or multi-branch plan
  static Future<bool> updateTenantStatus(int tenantId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/super_admin/tenant_update/$tenantId'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Search active coaching centers for student self-enrollment
  static Future<List<Map<String, dynamic>>> searchCoachingCenters(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/search-coaching?query=${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is Map && raw['data'] is List) {
          return (raw['data'] as List).cast<Map<String, dynamic>>();
        } else if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get batches for a selected coaching institute
  static Future<List<Map<String, dynamic>>> getCoachingBatches(int instituteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/coaching-batches/$instituteId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is Map && raw['data'] is List) {
          return (raw['data'] as List).cast<Map<String, dynamic>>();
        } else if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Student Self-Registration & Coaching Center Enrollment
  static Future<Map<String, dynamic>> studentSelfEnroll(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/student-enroll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final rawData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = (rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(rawData['data'])
            : (rawData is Map<String, dynamic> ? rawData : {});

        final Map<String, dynamic>? user = (data['user'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['user'])
            : null;

        final String? token = data['token'] ?? (rawData is Map<String, dynamic> ? rawData['token'] : null);

        if (user != null && user['tenant_id'] != null) {
          setSession(
            tenantId: int.parse(user['tenant_id'].toString()),
            userId: int.parse((user['user_id'] ?? user['id']).toString()),
            instituteId: user['institute_id'] != null ? int.tryParse(user['institute_id'].toString()) : null,
            branchId: user['branch_id'] != null ? int.tryParse(user['branch_id'].toString()) : null,
            token: token,
            role: 'STUDENT',
            firstName: user['first_name'],
            lastName: user['last_name'],
            avatarUrl: user['avatar_url'],
            instituteName: user['institute_name'],
            instituteCode: user['institute_code'],
          );
        }

        return {
          'token': token,
          'user': user ?? data,
          'data': data,
          'message': rawData['message'] ?? 'Enrollment successful!',
        };
      } else {
        throw Exception(rawData['message'] ?? 'Failed to enroll');
      }
    } catch (e) {
      final clean = e.toString().replaceAll(RegExp(r'^(Exception:\s*)+'), '');
      throw clean;
    }
  }
}
