// app/src/main/java/com/qw/sutra/speech/SpeechManager.kt
package com.qw.sutra.speech

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale
import java.util.UUID

class SpeechManager(private val context: Context) {
    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var isListening = false

    interface SpeechCallback {
        fun onListeningStart()
        fun onRmsChanged(rmsdB: Float)
        fun onResult(text: String)
        fun onError(errorMessage: String)
        fun onReadyForSpeech()
    }

    init {
        initializeTextToSpeech()
    }

    private fun initializeTextToSpeech() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status != TextToSpeech.ERROR) {
                textToSpeech?.language = Locale.CHINESE
                textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {}
                    override fun onError(utteranceId: String?) {}
                })
            }
        }
    }

    fun startListening(callback: SpeechCallback) {
        if (isListening) return

        isListening = true
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context).apply {
            setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    callback.onReadyForSpeech()
                }

                override fun onBeginningOfSpeech() {
                    callback.onListeningStart()
                }

                override fun onRmsChanged(rmsdB: Float) {
                    callback.onRmsChanged(rmsdB)
                }

                override fun onBufferReceived(buffer: ByteArray?) {}

                override fun onEndOfSpeech() {
                    isListening = false
                }

                override fun onError(error: Int) {
                    isListening = false
                    val errorMessage = getErrorMessage(error)
                    callback.onError(errorMessage)
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    matches?.firstOrNull()?.let { callback.onResult(it) }
                }

                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
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

    fun speak(text: String, onComplete: (() -> Unit)? = null) {
        val utteranceId = UUID.randomUUID().toString()
        textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) {
                onComplete?.invoke()
            }
            override fun onError(utteranceId: String?) {
                onComplete?.invoke()
            }
        })

        val params = HashMap<String, String>().apply {
            put(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
        }
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, params)
    }

    private fun getErrorMessage(error: Int): String = when (error) {
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

    fun release() {
        isListening = false
        speechRecognizer?.destroy()
        textToSpeech?.stop()
        textToSpeech?.shutdown()
    }
}