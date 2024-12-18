// app/src/main/java/com/qw/sutra/network/ApiManager.kt
package com.qw.sutra.network

import android.util.Log
import com.qw.sutra.App
import com.qw.sutra.model.ModelConfig
import com.qw.sutra.utils.NetworkUtils
import okhttp3.*
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import okhttp3.sse.EventSource
import okhttp3.sse.EventSourceListener
import okhttp3.sse.EventSources
import java.io.File
import java.io.IOException

class ApiManager {
    companion object {
        private const val TAG = "ApiManager"
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .apply {
            val cacheDir = File(App.instance.cacheDir, "http_cache")
            val cacheSize = 10 * 1024 * 1024L
            cache(Cache(cacheDir, cacheSize))

            // 添加日志拦截器
            addInterceptor { chain ->
                val request = chain.request()
                Log.d(TAG, "Network Request - ${request.method()} ${request.url()}")
                Log.d(TAG, "Headers: ${request.headers()}")
                if (request.body() != null) {
                    Log.d(TAG, "Request Body: ${request.body()}")
                }

                val response = chain.proceed(request)
                Log.d(TAG, "Network Response - Code: ${response.code()} for ${response.request().url()}")
                response
            }
        }
        .build()

    private val factory: EventSource.Factory by lazy {
        Log.d(TAG, "Creating EventSource factory")
        EventSources.createFactory(client)
    }

    private var currentEventSource: EventSource? = null
    private val responseBuilder = StringBuilder()

    fun startChatStream(
        prompt: String,
        modelConfig: ModelConfig = ModelConfig(),
        onResponse: (String) -> Unit,
        onComplete: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.i(TAG, "Starting chat stream with prompt: ${prompt.take(100)}...")

            if (!NetworkUtils.isNetworkAvailable(App.instance)) {
                Log.e(TAG, "Network not available")
                onError("网络不可用")
                return
            }

            currentEventSource?.let {
                Log.d(TAG, "Cancelling existing request")
                it.cancel()
            }

            val json = JSONObject().apply {
                put("model", modelConfig.modelName)
                put("prompt", prompt)
                put("stream", true)
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

            // 使用普通的 OkHttp 请求而不是 SSE
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "Request failed", e)
                    onError("连接错误: ${e.message}")
                }

                override fun onResponse(call: Call, response: Response) {
                    Log.i(TAG, "Got response: ${response.code()}")

                    try {
                        response.body()?.let { body ->
                            // 获取输入流
                            body.source().use { source ->
                                while (!source.exhausted()) {
                                    // 读取每一行数据
                                    val line = source.readUtf8Line()
                                    if (line == null || line.isEmpty()) continue

                                    Log.v(TAG, "Received line: $line")

                                    try {
                                        val jsonResponse = JSONObject(line)
                                        val responseText = jsonResponse.optString("response", "")
                                        val done = jsonResponse.optBoolean("done", false)

                                        if (responseText.isNotEmpty()) {
                                            responseBuilder.append(responseText)
                                            onResponse(responseText)
                                        }

                                        if (done) {
                                            Log.i(TAG, "Stream completed")
                                            onComplete()
                                            break
                                        }
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error parsing response", e)
                                        onError("解析响应失败: ${e.message}")
                                        break
                                    }
                                }
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error reading response", e)
                        onError("读取响应失败: ${e.message}")
                    } finally {
                        response.close()
                    }
                }
            })

            Log.i(TAG, "Request sent successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start stream", e)
            onError("创建连接失败: ${e.message}")
        }
    }

    fun cancelCurrentStream() {
        currentEventSource?.let {
            Log.i(TAG, "Manually cancelling current stream")
            it.cancel()
            currentEventSource = null
            Log.d(TAG, "Stream cancelled and reference cleared")
        }
    }
}