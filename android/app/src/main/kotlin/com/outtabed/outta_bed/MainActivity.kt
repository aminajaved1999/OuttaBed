package com.outtabed.outta_bed

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "com.outtabed.outta_bed/native"
    private var pendingPickResult: MethodChannel.Result? = null
    private var previousSpeakerphoneState: Boolean? = null
    private var launchAlarmId: String? = null

    private val pickRingtoneLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult(),
    ) { result ->
        val callback = pendingPickResult
        pendingPickResult = null
        if (callback == null) return@registerForActivityResult
        if (result.resultCode != Activity.RESULT_OK) {
            callback.success(null)
            return@registerForActivityResult
        }
        val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            result.data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            result.data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }
        if (uri == null) {
            callback.success(null)
            return@registerForActivityResult
        }
        val title = RingtoneManager.getRingtone(this, uri)?.getTitle(this) ?: "Phone sound"
        callback.success(mapOf("uri" to uri.toString(), "title" to title))
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        launchAlarmId = intent?.getStringExtra(AlarmRingService.EXTRA_ALARM_ID)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val alarmId = intent.getStringExtra(AlarmRingService.EXTRA_ALARM_ID)
        if (!alarmId.isNullOrBlank()) {
            launchAlarmId = alarmId
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, channelName).invokeMethod("onAlarmLaunched", alarmId)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchAlarmId" -> {
                        val id = launchAlarmId
                        launchAlarmId = null
                        result.success(id)
                    }
                    "scheduleAlarm" -> {
                        val alarmId = call.argument<String>("alarmId") ?: return@setMethodCallHandler result.error("arg", "missing alarmId", null)
                        val triggerAt = call.argument<Long>("triggerAt") ?: return@setMethodCallHandler result.error("arg", "missing triggerAt", null)
                        val label = call.argument<String>("label") ?: "OuttaBed"
                        val soundUri = call.argument<String>("soundUri")
                        val volume = call.argument<Double>("volume")?.toFloat() ?: 1f
                        NativeAlarmScheduler.schedule(
                            this,
                            alarmId.hashCode() and 0x7fffffff,
                            alarmId,
                            triggerAt,
                            label,
                            soundUri,
                            volume,
                        )
                        result.success(null)
                    }
                    "cancelAlarm" -> {
                        val alarmId = call.argument<String>("alarmId") ?: return@setMethodCallHandler result.error("arg", "missing alarmId", null)
                        NativeAlarmScheduler.cancel(this, alarmId.hashCode() and 0x7fffffff, alarmId)
                        result.success(null)
                    }
                    "stopNativeAlarm" -> {
                        AlarmRingService.stop(this)
                        result.success(null)
                    }
                    "startNativeVibration" -> {
                        // Vibration starts with alarm service; no-op when called standalone.
                        result.success(null)
                    }
                    "stopNativeVibration" -> {
                        result.success(null)
                    }
                    "triggerAlarmNow" -> {
                        val alarmId = call.argument<String>("alarmId") ?: return@setMethodCallHandler result.error("arg", "missing alarmId", null)
                        val label = call.argument<String>("label") ?: "OuttaBed"
                        val soundUri = call.argument<String>("soundUri")
                        val volume = call.argument<Double>("volume")?.toFloat() ?: 1f
                        AlarmRingService.start(this, alarmId, label, soundUri, volume)
                        result.success(null)
                    }
                    "pickDeviceAlarmSound" -> {
                        pendingPickResult = result
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Pick alarm sound")
                        }
                        pickRingtoneLauncher.launch(intent)
                    }
                    "getDeviceAlarmSounds" -> result.success(getDeviceAlarmSounds())
                    "isBluetoothAudioConnected" -> result.success(isBluetoothAudioConnected())
                    "routeAlarmToSpeaker" -> {
                        routeAlarmToSpeaker()
                        result.success(null)
                    }
                    "restoreAudioRouting" -> {
                        restoreAudioRouting()
                        result.success(null)
                    }
                    "openBatterySettings" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "canScheduleExactAlarms" -> {
                        result.success(canScheduleExactAlarms())
                    }
                    "requestExactAlarms" -> {
                        result.success(requestExactAlarms())
                    }
                    "openExactAlarmSettings" -> {
                        openExactAlarmSettings()
                        result.success(null)
                    }
                    "areNotificationsEnabled" -> {
                        result.success(areNotificationsEnabled())
                    }
                    "requestNotifications" -> {
                        result.success(requestNotifications())
                    }
                    "canUseFullScreenIntent" -> {
                        result.success(canUseFullScreenIntent())
                    }
                    "requestFullScreenIntent" -> {
                        result.success(requestFullScreenIntent())
                    }
                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettings()
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        result.success(requestIgnoreBatteryOptimizations())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getDeviceAlarmSounds(): List<Map<String, String>> {
        val manager = RingtoneManager(this).apply {
            setType(RingtoneManager.TYPE_ALARM)
        }
        val cursor = manager.cursor ?: return emptyList()
        val sounds = mutableListOf<Map<String, String>>()
        while (cursor.moveToNext()) {
            val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX) ?: continue
            val uri = manager.getRingtoneUri(cursor.position).toString()
            sounds.add(mapOf("title" to title, "uri" to uri))
        }
        cursor.close()
        return sounds
    }

    private fun isBluetoothAudioConnected(): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any {
                it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    it.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
            }
        }
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        return adapter.isEnabled && adapter.getProfileConnectionState(BluetoothProfile.A2DP) == BluetoothProfile.STATE_CONNECTED
    }

    private fun routeAlarmToSpeaker() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (previousSpeakerphoneState == null) {
            previousSpeakerphoneState = audioManager.isSpeakerphoneOn
        }
        audioManager.mode = AudioManager.MODE_NORMAL
        audioManager.stopBluetoothSco()
        audioManager.isBluetoothScoOn = false
        audioManager.isSpeakerphoneOn = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.availableCommunicationDevices
                .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                ?.let { audioManager.setCommunicationDevice(it) }
        }
    }

    private fun restoreAudioRouting() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        previousSpeakerphoneState?.let { audioManager.isSpeakerphoneOn = it }
        previousSpeakerphoneState = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.clearCommunicationDevice()
        }
    }

    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

    private fun requestExactAlarms(): Boolean {
        if (canScheduleExactAlarms()) return true
        openExactAlarmSettings()
        return false
    }

    private fun openExactAlarmSettings() {
        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }

    private fun areNotificationsEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotifications(): Boolean {
        if (areNotificationsEnabled()) return true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                1001,
            )
        }
        return areNotificationsEnabled()
    }

    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.canUseFullScreenIntent()
    }

    private fun requestFullScreenIntent(): Boolean {
        if (canUseFullScreenIntent()) return true
        openFullScreenIntentSettings()
        return false
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT >= 34) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return manager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations(): Boolean {
        if (isIgnoringBatteryOptimizations()) return true
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
        return false
    }
}
