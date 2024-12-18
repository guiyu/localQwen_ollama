import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

// app/src/main/java/com/qw/sutra/network/ApiManager.kt
class ApiManager {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    fun sendPrompt(prompt: String, callback: (String) -> Unit) {
        val json = JSONObject().apply {
            put("model", "llama3-chinese")
            put("prompt", prompt)
        }

        val request = Request.Builder()
            .url("http://192.3.59.148:8080/api/generate")
            .post(
                RequestBody.create(
                MediaType.parse("application/json"),
                json.toString()
            ))
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val responseText = response.body()?.string() ?: ""
                try {
                    val responseJson = JSONObject(responseText)
                    callback(responseJson.optString("response", ""))
                } catch (e: Exception) {
                    callback("抱歉，我理解不了服务器的响应")
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                callback("网络连接失败，请检查网络后重试")
            }
        })
    }
}