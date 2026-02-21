package com.ccextractor.uac_companion

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BootBroadcastReceiver listens for device boot completion.
 * When the device restarts, all pending alarms are cleared by the Android system.
 * This receiver reschedules all active alarms from the database.
 */
class BootBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootBroadcastReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed. Rescheduling alarms...")
            
            try {
                // Get all enabled alarms from the database
                val alarms = AlarmUtils.getAllAlarmsFromDb(context)
                val enabledAlarms = alarms.filter { it.isEnabled == 1 }
                
                Log.d(TAG, "Found ${enabledAlarms.size} enabled alarms to reschedule")
                
                // Reschedule each alarm using the AlarmScheduler
                // The scheduler will automatically pick the next upcoming alarm
                if (enabledAlarms.isNotEmpty()) {
                    AlarmScheduler.scheduleNextAlarm(context)
                    Log.d(TAG, "Successfully rescheduled alarms after boot")
                } else {
                    Log.d(TAG, "No active alarms to reschedule")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error rescheduling alarms after boot: ${e.message}", e)
            }
        }
    }
}
