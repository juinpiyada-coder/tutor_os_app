import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class FinanceService {
  // ===========================================================================
  // 1. FEE STRUCTURES (MASTER_FEE_STRUCTURE)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getFeeStructures() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_fee_structure'),
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

  static Future<bool> createFeeStructure(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/master_fee_structure'),
        headers: ApiService.headers,
        body: jsonEncode({
          'institute_id': ApiService.safeInstituteId,
          'fee_name': data['fee_name'],
          'frequency': data['frequency'] ?? 'MONTHLY',
          'amount': data['amount'],
          'status': data['status'] ?? 'ACTIVE',
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateFeeStructure(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/master_fee_structure/$id'),
        headers: ApiService.headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteFeeStructure(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/master_fee_structure/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 2. BATCH FEE MAPPINGS (MAP_BATCH_FEE_STRUCTURE)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getBatchFeeMappings({int? batchId, int? feeStructureId}) async {
    try {
      String query = '';
      if (batchId != null) query += '?batch_id=$batchId';
      if (feeStructureId != null) query += '${query.isEmpty ? '?' : '&'}fee_structure_id=$feeStructureId';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/map_batch_fee_structure$query'),
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

  static Future<bool> mapFeeToBatch({
    required int batchId,
    required int feeStructureId,
    String? effectiveFrom,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/map_batch_fee_structure'),
        headers: ApiService.headers,
        body: jsonEncode({
          'batch_id': batchId,
          'fee_structure_id': feeStructureId,
          'effective_from': effectiveFrom ?? DateTime.now().toIso8601String().substring(0, 10),
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unmapFeeFromBatch({required int batchId, required int feeStructureId}) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/map_batch_fee_structure/$batchId?fee_structure_id=$feeStructureId'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 3. STUDENT FEE INVOICES (TXN_FEE_INVOICE)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getInvoices({int? studentId, String? status}) async {
    try {
      String query = '';
      if (studentId != null) query += '?student_id=$studentId';
      if (status != null && status != 'ALL') query += '${query.isEmpty ? '?' : '&'}status=$status';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_fee_invoice$query'),
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

  static Future<bool> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_fee_invoice'),
        headers: ApiService.headers,
        body: jsonEncode({
          'student_id': data['student_id'],
          'subtotal': data['amount'],
          'discount_amount': data['discount'] ?? 0,
          'tax_amount': data['tax'] ?? 0,
          'due_date': data['due_date'],
          'fee_structure_id': data['fee_structure_id'],
          'status': 'ISSUED',
          'created_by_user_id': ApiService.currentUserId ?? 1,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateInvoiceStatus(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_fee_invoice/$id'),
        headers: ApiService.headers,
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteInvoice(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_fee_invoice/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 4. PAYMENTS & RECEIPTS (TXN_PAYMENT & TXN_RECEIPT)
  // ===========================================================================
  static Future<bool> recordOfflinePayment({
    required int invoiceId,
    required int studentId,
    required double amount,
    String paymentMethod = 'CASH',
    String? referenceNo,
  }) async {
    try {
      // 1. Record payment
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_payment'),
        headers: ApiService.headers,
        body: jsonEncode({
          'student_id': studentId,
          'payment_method_id': 1,
          'payment_ref_no': referenceNo ?? 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
          'payment_date': DateTime.now().toIso8601String(),
          'amount': amount,
          'status': 'VERIFIED',
          'notes': 'Offline Cash / Direct payment received at campus',
          'recorded_by_user_id': ApiService.currentUserId ?? 1,
          'verified_by_user_id': ApiService.currentUserId ?? 1,
        }),
      );

      // 2. Mark invoice as paid/partial
      await updateInvoiceStatus(invoiceId, 'PAID');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // 5. OPERATING EXPENSES (TXN_EXPENSE & MASTER_EXPENSE_CATEGORY)
  // ===========================================================================
  static Future<List<Map<String, dynamic>>> getExpenses({int? categoryId, String? status}) async {
    try {
      String query = '';
      if (categoryId != null) query += '?expense_category_id=$categoryId';
      if (status != null && status != 'ALL') query += '${query.isEmpty ? '?' : '&'}status=$status';

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/txn_expense$query'),
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

  static Future<bool> createExpense(Map<String, dynamic> data) async {
    try {
      final payload = <String, dynamic>{
        'institute_id': ApiService.safeInstituteId,
        'expense_category_id': data['expense_category_id'],
        'amount': data['amount'],
        'description': data['description'] ?? '',
        'expense_date': data['expense_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
        'recurring': data['recurring'] == true ? 1 : 0,
        'status': data['status'] ?? 'APPROVED',
        'created_by_user_id': ApiService.currentUserId ?? 1,
      };
      if (data['branch_id'] != null) {
        payload['branch_id'] = data['branch_id'];
      }
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/txn_expense'),
        headers: ApiService.headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateExpenseStatus(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/txn_expense/$id'),
        headers: ApiService.headers,
        body: jsonEncode({
          'status': status,
          'approved_by_user_id': ApiService.currentUserId ?? 1,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/txn_expense/$id'),
        headers: ApiService.headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/master_expense_category'),
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
}
