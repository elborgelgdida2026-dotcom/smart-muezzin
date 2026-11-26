import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prayer_times_model.dart';

/// One prayer row. The current prayer is highlighted in emerald.
class PrayerCard extends StatelessWidget {
  const PrayerCard({super.key, required this.entry});
  final PrayerTimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a', 'ar').format(entry.time);
    return Card(
      color: entry.isCurrent
          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
          : null,
      child: ListTile(
        leading: Icon(
          Icons.mosque,
          color: entry.isCurrent
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        title: Text(entry.arabicName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(time, style: const TextStyle(fontSize: 16)),
        subtitle: entry.isCurrent ? const Text('الصلاة الحالية') : null,
      ),
    );
  }
}
