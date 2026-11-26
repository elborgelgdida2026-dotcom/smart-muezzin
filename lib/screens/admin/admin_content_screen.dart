import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_common.dart';

/// Manage all Islamic content tables (spec section 27).
///
/// Religious-content rule, enforced here and in the database:
/// * `source` is REQUIRED for Azkar and Hadith — the form refuses to save
///   without it.
/// * New/edited Azkar and Hadith are saved with review_status 'pending'
///   and stay invisible to the public app until an admin approves them.
/// * Deactivation is preferred over deletion for religious rows; deletion
///   still exists (with confirmation) and is written to the audit log.
class _Field {
  const _Field(this.key, this.label,
      {this.multiline = false, this.required = false, this.kind = _Kind.text});
  final String key;
  final String label;
  final bool multiline;
  final bool required;
  final _Kind kind;
}

enum _Kind { text, integer, number }

class _TableConfig {
  const _TableConfig(this.table, this.title, this.fields,
      {this.hasReview = false, this.titleKey = 'title'});
  final String table;
  final String title;
  final List<_Field> fields;
  final bool hasReview;
  final String titleKey;
}

const _configs = <_TableConfig>[
  _TableConfig('azkar', 'الأذكار', [
    _Field('category', 'التصنيف', required: true),
    _Field('title', 'العنوان', required: true),
    _Field('text', 'النص', multiline: true, required: true),
    _Field('source', 'المصدر (إلزامي)', required: true),
    _Field('repetitions', 'عدد التكرارات', kind: _Kind.integer),
    _Field('sort_order', 'الترتيب', kind: _Kind.integer),
  ], hasReview: true),
  _TableConfig('hadith', 'الأحاديث', [
    _Field('book', 'الكتاب (مثال: bukhari)', required: true),
    _Field('book_title', 'اسم الكتاب', required: true),
    _Field('number', 'رقم الحديث', kind: _Kind.integer, required: true),
    _Field('text', 'نص الحديث', multiline: true, required: true),
    _Field('narrator', 'الراوي'),
    _Field('grade', 'الدرجة'),
    _Field('chapter', 'الباب/الفصل'),
    _Field('source', 'المصدر (إلزامي)', required: true),
  ], hasReview: true, titleKey: 'book_title'),
  _TableConfig('reciters', 'القرّاء', [
    _Field('name', 'الاسم', required: true),
    _Field('identifier', 'معرّف AlQuran Cloud (مثال: ar.alafasy)'),
    _Field('sort_order', 'الترتيب', kind: _Kind.integer),
  ], titleKey: 'name'),
  _TableConfig('muezzins', 'المؤذنون', [
    _Field('name', 'الاسم', required: true),
    _Field('audio_url', 'رابط الصوت (مرخّص فقط — اتركه فارغًا إن لم يوجد)'),
    _Field('prayer', 'الصلاة (مثال: fajr أو all)'),
    _Field('sort_order', 'الترتيب', kind: _Kind.integer),
  ], titleKey: 'name'),
  _TableConfig('events', 'المناسبات الإسلامية', [
    _Field('title', 'العنوان', required: true),
    _Field('hijri_month', 'الشهر الهجري (1-12)', kind: _Kind.integer, required: true),
    _Field('hijri_day', 'اليوم الهجري (1-30)', kind: _Kind.integer, required: true),
    _Field('hijri_date', 'التاريخ الهجري نصًا'),
    _Field('gregorian_date', 'التاريخ الميلادي (تقديري) YYYY-MM-DD'),
    _Field('description', 'الوصف', multiline: true),
  ]),
  _TableConfig('cities', 'المدن وطرق الحساب', [
    _Field('name_ar', 'الاسم بالعربية', required: true),
    _Field('name_en', 'الاسم بالإنجليزية', required: true),
    _Field('country', 'الدولة', required: true),
    _Field('latitude', 'خط العرض', kind: _Kind.number, required: true),
    _Field('longitude', 'خط الطول', kind: _Kind.number, required: true),
    _Field('timezone', 'المنطقة الزمنية (مثال: Africa/Cairo)'),
  ], titleKey: 'name_ar'),
  _TableConfig('translations', 'الترجمات', [
    _Field('key', 'المفتاح', required: true),
    _Field('lang', 'اللغة (ar أو en)', required: true),
    _Field('value', 'القيمة', multiline: true, required: true),
  ], titleKey: 'key'),
];

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _rows = <int, List<Map<String, dynamic>>>{
    for (var i = 0; i < _configs.length; i++) i: [],
  };
  final _loading = <int, bool>{for (var i = 0; i < _configs.length; i++) i: true};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _configs.length, vsync: this);
    for (var i = 0; i < _configs.length; i++) {
      _load(i);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load(int i) async {
    setState(() => _loading[i] = true);
    try {
      final rows = await AdminService.instance
          .fetchTable(_configs[i].table, limit: 200);
      if (mounted) setState(() => _rows[i] = rows);
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر التحميل: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading[i] = false);
    }
  }

  Future<void> _edit(int i, [Map<String, dynamic>? row]) async {
    final cfg = _configs[i];
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ContentFormDialog(config: cfg, row: row),
    );
    if (saved == true) _load(i);
  }

  Future<void> _setReview(int i, Map<String, dynamic> row, String status) async {
    final ok = await confirmDialog(
      context,
      title: status == 'approved' ? 'اعتماد المحتوى' : 'رفض المحتوى',
      message: status == 'approved'
          ? 'سيظهر هذا المحتوى للمستخدمين بعد التأكد من صحة نصه ومصدره. هل راجعت المصدر؟'
          : 'سيُرفض هذا المحتوى ولن يظهر للمستخدمين.',
      confirmLabel: status == 'approved' ? 'اعتماد' : 'رفض',
    );
    if (!ok) return;
    try {
      await AdminService.instance
          .setReviewStatus(_configs[i].table, row['id'].toString(), status);
      if (mounted) {
        showAdminSnack(context, 'تم ${status == 'approved' ? 'الاعتماد' : 'الرفض'}.');
        _load(i);
      }
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر الحفظ: $e', error: true);
    }
  }

  Future<void> _toggleActive(int i, Map<String, dynamic> row, bool v) async {
    try {
      await AdminService.instance
          .setActive(_configs[i].table, row['id'].toString(), v);
      _load(i);
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر الحفظ: $e', error: true);
    }
  }

  Future<void> _delete(int i, Map<String, dynamic> row) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف نهائي',
      message: 'سيُحذف هذا الصف نهائيًا ويُسجَّل الحذف في سجل التدقيق. '
          'للمحتوى الديني يُفضَّل التعطيل بدل الحذف. هل أنت متأكد؟',
      confirmLabel: 'حذف',
    );
    if (!ok) return;
    try {
      await AdminService.instance
          .deleteRow(_configs[i].table, row['id'].toString());
      if (mounted) {
        showAdminSnack(context, 'تم الحذف.');
        _load(i);
      }
    } catch (e) {
      if (mounted) showAdminSnack(context, 'تعذّر الحذف: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحتوى الإسلامي'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: _configs.map((c) => Tab(text: c.title)).toList(),
        ),
      ),
      body: AdminGate(
        child: TabBarView(
          controller: _tabs,
          children: List.generate(_configs.length, (i) {
            final cfg = _configs[i];
            if (_loading[i] == true) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = _rows[i]!;
            return Column(
              children: [
                if (cfg.hasReview)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'قاعدة المراجعة: أي ذكر أو حديث جديد يُحفظ بحالة «بانتظار '
                      'المراجعة» ولا يظهر للمستخدمين حتى يعتمده مدير بعد '
                      'التأكد من صحة النص والمصدر.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text('لا توجد صفوف بعد.'))
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, j) {
                            final row = rows[j];
                            final review = row['review_status'] as String?;
                            final active = row['is_active'] as bool? ?? true;
                            final title = row[cfg.titleKey]?.toString() ?? '';
                            final sub = [
                              if (row['category'] != null)
                                row['category'].toString(),
                              if (row['source'] != null)
                                'المصدر: ${row['source']}',
                              if (row['book'] != null)
                                '${row['book']} #${row['number']}',
                              if (row['text'] != null)
                                (row['text'] as String).length > 80
                                    ? '${(row['text'] as String).substring(0, 80)}…'
                                    : row['text'].toString(),
                            ].join(' • ');
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(title.isEmpty ? '(بدون عنوان)' : title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sub.isNotEmpty) Text(sub),
                                    if (review != null)
                                      Text(
                                        'المراجعة: ${review == 'approved' ? 'معتمد' : review == 'pending' ? 'بانتظار المراجعة' : 'مرفوض'}',
                                        style: TextStyle(
                                          color: review == 'approved'
                                              ? Colors.green.shade700
                                              : Colors.orange.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    switch (v) {
                                      case 'edit':
                                        _edit(i, row);
                                      case 'approve':
                                        _setReview(i, row, 'approved');
                                      case 'reject':
                                        _setReview(i, row, 'rejected');
                                      case 'toggle':
                                        _toggleActive(i, row, !active);
                                      case 'delete':
                                        _delete(i, row);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'edit', child: Text('تعديل')),
                                    if (review == 'pending')
                                      const PopupMenuItem(
                                          value: 'approve',
                                          child: Text('اعتماد')),
                                    if (review == 'pending')
                                      const PopupMenuItem(
                                          value: 'reject',
                                          child: Text('رفض')),
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(active
                                          ? 'تعطيل'
                                          : 'تفعيل'),
                                    ),
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('حذف نهائي')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => _edit(_tabs.index),
          tooltip: 'إضافة جديد',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ContentFormDialog extends StatefulWidget {
  const _ContentFormDialog({required this.config, this.row});
  final _TableConfig config;
  final Map<String, dynamic>? row;

  @override
  State<_ContentFormDialog> createState() => _ContentFormDialogState();
}

class _ContentFormDialogState extends State<_ContentFormDialog> {
  final _controllers = <String, TextEditingController>{};
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.config.fields) {
      final v = widget.row?[f.key];
      _controllers[f.key] =
          TextEditingController(text: v == null ? '' : v.toString());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final values = <String, dynamic>{};
    for (final f in widget.config.fields) {
      final raw = _controllers[f.key]!.text.trim();
      if (f.required && raw.isEmpty) {
        setState(() => _error = 'الحقل «${f.label}» إلزامي.');
        return;
      }
      if (raw.isEmpty) continue;
      switch (f.kind) {
        case _Kind.integer:
          final n = int.tryParse(raw);
          if (n == null) {
            setState(() => _error = 'الحقل «${f.label}» يجب أن يكون عددًا صحيحًا.');
            return;
          }
          values[f.key] = n;
        case _Kind.number:
          final n = double.tryParse(raw);
          if (n == null) {
            setState(() => _error = 'الحقل «${f.label}» يجب أن يكون عددًا.');
            return;
          }
          values[f.key] = n;
        case _Kind.text:
          values[f.key] = raw;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final admin = AdminService.instance;
      final row = widget.row;
      if (row == null) {
        // New religious content always starts as pending review.
        if (widget.config.hasReview) {
          values['review_status'] = 'pending';
          values['is_active'] = true;
        }
        await admin.insertRow(widget.config.table, values);
      } else {
        // Editing religious content sends it back to pending review.
        if (widget.config.hasReview) values['review_status'] = 'pending';
        await admin.updateRow(
            widget.config.table, row['id'].toString(), values);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذّر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.row == null;
    return AlertDialog(
      title: Text('${isNew ? 'إضافة' : 'تعديل'} — ${widget.config.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.config.hasReview)
              const Text(
                'سيُحفظ هذا المحتوى بحالة «بانتظار المراجعة» ولن يظهر '
                'للمستخدمين حتى يعتمده مدير بعد التأكد من المصدر.',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            for (final f in widget.config.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _controllers[f.key],
                  maxLines: f.multiline ? 4 : 1,
                  keyboardType: f.kind == _Kind.text
                      ? TextInputType.text
                      : TextInputType.number,
                  decoration: InputDecoration(
                    labelText: f.label,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'جارٍ الحفظ...' : 'حفظ'),
        ),
      ],
    );
  }
}
