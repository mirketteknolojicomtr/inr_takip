package com.mirketteknoloji.inrtakip

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle

/** `home_widget` paketinin yazdığı SharedPreferences dosyası (bkz.
 * HomeWidgetPlugin.PREFERENCES — o sınıfın kendi paketi bozuk olduğu için
 * (package bildirimi eksik) buradan import edilemiyor, adı sabit metin
 * olarak tekrarlanıyor). */
private const val HOME_WIDGET_PREFS = "HomeWidgetPreferences"

private val backgroundColor = ColorProvider(day = Color(0xFF0B1F1B), night = Color(0xFF0B1F1B))
private val headlineColor = ColorProvider(day = Color.White, night = Color.White)
private val nameColor = ColorProvider(day = Color(0xFFB2DFDB), night = Color(0xFFB2DFDB))
private val medicationColor = ColorProvider(day = Color(0xFF80CBC4), night = Color(0xFF80CBC4))

/**
 * Ana ekran acil durum widget'ının içeriği. [LockScreenSyncService] (Dart
 * tarafı) her yeni INR kaydında `home_widget` paketiyle SharedPreferences'a
 * yazıp bu widget'ın timeline'ını tazeler — burada periyodik polling yok,
 * yalnızca dışarıdan tetiklenen tek seferlik render.
 */
class InrEmergencyGlanceWidgetContent : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences(HOME_WIDGET_PREFS, Context.MODE_PRIVATE)
        val headline = prefs.getString("headline", null) ?: "INR kaydı yok"
        val patientName = prefs.getString("patientName", null) ?: ""
        val medication = prefs.getString("medication", null) ?: ""

        provideContent {

            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(backgroundColor)
                    .padding(12.dp),
            ) {
                Text(
                    headline,
                    style = TextStyle(
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = headlineColor,
                    ),
                )
                Text(
                    patientName,
                    style = TextStyle(fontSize = 13.sp, color = nameColor),
                )
                if (medication.isNotEmpty()) {
                    Text(
                        medication,
                        style = TextStyle(fontSize = 12.sp, color = medicationColor),
                    )
                }
            }
        }
    }
}

/**
 * Receiver sınıfının adı KASITLI olarak "InrEmergencyGlanceWidget" —
 * `HomeWidgetLockScreenGateway.publish()` (Dart) `androidName` olarak bunu
 * gönderiyor ve `home_widget` paketi
 * `Class.forName("$packageName.$androidName")` ile bu sınıfı reflection'la
 * buluyor. İsim eşleşmezse widget hiç güncellenmez.
 */
class InrEmergencyGlanceWidget : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = InrEmergencyGlanceWidgetContent()
}
