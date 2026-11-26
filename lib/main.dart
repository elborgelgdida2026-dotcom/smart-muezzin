import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';
import 'services/admin_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/widget_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/qibla_screen.dart';
import 'screens/azkar_screen.dart';
import 'screens/more_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hijri month names in Arabic throughout the app.
  HijriCalendar.setLocal('ar');
  // Optional: load SUPABASE_URL / SUPABASE_ANON_KEY from `.env`.
  // Missing file is fine — the app works fully without Supabase and the
  // admin panel shows setup instructions instead of fake data.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env asset: fall back to --dart-define values (see AdminService).
  }
  final settings = SettingsService();
  await settings.init();
  final notifications = NotificationService();
  await notifications.init();
  // Pre-warm the admin backend state (no-op when Supabase is unconfigured).
  await AdminService.instance.ensureInitialized();
  // Push the current next-prayer data to the home-screen widget
  // (best effort — widget failure never blocks startup).
  try {
    await WidgetService.updateNow(settings);
  } catch (_) {
    // No widget installed / package unavailable: ignore silently.
  }
  runApp(
    ChangeNotifierProvider<SettingsNotifier>(
      create: (_) => SettingsNotifier(settings),
      child: SmartMuezzinApp(settings: settings),
    ),
  );
}

/// Notifier so theme / language changes rebuild the app.
class SettingsNotifier extends ChangeNotifier {
  SettingsNotifier(this.settings);
  final SettingsService settings;

  Future<void> setDark(bool v) async {
    await settings.setDark(v);
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    await settings.setLanguage(v);
    notifyListeners();
  }
}

class SmartMuezzinApp extends StatelessWidget {
  const SmartMuezzinApp({super.key, required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SettingsNotifier>();
    final isDark = notifier.settings.isDark;
    final lang = notifier.settings.language;
    return MaterialApp(
      title: 'المؤذن الذكي',
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        // RTL is the default for Arabic; scale text for elderly users.
        final scale = settings.fontScale;
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection:
                lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: MainShell(settings: settings),
    );
  }
}

/// 5-tab bottom navigation, exactly as specified:
/// الرئيسية، القرآن الكريم، القبلة، الأذكار، المزيد.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.settings});
  final SettingsService settings;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(settings: widget.settings),
      QuranScreen(settings: widget.settings),
      QiblaScreen(settings: widget.settings),
      const AzkarScreen(),
      MoreScreen(settings: widget.settings),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/smart-muezzin-logo.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('المؤذن الذكي'),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'القرآن الكريم'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'القبلة'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'الأذكار'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}
