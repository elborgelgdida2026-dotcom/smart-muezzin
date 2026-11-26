import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';

/// Append-only audit log: who did what, to which table/row, and when.
/// Rows can never be edited or deleted from the app (RLS forbids it).
class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  String _tableFilter = 'all';
  late Future<List<Map<String, dynamic>>> _rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _rows = AdminService.instance.fetchAudit(limit: 200);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التدقيق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _load,
          ),
        ],
      ),
      body: AdminGate(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _rows,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('تعذّر التحميل: ${snap.error}'));
            }
            var rows = snap.data!;
            final tables = <String>{'all'};
            for (final r in rows) {
              tables.add((r['target_table'] as String?) ?? '');
            }
            tables.remove('');
            if (_tableFilter != 'all') {
              rows = rows
                  .where((r) => r['target_table'] == _tableFilter)
                  .toList();
            }
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: tables.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(t == 'all' ? 'الكل' : t),
                          selected: _tableFilter == t,
                          onSelected: (_) {
                            setState(() => _tableFilter = t);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'سجل التدقيق للقراءة فقط: لا يمكن تعديل أو حذف أي سطر '
                    'من التطبيق، وتُحفظ كل إجراءات الإدارة هنا تلقائيًا.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text('لا توجد إجراءات مسجلة بعد.'))
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final r = rows[i];
                            final details = r['details'];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(
                                  '${r['action']} — ${r['target_table']}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (r['target_id'] != null)
                                      Text('الهدف: ${r['target_id']}'),
                                    if (details != null &&
                                        details.toString() != '{}')
                                      Text('التفاصيل: $details'),
                                    Text(
                                      formatAdminDate(
                                          r['created_at']?.toString()),
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
