package com.priyanshu.dime_money

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DimeLargeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val currency = widgetData.getString("currency", "$") ?: "$"
        val balance = widgetData.getString("balance", "0.00") ?: "0.00"
        val todayExpense = widgetData.getString("today_expense", "0.00") ?: "0.00"
        val todayIncome = widgetData.getString("today_income", "0.00") ?: "0.00"
        val weekExpense = widgetData.getString("week_expense", "0.00") ?: "0.00"
        val monthExpense = widgetData.getString("month_expense", "0.00") ?: "0.00"

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_large)
            views.setTextViewText(R.id.widget_balance, "$currency$balance")
            views.setTextViewText(
                R.id.widget_today,
                "Today: ↗$currency$todayIncome  ↙$currency$todayExpense"
            )
            views.setTextViewText(R.id.widget_week, "This Week\n$currency$weekExpense")
            views.setTextViewText(R.id.widget_month, "This Month\n$currency$monthExpense")

            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
