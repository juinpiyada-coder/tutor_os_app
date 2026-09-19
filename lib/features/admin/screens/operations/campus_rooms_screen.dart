import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/universal_owner_header.dart';
import '../../services/academic_structure_service.dart';
import '../../services/settings_service.dart';

class CampusRoomsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CampusRoomsScreen({super.key, this.onOpenDrawer});

  @override
  State<CampusRoomsScreen> createState() => _CampusRoomsScreenState();
}

class _CampusRoomsScreenState extends State<CampusRoomsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _branches = [];
  String _selectedFilter = 'ALL'; // 'ALL', 'CLASSROOM', 'LAB'

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      AcademicStructureService.getRooms(),
      SettingsService.getBranches().catchError((_) => <Map<String, dynamic>>[]),
    ]);
    if (mounted) {
      setState(() {
        _rooms = results[0];
        _branches = results[1];
        _isLoading = false;
      });
    }
  }

  void _openRoomModal([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['room_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['room_name'] ?? '');
    final capCtrl = TextEditingController(text: (item?['capacity'] ?? '').toString());
    final latCtrl = TextEditingController(text: item?['latitude']?.toString() ?? '');
    final lngCtrl = TextEditingController(text: item?['longitude']?.toString() ?? '');
    final geofenceCtrl = TextEditingController(text: (item?['geofence_radius_m'] ?? '50').toString());
    bool isLab = item != null ? (item['is_lab'] == 1 || item['is_lab'] == true) : false;
    String status = (item?['status'] != null && item!['status'].toString().isNotEmpty)
        ? item['status'].toString().toUpperCase()
        : 'AVAILABLE';
    if (!['AVAILABLE', 'UNAVAILABLE', 'MAINTENANCE', 'ARCHIVED'].contains(status)) {
      status = 'AVAILABLE';
    }

    final branchIds = _branches.map((b) => int.tryParse(b['branch_id']?.toString() ?? '0') ?? 0).where((id) => id > 0).toSet();
    int? parsedBranchId = int.tryParse(item?['branch_id']?.toString() ?? '');
    int? selectedBranchId = (parsedBranchId != null && branchIds.contains(parsedBranchId))
        ? parsedBranchId
        : (branchIds.isNotEmpty ? branchIds.first : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                          isEdit ? 'Edit Room / Lab' : 'Add Room / Lab',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textHeading,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_branches.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedBranchId,
                        decoration: InputDecoration(
                          labelText: 'Branch / Campus Location',
                          prefixIcon: const Icon(Icons.business_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _branches.map((b) {
                          final id = int.tryParse(b['branch_id']?.toString() ?? '0') ?? 0;
                          final name = b['branch_name'] ?? '';
                          return DropdownMenuItem<int>(value: id, child: Text(name));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedBranchId = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Room Code (e.g. CR-101 or LAB-02)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Room / Lab Name (e.g. Science Lab Alpha)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Seating Capacity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Is Practical / Computer / Science Lab?',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      value: isLab,
                      onChanged: (val) => setModalState(() => isLab = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'GPS Latitude',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lngCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'GPS Longitude',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: geofenceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Geofence Radius (meters)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'AVAILABLE', child: Text('Available')),
                        DropdownMenuItem(value: 'UNAVAILABLE', child: Text('Unavailable')),
                        DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                      ],
                      onChanged: (val) => setModalState(() => status = val ?? 'AVAILABLE'),
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
                          if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill required fields')),
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          final payload = <String, dynamic>{
                            if (selectedBranchId != null) 'branch_id': selectedBranchId!,
                            'room_code': codeCtrl.text.trim(),
                            'room_name': nameCtrl.text.trim(),
                            'capacity': int.tryParse(capCtrl.text.trim()) ?? 30,
                            'is_lab': isLab,
                            'latitude': latCtrl.text.trim().isNotEmpty ? double.tryParse(latCtrl.text.trim()) : null,
                            'longitude': lngCtrl.text.trim().isNotEmpty ? double.tryParse(lngCtrl.text.trim()) : null,
                            'geofence_radius_m': int.tryParse(geofenceCtrl.text.trim()) ?? 50,
                            'status': status,
                          };
                          bool success = false;
                          if (isEdit) {
                            success = await AcademicStructureService.updateRoom(
                              int.parse(item['room_id'].toString()),
                              payload,
                            );
                          } else {
                            success = await AcademicStructureService.addRoom(payload);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Room saved!' : 'Action failed')),
                            );
                            _loadRooms();
                          }
                        },
                        child: Text(isEdit ? 'Update Room' : 'Create Room'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredRooms = _rooms.where((r) {
      final isLab = r['is_lab'] == 1 || r['is_lab'] == true;
      if (_selectedFilter == 'LAB') return isLab;
      if (_selectedFilter == 'CLASSROOM') return !isLab;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        title: 'Campus Infrastructure & Rooms',
        subtitle: 'Classrooms, lab allocations & seating capacity',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.electricCobalt,
        foregroundColor: Colors.white,
        onPressed: () => _openRoomModal(),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Room / Lab'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(isDark),
                Expanded(
                  child: filteredRooms.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadRooms,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRooms.length,
                            itemBuilder: (context, index) {
                              return _buildRoomCard(filteredRooms[index], isDark);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _filterChip('ALL', 'All Rooms (${_rooms.length})', isDark),
          const SizedBox(width: 8),
          _filterChip(
            'CLASSROOM',
            'Classrooms (${_rooms.where((r) => r['is_lab'] != 1 && r['is_lab'] != true).length})',
            isDark,
          ),
          const SizedBox(width: 8),
          _filterChip(
            'LAB',
            'Labs (${_rooms.where((r) => r['is_lab'] == 1 || r['is_lab'] == true).length})',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.electricCobalt
              : (isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No Rooms Found',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricCobalt,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _openRoomModal(),
            icon: const Icon(Icons.add),
            label: const Text('Add Classroom or Lab'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> item, bool isDark) {
    final isLab = item['is_lab'] == 1 || item['is_lab'] == true;
    final roomId = int.tryParse(item['room_id']?.toString() ?? '0') ?? 0;
    final capacity = item['capacity'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkAcademicBg : AppTheme.academicBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['room_code'] ?? '',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.academicText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLab
                            ? (isDark ? AppTheme.darkWarningBg : AppTheme.warningBg)
                            : (isDark ? AppTheme.darkSuccessBg : AppTheme.successBg),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLab ? Icons.biotech : Icons.chair,
                            size: 12,
                            color: isLab ? AppTheme.warningText : AppTheme.successText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLab ? 'Lab' : 'Classroom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isLab ? AppTheme.warningText : AppTheme.successText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      _openRoomModal(item);
                    } else if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Room?'),
                          content: Text('Are you sure you want to delete ${item['room_name']}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && roomId > 0) {
                        await AcademicStructureService.deleteRoom(roomId);
                        _loadRooms();
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['room_name'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.groups, size: 15, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Capacity: $capacity Seats',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                ),
                if (item['geofence_radius_m'] != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.radar, size: 15, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Geofence: ${item['geofence_radius_m']}m',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
