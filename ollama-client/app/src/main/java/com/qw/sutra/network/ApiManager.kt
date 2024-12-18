// app/src/main/java/com/qw/sutra/network/ApiManager.kt
package com.qw.sutra.network

import com.qw.sutra.model.ModelConfig
import okhttp3.*
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit
import okhttp3.sse.EventSource
import okhttp3.sse.EventSourceListener
import okhttp3.sse.EventSources

class ApiManager {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()

    private val factory: EventSource.Factory = EventSources.createFactory(client)
    private var currentEventSource: EventSource? = null

    fun startChatStream(
        prompt: String,
        modelConfig: ModelConfig = ModelConfig(),
        onResponse: (String) -> Unit,
        onComplete: () -> Unit,
        onError: (String) -> Unit
    ) {
        // 取消之前的请求（如果有）
        currentEventSource?.cancel()

        val json = JSONObject().apply {
            put("model", modelConfig.modelName)
            put("prompt", prompt)
            put("stream", true)  // 启用流式响应
        }

        val request = Request.Builder()
            .url("http://192.3.59.148:8080/api/generate")
            .post(
                RequestBody.create(
                    MediaType.parse("application/json"),
                    json.toString()
                )
            )
            .build()

        val listener = object : EventSourceListener() {
            private val responseBuilder = StringBuilder()

            override fun onOpen(eventSource: EventSource, response: Response) {
                // 连接建立成功
            }

            override fun onEvent(eventSource: EventSource, id: String?, type: String?, data: String) {
                try {
                    val jsonResponse = JSONObject(data)
                    val response = jsonResponse.optString("response", "")
                    val done = jsonResponse.optBoolean("done", false)

                    if (response.isNotEmpty()) {
                        responseBuilder.append(response)
                        onResponse(response)
                    }

                    if (done) {
                        onComplete()
                        eventSource.cancel()
                    }
                } catch (e: Exception) {
                    onError("解析响应失败: ${e.message}")
                }
            }

            override fun onClosed(eventSource: EventSource) {
                // 连接正常关闭
                onComplete()
            }

            override fun onFailure(eventSource: EventSource, t: Throwable?, response: Response?) {
                val errorMessage = when {
                    t != null -> "连接错误: ${t.message}"
                    response != null -> "服务器响应错误: ${response.code()}"
                    else -> "未知错误"
                }
                onError(errorMessage)
            }
        }

        try {
            currentEventSource = factory.newEventSource(request, listener)
        } catch (e: Exception) {
            onError("创建连接失败: ${e.message}")
        }
    }

    // 用于取消当前的流式请求
    fun cancelCurrentStream() {
        currentEventSource?.cancel()
        currentEventSource = null
    }
}