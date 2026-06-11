package com.example.dailylogr

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_widget_layout)

            // 1. Get data from shared preferences
            val hasEntry = widgetData.getBoolean("has_entry", false)
            val dateText = widgetData.getString("date_text", "") ?: ""
            val streakCount = getSafeInt(widgetData, "streak_count", 0)

            // 2. Bind Date and Streak text
            views.setTextViewText(R.id.widget_date_text, dateText)
            views.setTextViewText(R.id.widget_streak_text, "🔥 $streakCount day${if (streakCount == 1) "" else "s"}")

            // 3. Bind view based on whether today's entry has been written
            if (hasEntry) {
                views.setViewVisibility(R.id.widget_prompt_layout, View.GONE)
                views.setViewVisibility(R.id.widget_entry_layout, View.VISIBLE)

                // Get entry details
                val title = widgetData.getString("entry_title", "") ?: ""
                val note = widgetData.getString("entry_note", "") ?: ""
                val adjective = widgetData.getString("entry_adjective", "") ?: ""
                val rating = getSafeInt(widgetData, "entry_rating", 0)
                val colorInt = getSafeInt(widgetData, "entry_color", 0)

                // Title and note
                views.setTextViewText(R.id.widget_entry_title, if (title.trim().isEmpty()) "Untitled Entry" else title)
                views.setTextViewText(R.id.widget_entry_note, note)

                // Adjective chip
                if (adjective.trim().isEmpty()) {
                    views.setViewVisibility(R.id.widget_entry_adjective, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_entry_adjective, View.VISIBLE)
                    views.setTextViewText(R.id.widget_entry_adjective, adjective)
                }

                // Rating stars
                if (rating <= 0) {
                    views.setViewVisibility(R.id.widget_entry_rating, View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_entry_rating, View.VISIBLE)
                    val stars = "★".repeat(rating) + "☆".repeat((5 - rating).coerceAtLeast(0))
                    views.setTextViewText(R.id.widget_entry_rating, stars)
                }

                // Dynamic background color tinting
                if (colorInt != 0) {
                    // Blend entryColor with white to create a soft pastel tint
                    val blendedColor = blendWithWhite(colorInt, 0.82f)
                    views.setColorStateList(R.id.widget_background_image, "setImageTintList", ColorStateList.valueOf(blendedColor))
                } else {
                    // Default background tint (White)
                    views.setColorStateList(R.id.widget_background_image, "setImageTintList", ColorStateList.valueOf(0xFFFFFFFF.toInt()))
                }
            } else {
                views.setViewVisibility(R.id.widget_prompt_layout, View.VISIBLE)
                views.setViewVisibility(R.id.widget_entry_layout, View.GONE)
                // Use default background tint (Soft blue prompt color)
                views.setColorStateList(R.id.widget_background_image, "setImageTintList", ColorStateList.valueOf(0xFFE3F2FD.toInt()))
            }

            // 4. Intent to launch the application when widget is clicked
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getSafeInt(widgetData: SharedPreferences, key: String, defaultValue: Int): Int {
        val value = widgetData.all[key] ?: return defaultValue
        return when (value) {
            is Number -> value.toInt()
            is String -> value.toIntOrNull() ?: defaultValue
            else -> defaultValue
        }
    }

    private fun blendWithWhite(color: Int, ratio: Float): Int {
        val a = (color shr 24 and 0xFF)
        val r = (color shr 16 and 0xFF)
        val g = (color shr 8 and 0xFF)
        val b = (color and 0xFF)

        val blendedR = (r + (255 - r) * ratio).toInt().coerceIn(0, 255)
        val blendedG = (g + (255 - g) * ratio).toInt().coerceIn(0, 255)
        val blendedB = (b + (255 - b) * ratio).toInt().coerceIn(0, 255)
        
        val blendedA = if (a == 0) 255 else a

        return (blendedA shl 24) or (blendedR shl 16) or (blendedG shl 8) or blendedB
    }
}
