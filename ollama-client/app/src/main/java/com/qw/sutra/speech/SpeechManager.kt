// app/src/main/java/com/qw/sutra/speech/SpeechManager.kt
package com.qw.sutra.speech

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import android.widget.Toast
import androidx.core.content.ContextCompat
import com.qw.sutra.utils.NetworkUtils
import java.util.Locale
import java.util.UUID

class SpeechManager(private val context: Context) {
    companion object {
        private const val TAG = "SpeechManager"
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var isListening = false

    init {
        Log.d(TAG, "Initializing SpeechManager")
        initializeTextToSpeech()
    }

    private fun initializeTextToSpeech() {
        Log.d(TAG, "Initializing TextToSpeech")
        textToSpeech = TextToSpeech(context) { status ->
            val statusText = when (status) {
                TextToSpeech.SUCCESS -> "SUCCESS"
                TextToSpeech.ERROR -> "ERROR"
                else -> "UNKNOWN($status)"
            }
            Log.d(TAG, "TextToSpeech initialization status: $statusText")

            if (status != TextToSpeech.ERROR) {
                textToSpeech?.let { tts ->
                    tts.language = Locale.CHINESE
                    Log.d(TAG, "TextToSpeech language set to: ${tts.language}")
                    Log.d(TAG, "TextToSpeech available languages: ${tts.availableLanguages}")
                }
            }
        }
    }

    fun startListening(callback: RecognitionListener) {
        Log.i(TAG, "Starting speech recognition")

        // 检查网络状态
        if (!NetworkUtils.isNetworkAvailable(context)) {
            Log.e(TAG, "Network is not available")
            callback.onError(SpeechRecognizer.ERROR_NETWORK)
            return
        }

        if (isListening) {
            Log.w(TAG, "Speech recognition is already active")
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.e(TAG, "Speech recognition is not available on this device")
            Toast.makeText(context, "语音识别不可用", Toast.LENGTH_SHORT).show()
            return
        }

        isListening = true
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            Log.d(TAG, "Created new SpeechRecognizer instance")

            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    Log.d(TAG, "onReadyForSpeech: $params")
                    callback.onReadyForSpeech(params)
                }

                override fun onBeginningOfSpeech() {
                    Log.d(TAG, "onBeginningOfSpeech")
                    callback.onBeginningOfSpeech()
                }

                override fun onRmsChanged(rmsdB: Float) {
                    Log.v(TAG, "onRmsChanged: $rmsdB")
                    callback.onRmsChanged(rmsdB)
                }

                override fun onBufferReceived(buffer: ByteArray?) {
                    Log.v(TAG, "onBufferReceived: ${buffer?.size ?: 0} bytes")
                    callback.onBufferReceived(buffer)
                }

                override fun onEndOfSpeech() {
                    Log.d(TAG, "onEndOfSpeech")
                    isListening = false
                    callback.onEndOfSpeech()
                }

                override fun onError(error: Int) {
                    isListening = false
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
                        else -> "未知错误($error)"
                    }
                    Log.e(TAG, "onError: $errorMessage (code: $error)")
                    callback.onError(error)
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    Log.i(TAG, "onResults: matches=${matches?.size}, first match: ${matches?.firstOrNull()}")
                    callback.onResults(results)
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    Log.d(TAG, "onPartialResults: matches=${matches?.size}, first match: ${matches?.firstOrNull()}")
                    callback.onPartialResults(partialResults)
                }

                override fun onEvent(eventType: Int, params: Bundle?) {
                    Log.d(TAG, "onEvent: type=$eventType, params=$params")
                    callback.onEvent(eventType, params)
                }
            })

            try {
                val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                        RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, "zh-CN")
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    // 添加更多详细参数
                    putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, context.packageName)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 1000L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 1000L)
                    putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 500L)
                }
                Log.d(TAG, "Starting speech recognition with intent: $intent")
                startListening(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error starting speech recognition", e)
                isListening = false
                Toast.makeText(context, "启动语音识别失败: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    fun speak(text: String, onComplete: (() -> Unit)? = null) {
        Log.i(TAG, "Speaking text: ${text.take(100)}${if (text.length > 100) "..." else ""}")

        textToSpeech?.let { tts ->
            // 检查TTS状态
            if (tts.isSpeaking) {
                Log.d(TAG, "TTS is currently speaking, stopping...")
                tts.stop()
            }

            val utteranceId = UUID.randomUUID().toString()
            val result = tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)

            if (result == TextToSpeech.SUCCESS) {
                Log.d(TAG, "TTS speak command successful, utteranceId: $utteranceId")
            } else {
                Log.e(TAG, "TTS speak command failed with result: $result")
            }
        } ?: run {
            Log.e(TAG, "TTS not initialized")
            Toast.makeText(context, "TTS未初始化", Toast.LENGTH_SHORT).show()
        }
    }

    fun release() {
        Log.i(TAG, "Releasing SpeechManager resources")
        isListening = false
        try {
            speechRecognizer?.let {
                Log.d(TAG, "Destroying SpeechRecognizer")
                it.destroy()
                speechRecognizer = null
            }
            textToSpeech?.let {
                Log.d(TAG, "Shutting down TextToSpeech")
                it.stop()
                it.shutdown()
                textToSpeech = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during resource release", e)
        }
    }

    // 检查权限状态
    fun checkPermissions(): Boolean {
        val audioPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        Log.i(TAG, "Audio permission status: $audioPermission")
        return audioPermission
    }
}