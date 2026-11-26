/// An Azkar item with its verified source and fixed repetition count
/// (only where the count is established; otherwise repetitions = 1 and
/// the UI says so). No fabricated virtues or counts are included.
class Zikr {
  Zikr({
    required this.id,
    required this.category,
    required this.text,
    required this.source,
    required this.repetitions,
  });

  factory Zikr.fromJson(Map<String, dynamic> j) => Zikr(
        id: j['id'] as String,
        category: j['category'] as String,
        text: j['text'] as String,
        source: j['source'] as String,
        repetitions: j['repetitions'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'text': text,
        'source': source,
        'repetitions': repetitions,
      };

  final String id;
  final String category;
  final String text;
  final String source;
  final int repetitions;
}
