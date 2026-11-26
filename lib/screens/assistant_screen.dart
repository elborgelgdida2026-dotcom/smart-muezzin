import 'package:flutter/material.dart';
import '../services/assistant_service.dart';
import '../services/settings_service.dart';

/// «رفيق المسلم» — local knowledge-based assistant chat.
///
/// NOT a live language model: it answers only from the app's verified
/// datasets (Quran, Hadith, Azkar, prayer times, Hijri calendar, and
/// fixed sourced general rulings). The disclaimer is shown at the top
/// of the screen and in every "I don't know" answer.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({bool isUser, String text, List<String> sources})>[];
  bool _busy = false;

  late final AssistantService _service;

  static const _suggestions = [
    'ما موعد صلاة العصر؟',
    'ما التاريخ الهجري اليوم؟',
    'ابحث عن آية الصبر',
    'أذكار الصباح',
    'ما أحكام الزكاة؟',
    'كيف أتوضأ؟',
  ];

  @override
  void initState() {
    super.initState();
    _service = AssistantService(settings: widget.settings);
    _messages.add((
      isUser: false,
      text: 'السلام عليكم، أنا «رفيق المسلم». أجيبك فقط مما هو موثق داخل '
          'التطبيق: القرآن الكريم، والأحاديث الموثقة، والأذكار، ومواقيت '
          'الصلاة، والتقويم الهجري. إن لم أجد إجابة موثقة سأقول لك ذلك '
          'بصراحة بدل أن أختلق إجابة.',
      sources: const [],
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() {
      _messages.add((isUser: true, text: text, sources: const []));
      _busy = true;
    });
    final answer = await _service.ask(text);
    if (mounted) {
      setState(() {
        _messages.add((
          isUser: false,
          text: answer.text,
          sources: answer.sources,
        ));
        _busy = false;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رفيق المسلم')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Text(
              'مساعد محلي — ليس نموذج ذكاء اصطناعي حيًا. يجيب فقط من مصادر '
              'موثقة داخل التطبيق، ولا يختلق آيات أو أحاديث أو فتاوى.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.text, style: const TextStyle(fontSize: 15)),
                        if (m.sources.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'المصدر: ${m.sources.join(' • ')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(s),
                    onPressed: _busy ? null : () => _send(s),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب سؤالك…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: 'إرسال',
                  onPressed: _busy ? null : () => _send(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
