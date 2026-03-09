package com.joshua.kashlog

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class KashlogWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val balance = widgetData.getString("balance", "$0.00")
                val currency = widgetData.getString("currency", "USD")
                
                setTextViewText(R.id.widget_balance, balance)
                setTextViewText(R.id.widget_currency, currency)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
