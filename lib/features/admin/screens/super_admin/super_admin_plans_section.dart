import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/platform_service.dart';

class SuperAdminPlansSection extends StatefulWidget {
  final bool isDark;
  const SuperAdminPlansSection({super.key, required this.isDark});

  @override
  State<SuperAdminPlansSection> createState() => SuperAdminPlansSectionState();
}

class SuperAdminPlansSectionState extends State<SuperAdminPlansSection> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    loadPlans();
  }

  Future<void> loadPlans() async {
    setState(() => _isLoading = true);
    final plans = await PlatformService.getPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  void openAddEditPlanModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final planId = isEdit ? int.tryParse(item['plan_id']?.toString() ?? '0') ?? 0 : 0;
    final codeCtrl = TextEditingController(text: item?['plan_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['plan_name'] ?? '');
    final descCtrl = TextEditingController(text: item?['description'] ?? '');
    final mPriceCtrl = TextEditingController(text: item?['monthly_price']?.toString() ?? '999');
    final yPriceCtrl = TextEditingController(text: item?['yearly_price']?.toString() ?? '9999');
    final maxStudentsCtrl = TextEditingController(text: item?['max_students']?.toString() ?? '150');
    final maxUsersCtrl = TextEditingController(text: item?['max_users']?.toString() ?? '5');
    String status = item?['status'] ?? 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = widget.isDark;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: dark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Subscription Plan' : 'Create Platform Tier Plan',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : AppTheme.textHeading,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Plan Name *',
                        hintText: 'e.g. Coaching Academy Pro',
                        prefixIcon: const Icon(Icons.card_membership_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Plan Code *',
                        hintText: 'e.g. COACHING_PRO',
                        prefixIcon: const Icon(Icons.code_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Features, storage limits, and batch capacity',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: mPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Monthly Price (₹)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: yPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Yearly Price (₹)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: maxStudentsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Students',
                              prefixIcon: const Icon(Icons.groups_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxUsersCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Staff / Users',
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                        DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                      ],
                      onChanged: (val) => setModalState(() => status = val ?? 'ACTIVE'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Plan name is required')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = {
                            'plan_name': nameCtrl.text.trim(),
                            'plan_code': codeCtrl.text.trim().isNotEmpty
                                ? codeCtrl.text.trim().toUpperCase()
                                : nameCtrl.text.trim().replaceAll(' ', '_').toUpperCase(),
                            'description': descCtrl.text.trim(),
                            'monthly_price': double.tryParse(mPriceCtrl.text.trim()) ?? 0.0,
                            'yearly_price': double.tryParse(yPriceCtrl.text.trim()) ?? 0.0,
                            'max_students': int.tryParse(maxStudentsCtrl.text.trim()) ?? 100,
                            'max_users': int.tryParse(maxUsersCtrl.text.trim()) ?? 5,
                            'status': status,
                          };

                          final success = isEdit
                              ? await PlatformService.updatePlan(planId, payload)
                              : await PlatformService.addPlan(payload);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Plan saved successfully' : 'Failed to save plan'),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                            loadPlans();
                          }
                        },
                        child: Text(isEdit ? 'Update Plan' : 'Create Plan', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
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

  void confirmDeletePlan(Map<String, dynamic> plan) {
    final planId = int.tryParse(plan['plan_id']?.toString() ?? '0') ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: Text('Are you sure you want to remove "${plan['plan_name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await PlatformService.deletePlan(planId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Plan deleted' : 'Failed to delete plan'),
                    backgroundColor: ok ? AppTheme.successText : AppTheme.urgentText,
                  ),
                );
                loadPlans();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SaaS Subscription Tiers',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : AppTheme.textHeading,
                  ),
                ),
                Text(
                  'Manage tier pricing, feature bundles, and max student caps',
                  style: TextStyle(fontSize: 13, color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCobalt,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => openAddEditPlanModal(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_plans.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('No Subscription Plans Created Yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Create subscription tier plans for coaching centers and solo tutors.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => openAddEditPlanModal(),
                    child: const Text('Create First Plan'),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: 220,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _plans.length,
            itemBuilder: (context, index) {
              final plan = _plans[index];
              final isActive = (plan['status'] ?? 'ACTIVE') == 'ACTIVE';
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: dark ? AppTheme.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: dark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan['plan_name'] ?? 'Tier Plan',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.successBg : AppTheme.urgentBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            plan['status'] ?? 'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppTheme.successText : AppTheme.urgentText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['plan_code'] ?? '',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.electricCobalt, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan['description'] ?? 'No description provided.',
                      style: TextStyle(fontSize: 12.5, color: dark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${plan['monthly_price'] ?? 0} / mo',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Max ${plan['max_students'] ?? 'Unlimited'} Students',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => openAddEditPlanModal(plan),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.urgentText),
                              onPressed: () => confirmDeletePlan(plan),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
