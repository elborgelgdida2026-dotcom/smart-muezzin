import 'package:flutter/material.dart';

/// Zakat calculator: money, gold, silver, trade goods.
/// Nisab: 85 g gold or 595 g silver (user enters the local price per
/// gram, or the app uses the entered value — no price is invented).
/// Zakat = 2.5% of the zakatable amount once nisab + hawl are met.
/// Questions needing a scholar are flagged in the UI text below.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});
  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _cash = TextEditingController();
  final _goldGrams = TextEditingController();
  final _goldPrice = TextEditingController();
  final _silverGrams = TextEditingController();
  final _silverPrice = TextEditingController();
  String? _result;

  void _calculate() {
    final cash = double.tryParse(_cash.text) ?? 0;
    final goldG = double.tryParse(_goldGrams.text) ?? 0;
    final goldP = double.tryParse(_goldPrice.text) ?? 0;
    final silverG = double.tryParse(_silverGrams.text) ?? 0;
    final silverP = double.tryParse(_silverPrice.text) ?? 0;
    final goldValue = goldG * goldP;
    final silverValue = silverG * silverP;
    final total = cash + goldValue + silverValue;
    final goldNisab = 85 * goldP;
    final silverNisab = 595 * silverP;
    final nisab = goldP > 0 ? goldNisab : silverNisab;
    final due = total >= nisab && nisab > 0 ? total * 0.025 : 0.0;
    setState(() {
      _result = total >= nisab && nisab > 0
          ? 'المبلغ الخاضع للزكاة: ${total.toStringAsFixed(2)}\n'
              'النصاب (ذهب): ${goldNisab.toStringAsFixed(2)}\n'
              'الزكاة المستحقة (2.5%): ${due.toStringAsFixed(2)}'
          : 'لم يبلغ المال النصاب بعد (النصاب: ${nisab.toStringAsFixed(2)}). '
              'أدخل سعر الذهب/الفضة المحلي لحساب النصاب بدقة.';
    });
  }

  @override
  void dispose() {
    _cash.dispose();
    _goldGrams.dispose();
    _goldPrice.dispose();
    _silverGrams.dispose();
    _silverPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الزكاة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _cash,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'النقود والمدخرات', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goldGrams,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'الذهب (غرام)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goldPrice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'سعر غرام الذهب المحلي',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _silverGrams,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'الفضة (غرام)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _silverPrice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'سعر غرام الفضة المحلي',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('احسب الزكاة'),
            ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_result!, style: const TextStyle(fontSize: 17)),
              ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة: الزكاة تجب ببلوغ النصاب وحولان الحول. '
              'المسائل التفصيلية تحتاج استشارة شرعية.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
