import 'package:flutter/material.dart';
import '../models/radio_station.dart';
import '../services/radio_service.dart';

/// Quran radio: 8 live stations (see radio_station.dart for sources
/// and verification). Live internet radio — requires an internet
/// connection; a dead stream shows an honest error, never fake audio.
class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});
  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final _service = RadioService();
  Set<String> _favs = {};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    final favs = await _service.favorites();
    _service.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _service.errorStream.listen((_) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {
      _favs = favs;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(RadioStation station) async {
    if (_service.current?.id == station.id && _service.isPlaying) {
      await _service.stop();
    } else {
      await _service.play(station);
    }
  }

  Future<void> _toggleFav(String id) async {
    final nowFav = await _service.toggleFavorite(id);
    if (mounted) {
      setState(() {
        if (nowFav) {
          _favs.add(id);
        } else {
          _favs.remove(id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _service.current;
    return Scaffold(
      appBar: AppBar(title: const Text('إذاعات القرآن الكريم')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'بث مباشر عبر الإنترنت من مصادر رسمية. إذا انقطع البث '
                    'يعيد التطبيق الاتصال تلقائيًا، ويمكنك إعادة المحاولة يدويًا.',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_service.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.error_outline, color: Colors.red),
                        title: Text(_service.error!),
                        trailing: TextButton(
                          onPressed: current == null
                              ? null
                              : () => _togglePlay(current),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: kRadioStations.length,
                    itemBuilder: (context, i) {
                      final s = kRadioStations[i];
                      final isCurrent = current?.id == s.id;
                      final isPlaying = isCurrent && _service.isPlaying;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                          title: Text(s.name),
                          subtitle: Text('${s.description}\nالمصدر: ${s.source}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(
                              _favs.contains(s.id)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            tooltip: 'المفضلة',
                            onPressed: () => _toggleFav(s.id),
                          ),
                          onTap: () => _togglePlay(s),
                        ),
                      );
                    },
                  ),
                ),
                if (current != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: const Border(top: BorderSide(color: Colors.grey)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(_service.isPlaying
                                  ? Icons.stop
                                  : Icons.play_arrow),
                              onPressed: () => _togglePlay(current),
                            ),
                            Expanded(
                              child: Text(
                                'يُشغَّل الآن: ${current.name}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_service.sleepMinutesLeft != null)
                              Chip(
                                label: Text(
                                    'إيقاف بعد ${_service.sleepMinutesLeft} د'),
                                onDeleted: () =>
                                    setState(() => _service.setSleepTimer(0)),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.volume_down, size: 20),
                            Expanded(
                              child: Slider(
                                value: _service.volume,
                                onChanged: (v) =>
                                    setState(() => _service.setVolume(v)),
                              ),
                            ),
                            const Icon(Icons.volume_up, size: 20),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            const Text('مؤقت الإيقاف:'),
                            for (final m in [15, 30, 45, 60, 90])
                              ChoiceChip(
                                label: Text('$m د'),
                                selected:
                                    _service.sleepMinutesLeft == m,
                                onSelected: (_) => setState(
                                    () => _service.setSleepTimer(m)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
