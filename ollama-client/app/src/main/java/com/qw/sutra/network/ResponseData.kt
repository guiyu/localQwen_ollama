// app/src/main/java/com/qw/sutra/network/ResponseData.kt
package com.qw.sutra.network

data class ResponseData(
    val model: String? = null,
    val created_at: String? = null,
    val response: String? = null,
    val done: Boolean = false,
    val done_reason: String? = null,
)