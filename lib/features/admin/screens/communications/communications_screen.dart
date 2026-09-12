import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/communications_service.dart';
import '../../services/directory_service.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

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
    final titleController = TextEditingController(text: existingBroadcast?['title'] ?? '');
    final contentController = TextEditingController(text: existingBroadcast?['content'] ?? '');
    String target = existingBroadcast?['target_audience'] ?? 'ALL';
    String channel = existingBroadcast?['channel'] ?? 'PUSH';
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
                              channel = tpl['channel'] ?? channel;
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
                          initialValue: ['PUSH', 'WHATSAPP', 'SMS', 'EMAIL'].contains(channel.toUpperCase()) ? channel.toUpperCase() : 'PUSH',
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
                          initialValue: target.contains('Student') ? 'STUDENT' : (target.contains('Staff') ? 'STAFF' : 'ALL'),
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
                        if (isEditing) {
                          await CommunicationsService.updateBroadcast(existingBroadcast['broadcast_id'], {
                            'title': titleController.text.trim(),
                            'content': contentController.text.trim(),
                            'channel': channel,
                            'target': target,
                          });
                        } else {
                          await CommunicationsService.sendBroadcast({
                            'title': titleController.text.trim(),
                            'content': contentController.text.trim(),
                            'channel': channel,
                            'target': target,
                          });
                        }
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Broadcast updated successfully!' : 'Broadcast dispatched successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
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
  void _openTemplateDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController(text: 'TMPL_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    String channel = 'WHATSAPP';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Reusable Message Template',
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
                      label: const Text('Save Message Template'),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter template name and body.')));
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        await CommunicationsService.createTemplate({
                          'template_name': nameController.text.trim(),
                          'template_code': codeController.text.trim(),
                          'channel': channel,
                          'subject_template': subjectController.text.trim(),
                          'body_template': bodyController.text.trim(),
                        });
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Message template saved successfully!'), backgroundColor: AppTheme.successText),
                          );
                        }
                      },
                    ),
                  ),
                ],
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
                            labelText: 'Start Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: status,
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
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        final payload = {
                          'campaign_name': nameController.text.trim(),
                          'campaign_code': codeController.text.trim(),
                          'budget': double.tryParse(budgetController.text.trim()) ?? 0,
                          'start_date': startController.text.trim(),
                          'end_date': endController.text.trim(),
                          'status': status,
                        };
                        if (isEditing) {
                          await CommunicationsService.updateCampaign(existingCampaign['campaign_id'], payload);
                        } else {
                          await CommunicationsService.createCampaign(payload);
                        }
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Campaign updated successfully!' : 'Campaign launched successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
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
                          labelText: 'Referring Student *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.electricCobalt),
                        ),
                        items: _students.map((s) {
                          final id = int.tryParse(s['student_id']?.toString() ?? '0') ?? 0;
                          final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                          final code = s['student_code'] ?? '';
                          return DropdownMenuItem<int>(value: id, child: Text('$name ($code)'));
                        }).toList(),
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
                          if (leadNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter referred person name.')));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          await CommunicationsService.createReferral({
                            'referrer_student_id': referrerStudentId,
                            'campaign_id': campaignId,
                            'lead_name': leadNameController.text.trim(),
                            'lead_phone': leadPhoneController.text.trim(),
                            'notes': notesController.text.trim(),
                            'status': 'PENDING',
                          });
                          _loadData();
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Referral recorded successfully!'), backgroundColor: AppTheme.successText),
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
      appBar: AppBar(
        title: const Text('Communications & Notifications Hub'),
        elevation: 0,
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.primaryNavy,
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
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
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
        final channel = (b['channel'] ?? '').toString().toUpperCase();
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
                          await CommunicationsService.deleteBroadcast(b['broadcast_id'] ?? b['message_id'] ?? index);
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Broadcast deleted.'), backgroundColor: AppTheme.successText),
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
                      label: Text(b['target_audience'] ?? b['target'] ?? '', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const Spacer(),
                    Text(
                      b['sent_at'] ?? '',
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
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () async {
                        await CommunicationsService.deleteTemplate(t['template_id'] ?? index);
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Template deleted.'), backgroundColor: AppTheme.successText),
                          );
                        }
                      },
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
                          await CommunicationsService.deleteCampaign(c['campaign_id'] ?? index);
                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Campaign deleted.'), backgroundColor: AppTheme.successText),
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
                        Text('${c['start_date'] ?? ''} → ${c['end_date'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                            Text(r['referred_lead_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(r['referred_phone'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                    Text('Referred by: ${r['referrer_name'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Row(
                      children: [
                        if (status == 'PENDING')
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
                            tooltip: 'Mark Converted',
                            onPressed: () async {
                              await CommunicationsService.updateReferralStatus(r['referral_id'] ?? index, 'CONVERTED');
                              _loadData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Referral marked as converted!'), backgroundColor: AppTheme.successText),
                                );
                              }
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Delete',
                          onPressed: () async {
                            await CommunicationsService.deleteReferral(r['referral_id'] ?? index);
                            _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Referral deleted.'), backgroundColor: AppTheme.successText),
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
        Color statusColor = status == 'RESOLVED' ? Colors.green : (status == 'IN_PROGRESS' ? Colors.blue : Colors.orange);

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
                    Text(t['ticket_id'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Raised by: ${t['student_name'] ?? ''}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
