import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/universal_owner_header.dart';
import '../../services/finance_service.dart';
import '../../services/directory_service.dart';
import '../../services/academic_structure_service.dart';
import '../../services/settings_service.dart';

class FinanceHubScreen extends StatefulWidget {
  final int initialIndex;
  final VoidCallback? onOpenDrawer;
  const FinanceHubScreen({super.key, this.initialIndex = 0, this.onOpenDrawer});

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Data states
  List<Map<String, dynamic>> _feeStructures = [];
  List<Map<String, dynamic>> _batchFeeMappings = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _branches = [];

  // Filter states
  String _invoiceFilter = 'ALL';
  String _expenseFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialIndex >= 0 && widget.initialIndex < 3) ? widget.initialIndex : 0,
    );
    _tabController.addListener(() => setState(() {}));
    _loadAllFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFinanceData() async {
    setState(() => _isLoading = true);
    try {
      final feeStructuresFuture = FinanceService.getFeeStructures();
      final batchMappingsFuture = FinanceService.getBatchFeeMappings();
      final invoicesFuture = FinanceService.getInvoices(status: _invoiceFilter);
      final expensesFuture = FinanceService.getExpenses(status: _expenseFilter);
      final categoriesFuture = FinanceService.getExpenseCategories();
      final studentsFuture = DirectoryService.getStudents().catchError((_) => <Map<String, dynamic>>[]);
      final batchesFuture = AcademicStructureService.getBatches().catchError((_) => <Map<String, dynamic>>[]);
      final branchesFuture = SettingsService.getBranches().catchError((_) => <Map<String, dynamic>>[]);

      final results = await Future.wait([
        feeStructuresFuture,
        batchMappingsFuture,
        invoicesFuture,
        expensesFuture,
        categoriesFuture,
        studentsFuture,
        batchesFuture,
        branchesFuture,
      ]);

      if (mounted) {
        setState(() {
          _feeStructures = results[0];
          _batchFeeMappings = results[1];
          _invoices = results[2];
          _expenses = results[3];
          _expenseCategories = results[4];
          _students = results[5];
          _batches = results[6];
          _branches = results[7];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ===========================================================================
  // FINANCIAL METRICS CALCULATION
  // ===========================================================================
  double get _totalInvoiced {
    return _invoices.fold(0.0, (sum, inv) {
      final amt = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
      return sum + amt;
    });
  }

  double get _totalCollected {
    return _invoices.where((inv) => inv['status'] == 'PAID').fold(0.0, (sum, inv) {
      final amt = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
      return sum + amt;
    });
  }

  double get _totalOutstanding {
    return _invoices.where((inv) => inv['status'] == 'ISSUED' || inv['status'] == 'OVERDUE').fold(0.0, (sum, inv) {
      final amt = double.tryParse(inv['balance_due']?.toString() ?? inv['total_amount']?.toString() ?? '0') ?? 0.0;
      return sum + amt;
    });
  }

  double get _totalExpenses {
    return _expenses.where((exp) => exp['status'] == 'APPROVED').fold(0.0, (sum, exp) {
      final amt = double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0;
      return sum + amt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        title: 'Finance & Accounts',
        subtitle: 'Fee Structures, Invoices, Billing & Center Expenses',
        customActions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.electricCobalt),
            tooltip: 'Refresh Financials',
            onPressed: _loadAllFinanceData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_outlined, size: 20), text: 'Fee Structures & Batches'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 20), text: 'Invoices & Payments'),
            Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 20), text: 'Operating Expenses'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFinancialOverviewHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeeStructuresTab(),
                      _buildInvoicesTab(),
                      _buildExpensesTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ===========================================================================
  // TOP STATS CARDS
  // ===========================================================================
  Widget _buildFinancialOverviewHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(
                title: 'Total Invoiced',
                value: '₹${_totalInvoiced.toStringAsFixed(0)}',
                subtitle: '${_invoices.length} Invoices Issued',
                icon: Icons.receipt_outlined,
                color: AppTheme.electricCobalt,
                width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              ),
              _buildMetricCard(
                title: 'Total Collected',
                value: '₹${_totalCollected.toStringAsFixed(0)}',
                subtitle: 'Paid / Realized Fees',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF059669), // Emerald
                width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              ),
              _buildMetricCard(
                title: 'Outstanding Due',
                value: '₹${_totalOutstanding.toStringAsFixed(0)}',
                subtitle: 'Pending Collections',
                icon: Icons.pending_actions_outlined,
                color: const Color(0xFFD97706), // Amber
                width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              ),
              _buildMetricCard(
                title: 'Operating Expenses',
                value: '₹${_totalExpenses.toStringAsFixed(0)}',
                subtitle: 'Approved Institute Costs',
                icon: Icons.trending_down_outlined,
                color: const Color(0xFFDC2626), // Red
                width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: FEE STRUCTURES & BATCH MAPPINGS
  // ===========================================================================
  Widget _buildFeeStructuresTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Buttons Bar
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Fee Plans & Structures (${_feeStructures.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Assign to Batch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryNavy,
                      side: const BorderSide(color: AppTheme.primaryNavy),
                    ),
                    onPressed: () => _openBatchFeeMappingModal(),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Fee Plan'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
                    onPressed: () => _openFeeStructureModal(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fee Structure Grid/List
          if (_feeStructures.isEmpty)
            _buildEmptyState('No fee structures configured yet', 'Create tuition, annual, or installment fee plans for courses.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _feeStructures.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final fee = _feeStructures[index];
                return _buildFeeStructureCard(fee);
              },
            ),

          const SizedBox(height: 24),
          // Batch Fee Mappings Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Batch Fee Assignments (${_batchFeeMappings.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (_batchFeeMappings.isEmpty)
            _buildEmptyState('No batch fee assignments linked', 'Link fee structures to active batches to enable auto-billing.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batchFeeMappings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final mapping = _batchFeeMappings[index];
                return _buildBatchMappingCard(mapping);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeeStructureCard(Map<String, dynamic> fee) {
    final int feeId = int.tryParse(fee['fee_structure_id']?.toString() ?? '0') ?? 0;
    final String feeName = fee['fee_name'] ?? '';
    final String frequency = fee['frequency'] ?? 'MONTHLY';
    final double amount = double.tryParse(fee['amount']?.toString() ?? '0') ?? 0.0;
    final String status = fee['status'] ?? 'ACTIVE';
    final int batchCount = _batchFeeMappings.where((m) => int.tryParse(m['fee_structure_id']?.toString() ?? '0') == feeId).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.electricCobalt.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_outlined, color: AppTheme.electricCobalt, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(feeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    _buildBadge(frequency, AppTheme.electricCobalt),
                    const SizedBox(width: 6),
                    _buildBadge(status, status == 'ACTIVE' ? const Color(0xFF059669) : Colors.grey),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${amount.toStringAsFixed(2)} • $frequency cycle • Assigned to $batchCount batch(es)',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
            tooltip: 'Edit Plan',
            onPressed: () => _openFeeStructureModal(existingFee: fee),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Delete Plan',
            onPressed: () => _confirmDeleteFeeStructure(feeId, feeName),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchMappingCard(Map<String, dynamic> mapping) {
    final int batchId = int.tryParse(mapping['batch_id']?.toString() ?? '0') ?? 0;
    final int feeId = int.tryParse(mapping['fee_structure_id']?.toString() ?? '0') ?? 0;
    
    // Resolve batch details
    final matchingBatch = _batches.firstWhere(
      (b) => int.tryParse(b['batch_id']?.toString() ?? '0') == batchId,
      orElse: () => <String, dynamic>{},
    );
    final String batchName = (mapping['batch_name'] != null && mapping['batch_name'].toString().isNotEmpty)
        ? mapping['batch_name']
        : (matchingBatch['batch_name'] ?? 'Batch #$batchId');

    // Resolve fee plan details
    final matchingFee = _feeStructures.firstWhere(
      (f) => int.tryParse(f['fee_structure_id']?.toString() ?? '0') == feeId,
      orElse: () => <String, dynamic>{},
    );
    final String feeName = (mapping['fee_name'] != null && mapping['fee_name'].toString().isNotEmpty)
        ? mapping['fee_name']
        : (matchingFee['fee_name'] ?? 'Fee Plan #$feeId');
    final double amount = mapping['amount'] != null
        ? (double.tryParse(mapping['amount'].toString()) ?? 0.0)
        : (double.tryParse(matchingFee['amount']?.toString() ?? '0') ?? 0.0);
    final String effectiveFrom = mapping['effective_from'] ?? 'Current';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.class_outlined, color: AppTheme.primaryNavy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batchName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Linked: $feeName (₹${amount.toStringAsFixed(2)}) • Effective: $effectiveFrom', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.redAccent, size: 18),
            tooltip: 'Unlink Fee from Batch',
            onPressed: () => _confirmUnlinkBatchFee(batchId, feeId, batchName, feeName),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: INVOICES & PAYMENTS LEDGER
  // ===========================================================================
  Widget _buildInvoicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Actions Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter Chips
              Wrap(
                spacing: 8,
                children: ['ALL', 'ISSUED', 'PAID', 'OVERDUE'].map((status) {
                  final isSelected = _invoiceFilter == status;
                  return ChoiceChip(
                    label: Text(status, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppTheme.electricCobalt,
                    backgroundColor: AppTheme.surfaceWhite,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _invoiceFilter = status);
                        _loadAllFinanceData();
                      }
                    },
                  );
                }).toList(),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Issue Invoice'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
                onPressed: () => _openIssueInvoiceModal(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Invoices List
          if (_invoices.isEmpty)
            _buildEmptyState('No invoices found matching filter', 'Issue fee invoices to students or batches to track dues and collections.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final inv = _invoices[index];
                return _buildInvoiceCard(inv);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> inv) {
    final int invoiceId = int.tryParse(inv['invoice_id']?.toString() ?? '0') ?? 0;
    final int studentId = int.tryParse(inv['student_id']?.toString() ?? '0') ?? 0;
    final String invoiceNumber = inv['invoice_number'] ?? '';
    final String studentName = inv['student_name'] ?? '';
    final String studentCode = inv['student_code'] ?? '';
    final double totalAmount = double.tryParse(inv['total_amount']?.toString() ?? '0') ?? 0.0;
    final double balanceDue = double.tryParse(inv['balance_due']?.toString() ?? totalAmount.toString()) ?? totalAmount;
    final String status = inv['status'] ?? 'ISSUED';
    final String dueDate = inv['due_date'] ?? '';

    Color statusColor;
    if (status == 'PAID') {
      statusColor = const Color(0xFF059669);
    } else if (status == 'OVERDUE') {
      statusColor = const Color(0xFFDC2626);
    } else {
      statusColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('$studentName ${studentCode.isNotEmpty ? "($studentCode)" : ""}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              _buildBadge(status, statusColor),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance Due', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  Text(
                    '₹${balanceDue.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: balanceDue > 0 ? Colors.redAccent : Colors.green),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Due Date', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  Text(dueDate, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status != 'PAID') ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.point_of_sale, size: 16),
                  label: const Text('Record Payment / Collect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _openRecordPaymentModal(invoiceId, studentId, studentName, balanceDue),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text('Cancel / Void', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _confirmDeleteInvoice(invoiceId, invoiceNumber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: OPERATING EXPENSES & APPROVALS
  // ===========================================================================
  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Actions Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: ['ALL', 'APPROVED', 'DRAFT', 'REJECTED'].map((status) {
                  final isSelected = _expenseFilter == status;
                  return ChoiceChip(
                    label: Text(status, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppTheme.textPrimary)),
                    selected: isSelected,
                    selectedColor: AppTheme.electricCobalt,
                    backgroundColor: AppTheme.surfaceWhite,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _expenseFilter = status);
                        _loadAllFinanceData();
                      }
                    },
                  );
                }).toList(),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Expense'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
                onPressed: () => _openAddExpenseModal(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expenses List
          if (_expenses.isEmpty)
            _buildEmptyState('No operating expenses logged', 'Record utilities, rent, faculty compensation, and institute upkeep expenses.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                return _buildExpenseCard(exp);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> exp) {
    final int expenseId = int.tryParse(exp['expense_id']?.toString() ?? '0') ?? 0;
    final String categoryName = exp['category_name'] ?? '';
    final double amount = double.tryParse(exp['amount']?.toString() ?? '0') ?? 0.0;
    final String description = exp['description'] ?? '';
    final String expenseDate = exp['expense_date'] ?? '';
    final String status = exp['status'] ?? 'DRAFT';
    final bool isRecurring = exp['recurring'] == 1 || exp['recurring'] == true;

    Color statusColor;
    if (status == 'APPROVED') {
      statusColor = const Color(0xFF059669);
    } else if (status == 'REJECTED') {
      statusColor = const Color(0xFFDC2626);
    } else {
      statusColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Date: $expenseDate ${isRecurring ? "• (Recurring)" : ""}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFDC2626))),
                  const SizedBox(width: 8),
                  _buildBadge(status, statusColor),
                ],
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'DRAFT') ...[
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
                  label: const Text('Approve', style: TextStyle(color: Color(0xFF059669))),
                  onPressed: () async {
                    await FinanceService.updateExpenseStatus(expenseId, 'APPROVED');
                    _loadAllFinanceData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense approved.'), backgroundColor: AppTheme.successText),
                      );
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.orange, size: 18),
                  label: const Text('Reject', style: TextStyle(color: Colors.orange)),
                  onPressed: () async {
                    await FinanceService.updateExpenseStatus(expenseId, 'REJECTED');
                    _loadAllFinanceData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense rejected.'), backgroundColor: AppTheme.urgentText),
                      );
                    }
                  },
                ),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                tooltip: 'Delete Expense Voucher',
                onPressed: () => _confirmDeleteExpense(expenseId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALS & DIALOGS
  // ===========================================================================

  // 1. Fee Structure Modal
  void _openFeeStructureModal({Map<String, dynamic>? existingFee}) {
    final isEditing = existingFee != null;
    final nameController = TextEditingController(text: existingFee?['fee_name'] ?? '');
    final amountController = TextEditingController(text: existingFee?['amount']?.toString() ?? '');
    String frequency = existingFee?['frequency'] ?? 'MONTHLY';
    String status = existingFee?['status'] ?? 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEditing ? 'Edit Fee Structure' : 'Create Fee Structure Plan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Fee Head / Plan Name', hintText: 'e.g. Monthly Tuition Fee / Annual Lab Kit', prefixIcon: Icon(Icons.title)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: '3500.00', prefixIcon: Icon(Icons.currency_rupee)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: const InputDecoration(labelText: 'Billing Frequency', prefixIcon: Icon(Icons.repeat)),
                      items: ['MONTHLY', 'QUARTERLY', 'ANNUAL', 'COURSE', 'INSTALLMENT', 'CUSTOM'].map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => frequency = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Plan Status', prefixIcon: Icon(Icons.toggle_on)),
                      items: ['ACTIVE', 'INACTIVE'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter fee name and amount')));
                          return;
                        }
                        final data = {
                          'fee_name': nameController.text.trim(),
                          'amount': double.tryParse(amountController.text.trim()) ?? 0,
                          'frequency': frequency,
                          'status': status,
                        };

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        if (isEditing) {
                          final feeId = int.parse(existingFee['fee_structure_id'].toString());
                          await FinanceService.updateFeeStructure(feeId, data);
                        } else {
                          await FinanceService.createFeeStructure(data);
                        }
                        _loadAllFinanceData();
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Fee plan updated successfully!' : 'Fee plan created successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Update Plan' : 'Save Fee Plan', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Map Fee to Batch Modal
  void _openBatchFeeMappingModal() {
    int? selectedBatchId = _batches.isNotEmpty ? int.tryParse(_batches.first['batch_id']?.toString() ?? '0') : null;
    int? selectedFeeId = _feeStructures.isNotEmpty ? int.tryParse(_feeStructures.first['fee_structure_id']?.toString() ?? '0') : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Assign Fee Plan to Batch', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: selectedBatchId,
                      decoration: const InputDecoration(labelText: 'Select Batch', prefixIcon: Icon(Icons.class_outlined)),
                      items: _batches.map((b) {
                        final id = int.tryParse(b['batch_id']?.toString() ?? '0') ?? 0;
                        final name = b['batch_name'] ?? '';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedBatchId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedFeeId,
                      decoration: const InputDecoration(labelText: 'Select Fee Plan', prefixIcon: Icon(Icons.payments_outlined)),
                      items: _feeStructures.map((f) {
                        final id = int.tryParse(f['fee_structure_id']?.toString() ?? '0') ?? 0;
                        final name = f['fee_name'] ?? '';
                        final amt = f['amount'] ?? '0';
                        return DropdownMenuItem(value: id, child: Text('$name (₹$amt)'));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedFeeId = val),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (selectedBatchId == null || selectedFeeId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both a batch and fee plan')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await FinanceService.mapFeeToBatch(batchId: selectedBatchId!, feeStructureId: selectedFeeId!);
                        _loadAllFinanceData();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Fee plan linked to batch successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: const Text('Link Fee to Batch', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. Issue Invoice Modal
  void _openIssueInvoiceModal() {
    int? selectedStudentId = _students.isNotEmpty ? int.tryParse(_students.first['student_id']?.toString() ?? '0') : null;
    int? selectedFeeId = _feeStructures.isNotEmpty ? int.tryParse(_feeStructures.first['fee_structure_id']?.toString() ?? '0') : null;
    final amountController = TextEditingController(
      text: _feeStructures.isNotEmpty ? (_feeStructures.first['amount']?.toString() ?? '0') : '0',
    );
    final discountController = TextEditingController(text: '0');
    final dueDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 15)).toIso8601String().substring(0, 10));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Issue Student Fee Invoice', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: selectedStudentId,
                      decoration: const InputDecoration(labelText: 'Select Student', prefixIcon: Icon(Icons.person_outline)),
                      items: _students.map((s) {
                        final id = int.tryParse(s['student_id']?.toString() ?? '0') ?? 0;
                        final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                        final code = s['student_code'] ?? '';
                        return DropdownMenuItem(value: id, child: Text('$name ($code)'));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedStudentId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedFeeId,
                      decoration: const InputDecoration(labelText: 'Select Fee Plan (Optional)', prefixIcon: Icon(Icons.payments_outlined)),
                      items: _feeStructures.map((f) {
                        final id = int.tryParse(f['fee_structure_id']?.toString() ?? '0') ?? 0;
                        final name = f['fee_name'] ?? '';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedFeeId = val;
                          final match = _feeStructures.firstWhere((element) => int.tryParse(element['fee_structure_id']?.toString() ?? '0') == val, orElse: () => {});
                          if (match.isNotEmpty) {
                            amountController.text = match['amount']?.toString() ?? '0';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Invoice Subtotal (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Scholarship / Discount (₹)', prefixIcon: Icon(Icons.discount_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dueDateController,
                      decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.event_outlined)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (selectedStudentId == null || amountController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select student and enter amount')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await FinanceService.createInvoice({
                          'student_id': selectedStudentId,
                          'fee_structure_id': selectedFeeId,
                          'amount': double.tryParse(amountController.text.trim()) ?? 0,
                          'discount': double.tryParse(discountController.text.trim()) ?? 0,
                          'due_date': dueDateController.text.trim(),
                        });
                        _loadAllFinanceData();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Invoice issued to student successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: const Text('Generate Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. Record Offline Payment Modal
  void _openRecordPaymentModal(int invoiceId, int studentId, String studentName, double defaultAmount) {
    final amountController = TextEditingController(text: defaultAmount.toStringAsFixed(2));
    final refController = TextEditingController(text: 'OFF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    String paymentMode = 'CASH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Record Payment & Issue Receipt', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Student: $studentName • Invoice #$invoiceId', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount Received (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMode,
                      decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.payment)),
                      items: ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'POS_CARD'].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => paymentMode = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(labelText: 'Reference / Transaction No.', prefixIcon: Icon(Icons.receipt)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified),
                      label: const Text('Verify & Issue Receipt (REC-2026-XXXX)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid payment amount')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await FinanceService.recordOfflinePayment(
                          invoiceId: invoiceId,
                          studentId: studentId,
                          amount: amt,
                          paymentMethod: paymentMode,
                          referenceNo: refController.text.trim(),
                        );
                        _loadAllFinanceData();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF059669),
                              content: Text('Payment verified and official receipt generated successfully!'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 5. Add Expense Modal
  void _openAddExpenseModal() {
    int? selectedCategoryId = _expenseCategories.isNotEmpty ? int.tryParse(_expenseCategories.first['expense_category_id']?.toString() ?? '1') : 1;
    int? selectedBranchId = _branches.isNotEmpty ? int.tryParse(_branches.first['branch_id']?.toString() ?? '0') : null;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    bool isRecurring = false;
    String status = 'APPROVED';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Log Operating Expense Voucher', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Expense Category *', prefixIcon: Icon(Icons.category_outlined)),
                      items: _expenseCategories.map((c) {
                        final id = int.tryParse(c['expense_category_id']?.toString() ?? '0') ?? 0;
                        final name = c['category_name'] ?? '';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedCategoryId = val),
                    ),
                    if (_branches.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedBranchId,
                        decoration: const InputDecoration(labelText: 'Campus Branch', prefixIcon: Icon(Icons.location_city_outlined)),
                        items: _branches.map((b) {
                          final id = int.tryParse(b['branch_id']?.toString() ?? '0') ?? 0;
                          final name = b['branch_name'] ?? '';
                          final code = b['branch_code'] ?? '';
                          return DropdownMenuItem(value: id, child: Text('$name ($code)'));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedBranchId = val),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Expense Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description / Notes', hintText: 'e.g. Campus electricity bill for Aug', prefixIcon: Icon(Icons.notes)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Expense Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Recurring Expense (Monthly)', style: TextStyle(fontSize: 14)),
                      value: isRecurring,
                      onChanged: (val) => setModalState(() => isRecurring = val),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final expAmount = double.tryParse(amountController.text.trim());
                        if (expAmount == null || expAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid expense amount')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await FinanceService.createExpense({
                          'expense_category_id': selectedCategoryId ?? 1,
                          'branch_id': selectedBranchId,
                          'amount': expAmount,
                          'description': descController.text.trim(),
                          'expense_date': dateController.text.trim(),
                          'recurring': isRecurring,
                          'status': status,
                        });
                        _loadAllFinanceData();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Operating expense logged successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: const Text('Log Expense Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Delete Confirmations
  void _confirmDeleteFeeStructure(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fee Structure?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FinanceService.deleteFeeStructure(id);
              _loadAllFinanceData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fee plan deleted.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmUnlinkBatchFee(int batchId, int feeId, String batchName, String feeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Batch Fee?'),
        content: Text('Remove "$feeName" mapping from "$batchName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FinanceService.unmapFeeFromBatch(batchId: batchId, feeStructureId: feeId);
              _loadAllFinanceData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fee plan unlinked from batch.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteInvoice(int id, String invNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void / Delete Invoice?'),
        content: Text('Are you sure you want to delete invoice "$invNum"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FinanceService.deleteInvoice(id);
              _loadAllFinanceData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice voided.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense Voucher?'),
        content: const Text('Are you sure you want to delete this operating expense entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await FinanceService.deleteExpense(id);
              _loadAllFinanceData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense voucher deleted.'), backgroundColor: AppTheme.successText),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
