import 'package:flutter/material.dart';

/// Kids section: learning prayer/wudu steps in order, short surahs,
/// and a simple multiple-choice quiz. No ads targeted at children.
/// Content is educational and sourced from the same verified texts.
class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key});
  @override
  State<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends State<KidsScreen> {
  int _quizIndex = 0;
  int _score = 0;
  String? _feedback;

  static const _wuduSteps = [
    'النية والبسملة',
    'غسل الكفين ثلاثًا',
    'المضمضة والاستنشاق',
    'غسل الوجه ثلاثًا',
    'غسل اليدين إلى المرفقين',
    'مسح الرأس والأذنين',
    'غسل القدمين إلى الكعبين',
  ];

  static const _quiz = [
    (
      q: 'كم عدد الصلوات المفروضة في اليوم؟',
      options: ['3', '5', '7'],
      answer: 1,
    ),
    (
      q: 'ما أول سورة في القرآن؟',
      options: ['الإخلاص', 'الفاتحة', 'الناس'],
      answer: 1,
    ),
    (
      q: 'كم عدد ركعات صلاة الفجر؟',
      options: ['2', '3', '4'],
      answer: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = _quiz[_quizIndex % _quiz.length];
    return Scaffold(
      appBar: AppBar(title: const Text('قسم الأطفال')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('خطوات الوضوء بالترتيب',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ..._wuduSteps.asMap().entries.map(
                  (e) => ListTile(
                    leading: CircleAvatar(child: Text('${e.key + 1}')),
                    title: Text(e.value),
                  ),
                ),
            const SizedBox(height: 16),
            const Text('سور قصيرة للحفظ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const ListTile(title: Text('سورة الإخلاص'), subtitle: Text('4 آيات')),
            const ListTile(title: Text('سورة الفلق'), subtitle: Text('5 آيات')),
            const ListTile(title: Text('سورة الناس'), subtitle: Text('6 آيات')),
            const SizedBox(height: 16),
            const Text('مسابقة سريعة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('النقاط: $_score'),
            Text(item.q, style: const TextStyle(fontSize: 17)),
            ...item.options.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        final correct = e.key == item.answer;
                        setState(() {
                          _feedback =
                              correct ? 'إجابة صحيحة! أحسنت 👏' : 'حاول مرة أخرى';
                          if (correct) {
                            _score++;
                            _quizIndex++;
                          }
                        });
                      },
                      child: Text(e.value),
                    ),
                  ),
                ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_feedback!, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
