package com.zigmdm.agent

/**
 * Next hardening: become default SMS app (SmsApplication) so outgoing SMS
 * can be allowlisted and bodies archived when policy.logging=sms_body.
 * Incoming already hits SmsLogReceiver when the broadcast is delivered.
 */
object SmsGateStub {
    const val ROLE = "android.app.role.SMS"
}
