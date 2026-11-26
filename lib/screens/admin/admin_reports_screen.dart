import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';

/// Review user reports: open → in_review → resolved, with an admin note.
/// Reporters' identities are shown only as their user id (no worship
/// data is ever attached to a report).
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _filter = 'all';
  late Future<List<Map<String, dynamic>>> _reports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _reports = AdminService.instance.fetchReports(status: _filter);
    setState(() {});
  }

  Future<void> _setStatus(
      Map<String, dynamic> report, String status) async {
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تغيير الحالة إلى «$status»'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ملاحظة إدارية (اختياري)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.instance.updateReport(
        report['id'].toString(),
        status: status,
        adminNote: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
      if (mounted) {
        showAdminSnack(context, 'تم تحديث البلاغ.');
        _load();
      }
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر التحديث: $e', error: true);
    } finally {
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    const filters = {
      'all': 'الكل',
      'open': 'مفتوحة',
      'in_review': 'قيد المراجعة',
      'resolved': 'تمت المعالجة',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('البلاغات والمقترحات')),
      body: AdminGate(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: filters.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _filter == e.key,
                      onSelected: (_) {
                        _filter = e.key;
                        _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _reports,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('تعذّر التحميل: ${snap.error}'));
                  }
                  final reports = snap.data!;
                  if (reports.isEmpty) {
                    return const Center(child: Text('لا توجد بلاغات.'));
                  }
                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, i) {
                      final r = reports[i];
                      final status = r['status'] as String? ?? 'open';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(
                              '${r['type'] ?? 'بلاغ'} — ${r['target_id'] ?? ''}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['details']?.toString() ?? ''),
                              Text(
                                'الحالة: $status • ${formatAdminDate(r['created_at']?.toString())}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if ((r['admin_note'] as String?)?.isNotEmpty == true)
                                Text('ملاحظة: ${r['admin_note']}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) => _setStatus(r, v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'in_review',
                                  child: Text('قيد المراجعة')),
                              PopupMenuItem(
                                  value: 'resolved',
                                  child: Text('تمت المعالجة')),
                              PopupMenuItem(
                                  value: 'open', child: Text('إعادة فتح')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
