import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.widget.Toast
import java.util.Locale

// app/src/main/java/com/qw/sutra/speech/SpeechManager.kt
class SpeechManager(private val context: Context) {
    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null

    init {
        initializeTextToSpeech()
    }

    private fun initializeTextToSpeech() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status != TextToSpeech.ERROR) {
                textToSpeech?.language = Locale.CHINESE
            }
        }
    }

    fun startListening(onResult: (String) -> Unit) {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    // 准备好开始说话
                }

                override fun onBeginningOfSpeech() {
                    // 开始说话
                }

                override fun onRmsChanged(rmsdB: Float) {
                    // 音量变化
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    // 接收到语音数据
                }

                override fun onEndOfSpeech() {
                    // 说话结束
                }

                override fun onError(error: Int) {
                    // 处理错误
                    val errorMessage = when (error) {
                        SpeechRecognizer.ERROR_AUDIO -> "音频录制错误"
                        SpeechRecognizer.ERROR_CLIENT -> "客户端错误"
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "权限不足"
                        SpeechRecognizer.ERROR_NETWORK -> "网络错误"
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "网络超时"
                        SpeechRecognizer.ERROR_NO_MATCH -> "未能匹配语音"
                        SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "识别服务忙"
                        SpeechRecognizer.ERROR_SERVER -> "服务器错误"
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "语音超时"
                        else -> "未知错误"
                    }
                    // 可以在这里处理错误，比如通知用户
                    Toast.makeText(context, errorMessage, Toast.LENGTH_SHORT).show()
                }

                override fun onResults(results: Bundle?) {
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    matches?.firstOrNull()?.let(onResult)
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    // 部分识别结果
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    // 其他事件
                }
            })

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, "zh-CN")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            }

            startListening(intent)
        }
    }

    fun speak(text: String) {
        @Suppress("DEPRECATION")
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null)
    }

    fun release() {
        speechRecognizer?.destroy()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
    }
}