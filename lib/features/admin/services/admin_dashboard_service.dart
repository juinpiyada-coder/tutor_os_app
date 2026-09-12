import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class AdminDashboardService {
  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/dashboard/stats'),
        headers: ApiService.headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch dashboard stats');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
