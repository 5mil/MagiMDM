package com.zigmdm.agent

import java.util.Calendar

object Schedule {
    /** Local weekday 0=Sun. */
    fun pickMode(now: Calendar = Calendar.getInstance()): String {
        val dow = now.get(Calendar.DAY_OF_WEEK) - 1
        val minutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val weekday = dow in 1..5
        return when {
            weekday && minutes in (8 * 60) until (15 * 60) -> "SchoolDay"
            weekday && minutes in (15 * 60) until (20 * 60) -> "AfterHours"
            dow == 0 || dow == 6 -> "Weekend"
            else -> "AfterHours"
        }
    }
}
