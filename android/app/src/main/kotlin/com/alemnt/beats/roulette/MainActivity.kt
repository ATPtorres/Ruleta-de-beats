package com.alemnt.beats.roulette

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        TimerAlarm.channel(this)
    }

    override fun onResume() {
        super.onResume()
        TimerAlarm.foreground = true
    }

    override fun onPause() {
        TimerAlarm.foreground = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "beat_roulette/android")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "deadline" -> result.success(TimerAlarm.deadline(this))
                        "status" -> result.success(mapOf(
                            "notifications" to getSystemService(NotificationManager::class.java).areNotificationsEnabled(),
                            "exact" to TimerAlarm.exact(this)
                        ))
                        "notifications" -> {
                            if (Build.VERSION.SDK_INT >= 33 &&
                                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                            ) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 39)
                            else startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                            result.success(null)
                        }
                        "exactSettings" -> {
                            if (Build.VERSION.SDK_INT >= 31) startActivity(
                                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName"))
                            )
                            result.success(null)
                        }
                        "start" -> {
                            TimerAlarm.start(this, requireNotNull(call.argument<Number>("deadline")).toLong())
                            result.success(null)
                        }
                        "cancel" -> {
                            TimerAlarm.cancel(this)
                            result.success(null)
                        }
                        "finish" -> {
                            TimerAlarm.finish(this, foreground = true)
                            result.success(null)
                        }
                        "screen" -> {
                            if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            result.success(null)
                        }
                        "savePng" -> {
                            val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                            val name = "Beat-Roulette-${System.currentTimeMillis()}.png"
                            Thread {
                                try {
                                    savePng(bytes, name)
                                    runOnUiThread { result.success(name) }
                                } catch (e: Exception) {
                                    runOnUiThread { result.error("export", e.message, null) }
                                }
                            }.start()
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("android", e.message, null)
                }
            }
    }

    private fun savePng(bytes: ByteArray, name: String) {
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Beat Roulette")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Android no pudo crear el archivo.")
        try {
            val stream = resolver.openOutputStream(uri) ?: throw IOException("No se pudo abrir la imagen.")
            stream.use { it.write(bytes) }
            resolver.update(uri, ContentValues().apply {
                put(MediaStore.Images.Media.IS_PENDING, 0)
            }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }
}

class TimerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        TimerAlarm.finish(context, foreground = TimerAlarm.foreground)
    }
}

private object TimerAlarm {
    private const val channelId = "beat_timer_v1"
    private const val timerId = 426
    var foreground = false

    private fun prefs(context: Context) =
        context.getSharedPreferences("beat_alarm", Context.MODE_PRIVATE)

    fun deadline(context: Context): Long = prefs(context).getLong("deadline", 0L)

    private fun alarm(context: Context) = context.getSystemService(AlarmManager::class.java)
    fun exact(context: Context): Boolean =
        Build.VERSION.SDK_INT < 31 || alarm(context).canScheduleExactAlarms()

    private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context, timerId, Intent(context, TimerReceiver::class.java),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    fun start(context: Context, deadline: Long) {
        val manager = alarm(context)
        val operation = pending(context)
        if (exact(context)) {
            try {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, deadline, operation)
            } catch (_: SecurityException) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, deadline, operation)
            }
        } else {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, deadline, operation)
        }
        prefs(context).edit().putLong("deadline", deadline).commit()
    }

    fun cancel(context: Context) {
        alarm(context).cancel(pending(context))
        prefs(context).edit().remove("deadline").commit()
    }

    fun channel(context: Context) {
        val channel = NotificationChannel(channelId, "Fin de sesión", NotificationManager.IMPORTANCE_HIGH)
        channel.description = "Aviso cuando termina el temporizador de producción"
        channel.enableVibration(true)
        channel.setSound(
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build()
        )
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    fun finish(context: Context, foreground: Boolean) {
        val due = deadline(context)
        if (due <= 0 || System.currentTimeMillis() < due) return
        cancel(context)
        val manager = context.getSystemService(NotificationManager::class.java)
        channel(context)
        if (manager.areNotificationsEnabled()) {
            val open = PendingIntent.getActivity(
                context, timerId, Intent(context, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            manager.notify(timerId, Notification.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("Tiempo cumplido")
                .setContentText("Guarda tu beat y anota lo que funcionó.")
                .setContentIntent(open)
                .setAutoCancel(true)
                .build())
        } else if (foreground) {
            @Suppress("DEPRECATION")
            val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            vibrator.vibrate(VibrationEffect.createOneShot(320, VibrationEffect.DEFAULT_AMPLITUDE))
            val tone = runCatching { ToneGenerator(AudioManager.STREAM_NOTIFICATION, 75) }.getOrNull()
            tone?.startTone(ToneGenerator.TONE_PROP_ACK, 450)
            if (tone != null) android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ tone.release() }, 700)
        }
    }
}
