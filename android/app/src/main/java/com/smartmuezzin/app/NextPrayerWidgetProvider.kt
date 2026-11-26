package com.smartmuezzin.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: "الصلاة القادمة" (next prayer).
 *
 * Data is pushed from Dart by WidgetService (home_widget package) into
 * the widget's SharedPreferences; this provider only renders it.
 * Registered in AndroidManifest.xml; metadata in
 * res/xml/next_prayer_widget_info.xml; layout in
 * res/layout/next_prayer_widget.xml.
 *
 * HONEST LIMIT: there is no lock-screen widget — Android 12+ removed
 * lock-screen widgets from the OS. On the lock screen only a
 * notification can appear (prayer reminders), never a live widget.
 */
class NextPrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.next_prayer_widget)
            views.setTextViewText(
                R.id.widget_prayer_name,
                widgetData.getString("next_prayer_name", "الصلاة القادمة") ?: "الصلاة القادمة"
            )
            views.setTextViewText(
                R.id.widget_prayer_time,
                widgetData.getString("next_prayer_time", "--:--") ?: "--:--"
            )
            views.setTextViewText(
                R.id.widget_countdown,
                widgetData.getString("next_prayer_countdown", "") ?: ""
            )
            views.setTextViewText(
                R.id.widget_city,
                widgetData.getString("city_name", "") ?: ""
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
