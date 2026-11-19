package com.hatimmatik.app
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HatimWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            val data = HomeWidgetPlugin.getData(context)
            val streak = data.getInt("streak", 0)
            val page = data.getInt("page", 1)
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.widget_streak, "$streak")
            views.setTextViewText(R.id.widget_page, "Sayfa: $page")
            manager.updateAppWidget(id, views)
        }
    }
}