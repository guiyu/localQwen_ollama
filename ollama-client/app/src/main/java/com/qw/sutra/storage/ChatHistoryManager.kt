// app/src/main/java/com/qw/sutra/storage/ChatHistoryManager.kt
package com.qw.sutra.storage

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.*

class ChatHistoryManager(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "chat_history",
        Context.MODE_PRIVATE
    )

    fun saveMessage(role: String, content: String) {
        val messages = getMessages().toMutableList()
        messages.add(
            JSONObject().apply {
                put("role", role)
                put("content", content)
                put("timestamp", System.currentTimeMillis())
            }.toString()
        )

        // 只保留最近的100条消息
        if (messages.size > 100) {
            messages.removeAt(0)
        }

        prefs.edit()
            .putString("messages", JSONArray(messages).toString())
            .apply()
    }

    private fun getMessages(): List<String> {
        val messagesStr = prefs.getString("messages", "[]")
        val messagesArray = JSONArray(messagesStr)
        return List(messagesArray.length()) { i -> messagesArray.getString(i) }
    }
}