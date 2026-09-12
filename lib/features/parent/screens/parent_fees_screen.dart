import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/parent_dashboard_service.dart';

class ParentFeesScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;

  const ParentFeesScreen({super.key, this.selectedChild});

  @override
  State<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends State<ParentFeesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    setState(() => _isLoading = true);
    final list = await ParentDashboardService.getFeeInvoices();
    if (mounted) {
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    }
  }

  void _showPaymentModal(Map<String, dynamic> invoice) {
    String selectedMethod = 'UPI';
    final amount = double.tryParse(invoice['amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment_rounded, color: AppTheme.electricCobalt, size: 24),
                      SizedBox(width: 8),
                      Text('Secure Fee Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),

              Text(invoice['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Invoice: ${invoice['invoice_number'] ?? ''} • Due: ${invoice['due_date'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),

              const SizedBox(height: 16),

              // Total Payable Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.electricCobalt.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textHeading)),
                    Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text('Select Payment Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
              const SizedBox(height: 10),

              _buildPaymentOption(
                title: 'UPI / Instant QR',
                subtitle: 'Google Pay, PhonePe, Paytm',
                icon: Icons.qr_code_scanner_rounded,
                value: 'UPI',
                groupValue: selectedMethod,
                onChanged: (val) => setModalState(() => selectedMethod = val!),
              ),
              _buildPaymentOption(
                title: 'Credit / Debit Card',
                subtitle: 'Visa, Mastercard, RuPay',
                icon: Icons.credit_card_rounded,
                value: 'CARD',
                groupValue: selectedMethod,
                onChanged: (val) => setModalState(() => selectedMethod = val!),
              ),
              _buildPaymentOption(
                title: 'Net Banking',
                subtitle: 'All Major National Banks',
                icon: Icons.account_balance_rounded,
                value: 'NETBANKING',
                groupValue: selectedMethod,
                onChanged: (val) => setModalState(() => selectedMethod = val!),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final invId = int.tryParse(invoice['invoice_id'].toString()) ?? 501;

                  await ParentDashboardService.payFeeInvoice(
                    invoiceId: invId,
                    amount: amount,
                    paymentMode: selectedMethod,
                  );

                  _loadFeeData();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Payment of \$${amount.toStringAsFixed(0)} successful! Receipt generated.'),
                      backgroundColor: AppTheme.successText,
                    ),
                  );
                },
                child: Text('Pay \$${amount.toStringAsFixed(0)} Now', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.electricCobalt : AppTheme.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.electricCobalt : AppTheme.textHeading)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            RadioGroup<String>(
              groupValue: groupValue,
              onChanged: onChanged,
              child: Radio<String>(
                value: value,
                activeColor: AppTheme.electricCobalt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptModal(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppTheme.successText, size: 22),
            SizedBox(width: 8),
            Text('Official Payment Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Invoice: ${invoice['invoice_number'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Paid:'),
                Text('\$${invoice['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.successText)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Mode:'),
                Text(invoice['payment_mode'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Status:'),
                const Text('CONFIRMED / PAID', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successText)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricCobalt, foregroundColor: Colors.white),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download PDF'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading fee receipt PDF...')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _invoices;
    if (_statusFilter != 'All') {
      filtered = filtered.where((inv) => (inv['status'] ?? '').toString().toUpperCase() == _statusFilter.toUpperCase()).toList();
    }

    return RefreshIndicator(
      onRefresh: _loadFeeData,
      color: AppTheme.electricCobalt,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.level2Shadow,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'FINANCE & BILLING',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Fee Payments & Invoices',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pay upcoming coaching dues securely, view itemized statements & download official receipts.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Filter Tabs
            Row(
              children: [
                _buildStatusTab('All', 'All Invoices'),
                const SizedBox(width: 8),
                _buildStatusTab('PENDING', 'Pending'),
                const SizedBox(width: 8),
                _buildStatusTab('PAID', 'Paid / History'),
              ],
            ),

            const SizedBox(height: 18),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.electricCobalt),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.successText),
                    SizedBox(height: 12),
                    Text('No dues pending!', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('All tuition and examination invoices are up to date.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final inv = filtered[index];
                  final isPaid = inv['status'] == 'PAID';
                  final breakdown = (inv['breakdown'] as List?) ?? [];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPaid ? AppTheme.borderSubtle : AppTheme.urgentText.withValues(alpha: 0.4),
                        width: isPaid ? 1 : 1.5,
                      ),
                      boxShadow: AppTheme.level1Shadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv['invoice_number'] ?? '',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid ? AppTheme.successBg : AppTheme.urgentBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                inv['status'] ?? '',
                                style: TextStyle(
                                  color: isPaid ? AppTheme.successText : AppTheme.urgentText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inv['title'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid ? 'Paid on ${inv['paid_date'] ?? ''}' : 'Due Date: ${inv['due_date'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: isPaid ? AppTheme.textMuted : AppTheme.urgentText, fontWeight: isPaid ? FontWeight.normal : FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Itemized Breakdown
                        if (breakdown.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.canvasBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: breakdown.map<Widget>((b) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(b['item_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
                                      Text('\$${b['amount'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                            Text('\$${inv['amount']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                          ],
                        ),
                        const SizedBox(height: 14),

                        if (!isPaid)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.electricCobalt,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text('Pay \$${inv['amount']} Online', style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _showPaymentModal(inv),
                          )
                        else
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 42),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppTheme.borderSubtle),
                            ),
                            icon: const Icon(Icons.receipt_rounded, size: 18, color: AppTheme.textHeading),
                            label: const Text('View Payment Receipt', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
                            onPressed: () => _showReceiptModal(inv),
                          ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(String status, String label) {
    final isSelected = _statusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricCobalt.withValues(alpha: 0.1) : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.electricCobalt : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}
