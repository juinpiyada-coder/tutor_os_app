import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class CommunicationsService {
  // ==========================================
  // 1. BROADCASTS & MESSAGES (TXN_MESSAGE & TXN_MESSAGE_RECIPIENT)
  // ==========================================

  /// Fetch Broadcasts / Announcements
  static Future<List<Map<String, dynamic>>> getBroadcasts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_message'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Send a new broadcast notice
  static Future<bool> sendBroadcast(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_message'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'subject': data['title'] ?? data['subject'],
          'body': data['content'] ?? data['body'],
          'channel': data['channel'] ?? 'PUSH',
          'message_type': 'BROADCAST',
          'target': data['target'] ?? 'ALL',
          'template_id': data['template_id'],
          'status': 'SENT',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing broadcast notice
  static Future<bool> updateBroadcast(dynamic broadcastId, Map<String, dynamic> data) async {
    try {
      final id = int.tryParse(broadcastId.toString()) ?? 0;
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_message/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'subject': data['title'] ?? data['subject'],
          'body': data['content'] ?? data['body'],
          'channel': data['channel'] ?? 'PUSH',
          'target': data['target'] ?? 'ALL',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a broadcast notice
  static Future<bool> deleteBroadcast(dynamic broadcastId) async {
    try {
      final id = int.tryParse(broadcastId.toString()) ?? 0;
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_message/$id'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 2. MESSAGE TEMPLATES (MASTER_MESSAGE_TEMPLATE)
  // ==========================================

  /// Fetch Message Templates
  static Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_message_template'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create Message Template
  static Future<bool> createTemplate(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_message_template'),
        headers: ApiService.headers,
        body: jsonEncode({
          'tenant_id': ApiService.currentTenantId ?? ApiService.safeInstituteId,
          'institute_id': ApiService.safeInstituteId,
          'template_code': data['template_code'] ?? 'TMPL_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          'template_name': data['template_name'],
          'channel': (data['channel'] ?? 'WHATSAPP').toString().toUpperCase(),
          'subject_template': data['subject_template'] ?? '',
          'body_template': data['body_template'],
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update Message Template
  static Future<bool> updateTemplate(dynamic templateId, Map<String, dynamic> data) async {
    try {
      final id = int.tryParse(templateId.toString()) ?? 0;
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_message_template/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'template_code': data['template_code'],
          'template_name': data['template_name'],
          'channel': (data['channel'] ?? 'WHATSAPP').toString().toUpperCase(),
          'subject_template': data['subject_template'] ?? '',
          'body_template': data['body_template'],
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete Message Template
  static Future<bool> deleteTemplate(dynamic templateId) async {
    try {
      final id = int.tryParse(templateId.toString()) ?? 0;
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_message_template/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 3. NOTIFICATION PREFERENCES (MASTER_NOTIFICATION_PREFERENCE)
  // ==========================================

  /// Fetch Notification Preferences
  static Future<List<Map<String, dynamic>>> getNotificationPreferences() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_notification_preference'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // 4. MARKETING CAMPAIGNS (MASTER_CAMPAIGN)
  // ==========================================

  /// Fetch Marketing Campaigns
  static Future<List<Map<String, dynamic>>> getCampaigns() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_campaign'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create Marketing Campaign
  static Future<bool> createCampaign(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_campaign'),
        headers: ApiService.headers,
        body: jsonEncode({
          'campaign_code': data['campaign_code'] ?? 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          'campaign_name': data['campaign_name'],
          'start_date': data['start_date'],
          'end_date': data['end_date'],
          'budget': data['budget'],
          'status': data['status'] ?? 'PLANNED',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update Marketing Campaign
  static Future<bool> updateCampaign(dynamic campaignId, Map<String, dynamic> data) async {
    try {
      final id = int.tryParse(campaignId.toString()) ?? 0;
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_campaign/$id'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete Marketing Campaign
  static Future<bool> deleteCampaign(dynamic campaignId) async {
    try {
      final id = int.tryParse(campaignId.toString()) ?? 0;
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_campaign/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 5. REFERRALS (TXN_REFERRAL)
  // ==========================================

  /// Fetch Referrals
  static Future<List<Map<String, dynamic>>> getReferrals() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_referral'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create Referral
  static Future<bool> createReferral(Map<String, dynamic> data) async {
    try {
      final payload = <String, dynamic>{
        'referrer_student_id': data['referrer_student_id'],
        'referrer_parent_id': data['referrer_parent_id'],
        'referral_date': data['referral_date'] ?? DateTime.now().toIso8601String().split('T')[0],
        'notes': data['notes'],
        'status': data['status'] ?? 'PENDING',
      };
      if (data['campaign_id'] != null) payload['campaign_id'] = data['campaign_id'];
      if (data['lead_name'] != null) payload['lead_name'] = data['lead_name'];
      if (data['lead_phone'] != null) payload['lead_phone'] = data['lead_phone'];

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_referral'),
        headers: ApiService.headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update Referral Status
  static Future<bool> updateReferralStatus(dynamic referralId, String newStatus) async {
    try {
      final id = int.tryParse(referralId.toString()) ?? 0;
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_referral/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'status': newStatus,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete Referral
  static Future<bool> deleteReferral(dynamic referralId) async {
    try {
      final id = int.tryParse(referralId.toString()) ?? 0;
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_referral/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 6. SUPPORT TICKETS (TXN_SUPPORT_TICKET)
  // ==========================================

  /// Fetch Support Tickets / Inquiries
  static Future<List<Map<String, dynamic>>> getSupportTickets() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_support_ticket'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create a support ticket
  static Future<bool> createSupportTicket(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_support_ticket'),
        headers: ApiService.headers,
        body: jsonEncode({
          'subject': data['subject'] ?? data['title'],
          'description': data['description'] ?? data['content'] ?? data['message'],
          'priority': data['priority'] ?? 'MEDIUM',
          'status': data['status'] ?? 'OPEN',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Update support ticket status
  static Future<bool> updateTicketStatus(dynamic ticketId, String newStatus) async {
    try {
      final id = int.tryParse(ticketId.toString()) ?? 0;
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_support_ticket/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'status': newStatus,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete a support ticket
  static Future<bool> deleteTicket(dynamic ticketId) async {
    try {
      final id = int.tryParse(ticketId.toString()) ?? 0;
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_support_ticket/$id'),
        headers: ApiService.headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
