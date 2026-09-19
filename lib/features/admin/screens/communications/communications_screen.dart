import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/universal_owner_header.dart';
import '../../services/communications_service.dart';
import '../../services/directory_service.dart';

class CommunicationsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CommunicationsScreen({super.key, this.onOpenDrawer});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _broadcasts = [];
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _referrals = [];
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final broadcasts = await CommunicationsService.getBroadcasts();
      final templates = await CommunicationsService.getTemplates();
      final campaigns = await CommunicationsService.getCampaigns();
      final referrals = await CommunicationsService.getReferrals();
      final tickets = await CommunicationsService.getSupportTickets();
      final students = await DirectoryService.getStudents().catchError((_) => <Map<String, dynamic>>[]);
      if (mounted) {
        setState(() {
          _broadcasts = broadcasts;
          _templates = templates;
          _campaigns = campaigns;
          _referrals = referrals;
          _tickets = tickets;
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 1. BROADCASTS MODAL
  // ==========================================
  void _openBroadcastDialog({Map<String, dynamic>? existingBroadcast}) {
    final isEditing = existingBroadcast != null;
    final broadcastId = existingBroadcast?['broadcast_id'] ?? existingBroadcast?['message_id'];
    final titleController = TextEditingController(text: existingBroadcast?['title'] ?? existingBroadcast?['subject'] ?? '');
    final contentController = TextEditingController(text: existingBroadcast?['content'] ?? existingBroadcast?['body'] ?? '');
    String target = existingBroadcast?['target_audience'] ?? existingBroadcast?['target'] ?? 'ALL';
    String channel = (existingBroadcast?['channel'] ?? 'PUSH').toString().toUpperCase();
    if (!['PUSH', 'WHATSAPP', 'SMS', 'EMAIL'].contains(channel)) channel = 'PUSH';
    int? selectedTemplateId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Broadcast Notice' : 'Compose Multi-Channel Broadcast',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Template auto-fill selector
                    if (_templates.isNotEmpty && !isEditing) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedTemplateId,
                        decoration: InputDecoration(
                          labelText: 'Use Message Template (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.note_alt_outlined, color: AppTheme.electricCobalt),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('— None / Write manually —')),
                          ..._templates.map((t) {
                            final id = int.tryParse(t['template_id']?.toString() ?? '0') ?? 0;
                            final name = t['template_name'] ?? '';
                            final ch = t['channel'] ?? '';
                            return DropdownMenuItem<int>(value: id, child: Text('$name ($ch)'));
                          }),
                        ],
                        onChanged: (val) {
                          setModalState(() {
                            selectedTemplateId = val;
                            if (val != null) {
                              final tpl = _templates.firstWhere(
                                (t) => int.tryParse(t['template_id']?.toString() ?? '0') == val,
                                orElse: () => {},
                              );
                              if (tpl.isNotEmpty) {
                                titleController.text = tpl['subject_template'] ?? titleController.text;
                                contentController.text = tpl['body_template'] ?? contentController.text;
                                channel = (tpl['channel'] ?? channel).toString().toUpperCase();
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: ['PUSH', 'WHATSAPP', 'SMS', 'EMAIL'].contains(channel) ? channel : 'PUSH',
                            decoration: InputDecoration(
                              labelText: 'Delivery Channel *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.sensors, color: AppTheme.electricCobalt),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PUSH', child: Text('In-App Push')),
                              DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
                              DropdownMenuItem(value: 'SMS', child: Text('SMS Message')),
                              DropdownMenuItem(value: 'EMAIL', child: Text('Email Digest')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => channel = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: target.contains('STUDENT') ? 'STUDENT' : (target.contains('STAFF') ? 'STAFF' : 'ALL'),
                            decoration: InputDecoration(
                              labelText: 'Target Audience *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('Everyone')),
                              DropdownMenuItem(value: 'STUDENT', child: Text('Students Only')),
                              DropdownMenuItem(value: 'STAFF', child: Text('Faculty Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => target = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Notice Headline / Subject *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.campaign_outlined, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message Body *',
                        hintText: 'Type your message or use templates...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.send),
                        label: Text(isEditing ? 'Update Broadcast' : 'Dispatch Broadcast Message'),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          bool success = false;
                          if (isEditing) {
                            success = await CommunicationsService.updateBroadcast(broadcastId, {
                              'title': titleController.text.trim(),
                              'content': contentController.text.trim(),
                              'channel': channel,
                              'target': target,
                            });
                          } else {
                            success = await CommunicationsService.sendBroadcast({
                              'title': titleController.text.trim(),
                              'content': contentController.text.trim(),
                              'channel': channel,
                              'target': target,
                              'template_id': selectedTemplateId,
                            });
                          }
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? (success ? 'Broadcast updated successfully!' : 'Failed to update broadcast.')
                                    : (success ? 'Broadcast dispatched successfully!' : 'Failed to dispatch broadcast.')),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        },
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

  // ==========================================
  // 2. TEMPLATE MODAL (MASTER_MESSAGE_TEMPLATE)
  // ==========================================
  void _openTemplateDialog({Map<String, dynamic>? existingTemplate}) {
    final isEditing = existingTemplate != null;
    final templateId = existingTemplate?['template_id'] ?? existingTemplate?['id'];
    final nameController = TextEditingController(text: existingTemplate?['template_name'] ?? '');
    final codeController = TextEditingController(
      text: existingTemplate?['template_code'] ?? 'TMPL_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final subjectController = TextEditingController(text: existingTemplate?['subject_template'] ?? '');
    final bodyController = TextEditingController(text: existingTemplate?['body_template'] ?? '');
    String channel = (existingTemplate?['channel'] ?? 'WHATSAPP').toString().toUpperCase();
    if (!['WHATSAPP', 'SMS', 'PUSH', 'EMAIL'].contains(channel)) {
      channel = 'WHATSAPP';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Message Template' : 'Create Reusable Message Template',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Template Name *',
                        hintText: 'e.g. Absent Alert, Fee Due Notice',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.note_alt_outlined, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: channel,
                            decoration: InputDecoration(
                              labelText: 'Channel *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'WHATSAPP', child: Text('WhatsApp')),
                              DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                              DropdownMenuItem(value: 'PUSH', child: Text('Push')),
                              DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => channel = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: InputDecoration(
                              labelText: 'Template Code *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject Template',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message Body Template *',
                        hintText: 'Use placeholders like {{student_name}}, {{amount}}, {{due_date}}...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save),
                        label: Text(isEditing ? 'Update Message Template' : 'Save Message Template'),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter template name and body.')));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final payload = {
                            'template_name': nameController.text.trim(),
                            'template_code': codeController.text.trim(),
                            'channel': channel,
                            'subject_template': subjectController.text.trim(),
                            'body_template': bodyController.text.trim(),
                          };
                          bool success = false;
                          if (isEditing) {
                            success = await CommunicationsService.updateTemplate(templateId, payload);
                          } else {
                            success = await CommunicationsService.createTemplate(payload);
                          }
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? (success ? 'Message template updated successfully!' : 'Failed to update template.')
                                    : (success ? 'Message template saved successfully!' : 'Failed to save template.')),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        },
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

  // ==========================================
  // 3. MARKETING CAMPAIGN MODAL
  // ==========================================
  void _openCampaignDialog({Map<String, dynamic>? existingCampaign}) {
    final isEditing = existingCampaign != null;
    final campaignId = existingCampaign?['campaign_id'] ?? existingCampaign?['id'];
    final nameController = TextEditingController(text: existingCampaign?['campaign_name'] ?? '');
    final codeController = TextEditingController(text: existingCampaign?['campaign_code'] ?? 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final budgetController = TextEditingController(text: existingCampaign?['budget']?.toString() ?? '25000');
    final startController = TextEditingController(text: existingCampaign?['start_date'] ?? DateTime.now().toIso8601String().split('T')[0]);
    final endController = TextEditingController(text: existingCampaign?['end_date'] ?? DateTime.now().add(const Duration(days: 60)).toIso8601String().split('T')[0]);
    String status = existingCampaign?['status'] ?? 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Marketing Campaign' : 'Create Marketing Campaign',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Campaign Name *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.ads_click, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: InputDecoration(
                              labelText: 'Campaign Code *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: budgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Budget (₹) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            decoration: InputDecoration(
                              labelText: 'Start Date (YYYY-MM-DD)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            decoration: InputDecoration(
                              labelText: 'End Date (YYYY-MM-DD)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: ['PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED'].contains(status.toUpperCase()) ? status.toUpperCase() : 'ACTIVE',
                      decoration: InputDecoration(
                        labelText: 'Campaign Status *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PLANNED', child: Text('Planned / Draft')),
                        DropdownMenuItem(value: 'ACTIVE', child: Text('Active / Running')),
                        DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                        DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(isEditing ? 'Update Campaign' : 'Save & Launch Campaign'),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter campaign name.')));
                            return;
                          }
                          final campaignBudget = double.tryParse(budgetController.text.trim());
                          if (campaignBudget == null || campaignBudget <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid campaign budget.')));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final payload = {
                            'campaign_name': nameController.text.trim(),
                            'campaign_code': codeController.text.trim(),
                            'budget': campaignBudget,
                            'start_date': startController.text.trim(),
                            'end_date': endController.text.trim(),
                            'status': status,
                          };
                          bool success = false;
                          if (isEditing) {
                            success = await CommunicationsService.updateCampaign(campaignId, payload);
                          } else {
                            success = await CommunicationsService.createCampaign(payload);
                          }
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? (success ? 'Campaign updated successfully!' : 'Failed to update campaign.')
                                    : (success ? 'Campaign launched successfully!' : 'Failed to launch campaign.')),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        },
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

  // ==========================================
  // 4. REFERRAL MODAL
  // ==========================================
  void _openReferralDialog() {
    final leadNameController = TextEditingController();
    final leadPhoneController = TextEditingController();
    final notesController = TextEditingController();
    int? referrerStudentId = _students.isNotEmpty
        ? int.tryParse(_students.first['student_id']?.toString() ?? '0')
        : null;
    int? campaignId = _campaigns.isNotEmpty
        ? int.tryParse(_campaigns.first['campaign_id']?.toString() ?? '0')
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Record Student / Parent Referral',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_students.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: referrerStudentId,
                        decoration: InputDecoration(
                          labelText: 'Referring Student (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.electricCobalt),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('— Direct / Walk-in Referral —')),
                          ..._students.map((s) {
                            final id = int.tryParse(s['student_id']?.toString() ?? '0') ?? 0;
                            final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                            final code = s['student_code'] ?? '';
                            return DropdownMenuItem<int>(value: id, child: Text('$name ($code)'));
                          }),
                        ],
                        onChanged: (val) => setModalState(() => referrerStudentId = val),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_campaigns.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: campaignId,
                        decoration: InputDecoration(
                          labelText: 'Attribute to Campaign (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.ads_click, color: AppTheme.electricCobalt),
                        ),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text('— No Campaign —')),
                          ..._campaigns.map((c) {
                            final id = int.tryParse(c['campaign_id']?.toString() ?? '0') ?? 0;
                            final name = c['campaign_name'] ?? '';
                            return DropdownMenuItem<int>(value: id, child: Text(name));
                          }),
                        ],
                        onChanged: (val) => setModalState(() => campaignId = val),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: leadNameController,
                      decoration: InputDecoration(
                        labelText: 'Referred Prospect Name *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_add, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: leadPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Phone Number *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Program Interest & Notes',
                        hintText: 'e.g. Grade 11 IIT-JEE weekend batch',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('Save Referral Record'),
                        onPressed: () async {
                          final referredName = leadNameController.text.trim();
                          final referredPhone = leadPhoneController.text.trim();
                          if (referredName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter referred person name.')));
                            return;
                          }
                          if (referredPhone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter contact phone number.')));
                            return;
                          }
                          final phoneErr = validateIndianPhone(referredPhone, required: true);
                          if (phoneErr != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneErr)));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final success = await CommunicationsService.createReferral({
                            'referrer_student_id': referrerStudentId,
                            'campaign_id': campaignId,
                            'lead_name': referredName,
                            'lead_phone': referredPhone,
                            'notes': notesController.text.trim(),
                            'status': 'PENDING',
                          });
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Referral recorded successfully!' : 'Failed to record referral.'),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        },
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

  // ==========================================
  // 5. SUPPORT TICKET MODAL
  // ==========================================
  void _openTicketDialog({Map<String, dynamic>? existingTicket}) {
    final isEditing = existingTicket != null;
    final ticketId = existingTicket?['ticket_id'] ?? existingTicket?['id'];
    final subjectController = TextEditingController(text: existingTicket?['subject'] ?? '');
    final descriptionController = TextEditingController(text: existingTicket?['description'] ?? '');
    String priority = (existingTicket?['priority'] ?? 'MEDIUM').toString().toUpperCase();
    String status = (existingTicket?['status'] ?? 'OPEN').toString().toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Update Support Ticket #$ticketId' : 'Create New Support Ticket',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'Inquiry / Issue Subject *',
                        hintText: 'e.g. App login issue, Fees receipt mismatch',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.help_outline, color: AppTheme.electricCobalt),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'].contains(priority) ? priority : 'MEDIUM',
                            decoration: InputDecoration(
                              labelText: 'Priority *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'LOW', child: Text('Low Priority')),
                              DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                              DropdownMenuItem(value: 'HIGH', child: Text('High Priority')),
                              DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: ['OPEN', 'IN_PROGRESS', 'WAITING', 'RESOLVED', 'CLOSED'].contains(status) ? status : 'OPEN',
                              decoration: InputDecoration(
                                labelText: 'Status *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                                DropdownMenuItem(value: 'WAITING', child: Text('Waiting')),
                                DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                                DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => status = val);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Ticket Details / Message *',
                        hintText: 'Describe the issue or user inquiry in detail...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: Text(isEditing ? 'Update Ticket' : 'Submit Support Ticket'),
                        onPressed: () async {
                          if (subjectController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter subject and description.')));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          bool success = false;
                          if (isEditing) {
                            success = await CommunicationsService.updateTicketStatus(ticketId, status);
                          } else {
                            success = await CommunicationsService.createSupportTicket({
                              'subject': subjectController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'priority': priority,
                              'status': 'OPEN',
                            });
                          }
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? (success ? 'Ticket updated successfully!' : 'Failed to update ticket.')
                                    : (success ? 'Support ticket created successfully!' : 'Failed to create ticket.')),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        title: 'Communications Hub',
        subtitle: 'Broadcast Alerts, Message Templates & Marketing Campaigns',
        customActions: [
          IconButton(
            tooltip: 'Reload Messages',
            icon: const Icon(Icons.refresh, color: AppTheme.electricCobalt),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Broadcasts'),
            Tab(icon: Icon(Icons.dynamic_feed), text: 'Templates'),
            Tab(icon: Icon(Icons.ads_click), text: 'Campaigns'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Referrals'),
            Tab(icon: Icon(Icons.support_agent), text: 'Tickets'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        icon: Icon(_getFabIcon()),
        label: Text(_getFabLabel()),
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _openBroadcastDialog();
              break;
            case 1:
              _openTemplateDialog();
              break;
            case 2:
              _openCampaignDialog();
              break;
            case 3:
              _openReferralDialog();
              break;
            case 4:
              _openTicketDialog();
              break;
            default:
              _openBroadcastDialog();
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBroadcastsTab(),
                _buildTemplatesTab(),
                _buildCampaignsTab(),
                _buildReferralsTab(),
                _buildTicketsTab(),
              ],
            ),
    );
  }

  IconData _getFabIcon() {
    switch (_tabController.index) {
      case 1:
        return Icons.note_add;
      case 2:
        return Icons.add_circle;
      case 3:
        return Icons.share;
      case 4:
        return Icons.support_agent;
      default:
        return Icons.add_comment;
    }
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 1:
        return 'New Template';
      case 2:
        return 'New Campaign';
      case 3:
        return 'Add Referral';
      case 4:
        return 'New Ticket';
      default:
        return 'New Broadcast';
    }
  }

  // ==========================================
  // TAB 1: BROADCASTS (TXN_MESSAGE)
  // ==========================================
  Widget _buildBroadcastsTab() {
    if (_broadcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Broadcasts Sent Yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _broadcasts.length,
      itemBuilder: (context, index) {
        final b = _broadcasts[index];
        final channel = (b['channel'] ?? 'PUSH').toString().toUpperCase();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b['title'] ?? b['subject'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(channel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _openBroadcastDialog(existingBroadcast: b);
                        } else if (val == 'delete') {
                          final messenger = ScaffoldMessenger.of(context);
                          final id = b['broadcast_id'] ?? b['message_id'] ?? index;
                          final success = await CommunicationsService.deleteBroadcast(id);
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Broadcast deleted.' : 'Failed to delete broadcast.'),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Notice')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Notice', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  b['content'] ?? b['body'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textDark),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Chip(
                      label: Text(b['target_audience'] ?? b['target'] ?? 'ALL', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const Spacer(),
                    Text(
                      b['sent_at'] ?? b['created_at'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: TEMPLATES (MASTER_MESSAGE_TEMPLATE)
  // ==========================================
  Widget _buildTemplatesTab() {
    if (_templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dynamic_feed_outlined, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Message Templates Found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final t = _templates[index];
        final channel = (t['channel'] ?? '').toString().toUpperCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['template_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(t['template_code'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(channel, style: TextStyle(color: Colors.purple.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _openTemplateDialog(existingTemplate: t);
                        } else if (val == 'delete') {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Delete Message Template?'),
                              content: Text('Are you sure you want to delete template "${t['template_name']}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final templateId = t['template_id'] ?? t['id'];
                            final success = await CommunicationsService.deleteTemplate(templateId);
                            _loadData();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Template deleted successfully.' : 'Failed to delete template.'),
                                  backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: AppTheme.electricCobalt), SizedBox(width: 8), Text('Edit Template')]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete Template', style: TextStyle(color: Colors.red))]),
                        ),
                      ],
                    ),
                  ],
                ),
                if (t['subject_template'] != null && t['subject_template'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Subject: ${t['subject_template']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryNavy)),
                ],
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(t['body_template'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: MARKETING CAMPAIGNS (MASTER_CAMPAIGN)
  // ==========================================
  Widget _buildCampaignsTab() {
    if (_campaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ads_click, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Marketing Campaigns Found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final c = _campaigns[index];
        final status = (c['status'] ?? 'ACTIVE').toString().toUpperCase();
        Color statusColor = status == 'ACTIVE' ? Colors.green : (status == 'COMPLETED' ? Colors.blue : Colors.orange);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['campaign_name'] ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(c['campaign_code'] ?? '', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.electricCobalt, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _openCampaignDialog(existingCampaign: c);
                        } else if (val == 'delete') {
                          final messenger = ScaffoldMessenger.of(context);
                          final id = c['campaign_id'] ?? c['id'] ?? index;
                          final success = await CommunicationsService.deleteCampaign(id);
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Campaign deleted.' : 'Failed to delete campaign.'),
                                backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Campaign')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Campaign', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget Allocated', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('₹ ${c['budget'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Duration', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('${c['start_date'] ?? '—'} → ${c['end_date'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: REFERRALS (TXN_REFERRAL)
  // ==========================================
  Widget _buildReferralsTab() {
    if (_referrals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Referrals Recorded', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _referrals.length,
      itemBuilder: (context, index) {
        final r = _referrals[index];
        final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
        Color statusColor = status == 'CONVERTED' ? Colors.green : (status == 'REJECTED' ? Colors.red : Colors.orange);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: AppTheme.electricCobalt),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['referred_lead_name'] ?? 'Prospect #${r['referral_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(r['referred_phone'] ?? '—', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (r['notes'] != null && r['notes'].toString().isNotEmpty)
                  Text(r['notes'], style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Referred by: ${r['referrer_name'] ?? 'General'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Row(
                      children: [
                        if (status == 'PENDING') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                            tooltip: 'Mark Converted',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await CommunicationsService.updateReferralStatus(r['referral_id'], 'CONVERTED');
                              _loadData();
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Referral marked as converted!' : 'Failed to update referral.'),
                                    backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.orange, size: 22),
                            tooltip: 'Mark Rejected',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await CommunicationsService.updateReferralStatus(r['referral_id'], 'REJECTED');
                              _loadData();
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Referral marked as rejected.' : 'Failed to update referral.'),
                                    backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await CommunicationsService.deleteReferral(r['referral_id']);
                            _loadData();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Referral deleted.' : 'Failed to delete referral.'),
                                  backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 5: SUPPORT TICKETS (TXN_SUPPORT_TICKET)
  // ==========================================
  Widget _buildTicketsTab() {
    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No Support Tickets', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final t = _tickets[index];
        final status = (t['status'] ?? 'OPEN').toString().toUpperCase();
        final priority = (t['priority'] ?? 'MEDIUM').toString().toUpperCase();
        Color statusColor = status == 'RESOLVED' ? Colors.green : (status == 'IN_PROGRESS' ? Colors.blue : (status == 'CLOSED' ? Colors.grey : Colors.orange));
        Color priorityColor = priority == 'URGENT' ? Colors.red : (priority == 'HIGH' ? Colors.deepOrange : Colors.blueGrey);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Ticket #${t['ticket_id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'status_progress') {
                              final messenger = ScaffoldMessenger.of(context);
                              await CommunicationsService.updateTicketStatus(t['ticket_id'], 'IN_PROGRESS');
                              _loadData();
                              if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Ticket marked In Progress.')));
                            } else if (val == 'status_resolved') {
                              final messenger = ScaffoldMessenger.of(context);
                              await CommunicationsService.updateTicketStatus(t['ticket_id'], 'RESOLVED');
                              _loadData();
                              if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Ticket marked Resolved!'), backgroundColor: AppTheme.successText));
                            } else if (val == 'status_closed') {
                              final messenger = ScaffoldMessenger.of(context);
                              await CommunicationsService.updateTicketStatus(t['ticket_id'], 'CLOSED');
                              _loadData();
                              if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Ticket closed.')));
                            } else if (val == 'delete') {
                              final messenger = ScaffoldMessenger.of(context);
                              final success = await CommunicationsService.deleteTicket(t['ticket_id']);
                              _loadData();
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Ticket deleted.' : 'Failed to delete ticket.'),
                                    backgroundColor: success ? AppTheme.successText : AppTheme.urgentText,
                                  ),
                                );
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'status_progress', child: Text('Mark In Progress')),
                            const PopupMenuItem(value: 'status_resolved', child: Text('Mark Resolved', style: TextStyle(color: Colors.green))),
                            const PopupMenuItem(value: 'status_closed', child: Text('Mark Closed')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete Ticket', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(t['description'], style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Raised by: ${t['student_name'] ?? t['creator_name'] ?? 'User'}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    Text(
                      t['created_at'] != null ? t['created_at'].toString().split(' ')[0] : '',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
