import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

/// Hijri calendar: today in Hijri + Gregorian, converter both ways,
/// and the main Islamic occasions (dates are estimated until the
/// official moon-sighting announcement — the UI says so).
class HijriScreen extends StatefulWidget {
  const HijriScreen({super.key});
  @override
  State<HijriScreen> createState() => _HijriScreenState();
}

class _HijriScreenState extends State<HijriScreen> {
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  String? _converted;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    return Scaffold(
      appBar: AppBar(title: const Text('التقويم الهجري')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اليوم: ${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear} هـ',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              'الموافق: ${now.day}/${now.month}/${now.year} م',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'المناسبات القادمة (تقديرية حتى الإعلان الرسمي عن رؤية الهلال):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const ListTile(title: Text('بداية رمضان'), subtitle: Text('١ رمضان')),
            const ListTile(title: Text('عيد الفطر'), subtitle: Text('١ شوال')),
            const ListTile(title: Text('يوم عرفة'), subtitle: Text('٩ ذو الحجة')),
            const ListTile(title: Text('عيد الأضحى'), subtitle: Text('١٠ ذو الحجة')),
            const ListTile(title: Text('عاشوراء'), subtitle: Text('١٠ محرم')),
            const ListTile(title: Text('الأيام البيض'), subtitle: Text('١٣ و١٤ و١٥ من كل شهر هجري')),
            const SizedBox(height: 16),
            const Text('تحويل هجري ← ميلادي:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _day,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'اليوم'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _month,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الشهر'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'السنة'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final d = int.tryParse(_day.text) ?? 1;
                final m = int.tryParse(_month.text) ?? 1;
                final y = int.tryParse(_year.text) ?? 1447;
                final hijriDate = HijriCalendar()
                  ..hDay = d
                  ..hMonth = m
                  ..hYear = y;
                final greg = hijriDate.hijriToGregorian(y, m, d);
                setState(() {
                  _converted =
                      '$d/$m/$y هـ  =  ${greg.day}/${greg.month}/${greg.year} م';
                });
              },
              child: const Text('حوّل التاريخ'),
            ),
            if (_converted != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_converted!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17)),
              ),
          ],
        ),
      ),
    );
  }
}
