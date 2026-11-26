import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/settings_service.dart';
import 'admin/admin_home_screen.dart';
import 'admin/admin_login_screen.dart';
import 'account_screen.dart';
import 'assistant_screen.dart';
import 'hajj_screen.dart';
import 'hadith_screen.dart';
import 'hijri_screen.dart';
import 'khatma_screen.dart';
import 'kids_screen.dart';
import 'mosques_screen.dart';
import 'prayer_guide_screen.dart';
import 'radio_screen.dart';
import 'ramadan_screen.dart';
import 'settings_screen.dart';
import 'studio_screen.dart';
import 'tasbih_screen.dart';
import 'widget_setup_screen.dart';
import 'worship_screen.dart';
import 'zakat_screen.dart';

/// "More" tab: every remaining tool, each opening a real screen.
/// No dead buttons: every entry navigates somewhere that works.
/// The Admin Panel entry is shown ONLY after an admin/moderator signs in
/// (AdminService.state); otherwise it is hidden entirely.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.settings});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    final entries = <({String title, IconData icon, Widget Function() page})>[
      (title: 'إذاعات القرآن الكريم', icon: Icons.radio, page: () => const RadioScreen()),
      (title: 'الاستوديو الإسلامي', icon: Icons.photo_library, page: () => const StudioScreen()),
      (title: 'المساجد القريبة', icon: Icons.mosque, page: () => MosquesScreen(settings: settings)),
      (title: 'مكتبة الحديث النبوي', icon: Icons.library_books, page: () => const HadithScreen()),
      (title: 'دليل الصلاة والوضوء', icon: Icons.menu_book, page: () => const PrayerGuideScreen()),
      (title: 'خطة الختمة', icon: Icons.menu_book, page: () => const KhatmaScreen()),
      (title: 'دليل الحج والعمرة', icon: Icons.flight_takeoff, page: () => const HajjScreen()),
      (title: 'رفيق المسلم — المساعد', icon: Icons.chat_bubble_outline, page: () => AssistantScreen(settings: settings)),
      (title: 'تتبع العبادات', icon: Icons.track_changes, page: () => const WorshipScreen()),
      (title: 'حسابي والمزامنة', icon: Icons.account_circle, page: () => AccountScreen(settings: settings)),
      (title: 'ودجت الشاشة الرئيسية', icon: Icons.widgets, page: () => WidgetSetupScreen(settings: settings)),
      (title: 'المسبحة الإلكترونية', icon: Icons.fingerprint, page: () => const TasbihScreen()),
      (title: 'حاسبة الزكاة', icon: Icons.calculate, page: () => const ZakatScreen()),
      (title: 'التقويم الهجري', icon: Icons.calendar_month, page: () => const HijriScreen()),
      (title: 'رمضان', icon: Icons.nightlight_round, page: () => RamadanScreen(settings: settings)),
      (title: 'قسم الأطفال', icon: Icons.child_care, page: () => const KidsScreen()),
      (title: 'الإعدادات', icon: Icons.settings, page: () => SettingsScreen(settings: settings)),
    ];
    return ValueListenableBuilder<AdminState>(
      valueListenable: AdminService.instance.state,
      builder: (context, adminState, _) {
        final isStaff = adminState == AdminState.admin ||
            adminState == AdminState.moderator;
        // The admin entry is visible only to signed-in staff. When
        // Supabase is unconfigured, staff can never be signed in, so the
        // entry stays hidden and no fake admin screen is reachable.
        final all = <({String title, IconData icon, Widget Function() page})>[
          ...entries,
          if (isStaff)
            (
              title: 'لوحة تحكم الإدارة',
              icon: Icons.admin_panel_settings,
              page: () => const AdminHomeScreen(),
            ),
        ];
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: all.length,
                itemBuilder: (context, i) {
                  final e = all[i];
                  return ListTile(
                    leading: Icon(e.icon),
                    title: Text(e.title),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => e.page()),
                    ),
                  );
                },
              ),
            ),
            if (!isStaff)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton.icon(
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('دخول لوحة تحكم الإدارة'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AdminLoginScreen()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
