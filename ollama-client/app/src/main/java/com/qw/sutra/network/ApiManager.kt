// app/src/main/java/com/qw/sutra/network/ApiManager.kt
package com.qw.sutra.network

import android.content.Context
import android.util.Log
import com.google.gson.Gson
import com.qw.sutra.model.ModelConfig
import com.qw.sutra.utils.NetworkUtils
import okhttp3.*
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import java.io.IOException

// app/src/main/java/com/qw/sutra/network/ApiManager.kt
class ApiManager(private val context: Context) {
    companion object {
        private const val TAG = "ApiManager"
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()

    fun startChatStream(
        prompt: String,
        modelConfig: ModelConfig = ModelConfig(),
        onResponse: (String) -> Unit,
        onComplete: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.i(TAG, "Starting chat with prompt: ${prompt.take(100)}...")

            if (!NetworkUtils.isNetworkAvailable(context)) {
                Log.e(TAG, "Network not available")
                onError("网络不可用")
                return
            }

            val json = JSONObject().apply {
                put("model", modelConfig.modelName)
                put("prompt", prompt)
                put("stream", modelConfig.stream)  // 设置stream参数
            }

            Log.d(TAG, "Request payload: $json")

            val request = Request.Builder()
                .url("http://192.3.59.148:8080/api/generate")
                .post(RequestBody.create(
                    MediaType.parse("application/json"),
                    json.toString()
                ))
                .build()

            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "Request failed", e)
                    onError("连接错误: ${e.message}")
                }

                override fun onResponse(call: Call, response: Response) {
                    try {
                        val responseBody = response.body()?.string()
                        Log.d(TAG, "Response body: $responseBody")

                        if (responseBody == null) {
                            onError("响应为空")
                            return
                        }

                        // 解析响应
                        val jsonResponse = JSONObject(responseBody)
                        val responseText = jsonResponse.optString("response", "")

                        if (responseText.isNotEmpty()) {
                            Log.i(TAG, "Received response: $responseText")
                            onResponse(responseText)
                        }

                        // 检查是否完成
                        if (jsonResponse.optBoolean("done", false)) {
                            Log.i(TAG, "Request completed")
                            onComplete()
                        }

                    } catch (e: Exception) {
                        Log.e(TAG, "Error parsing response", e)
                        onError("解析响应失败: ${e.message}")
                    }
                }
            })

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start request", e)
            onError("创建请求失败: ${e.message}")
        }
    }
}