// app/src/main/java/com/qw/sutra/speech/SpeechManager.kt
package com.qw.sutra.speech

import android.content.Context
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import android.os.Bundle
import java.util.*

class SpeechManager(private val context: Context) {
    companion object {
        private const val TAG = "SpeechManager"
        private const val STATE_START = 0
        private const val STATE_READY = 1
        private const val STATE_DONE = 2
        private const val STATE_MIC = 3
    }

    private var textToSpeech: TextToSpeech? = null
    private val voskWrapper = VoskWrapper(context)
    private var currentState = STATE_START

    init {
        initializeTextToSpeech()
        initializeVosk()
    }

    private fun initializeTextToSpeech() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = textToSpeech?.setLanguage(Locale.CHINESE)
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    Log.e(TAG, "Chinese language not supported")
                }
            } else {
                Log.e(TAG, "TextToSpeech initialization failed")
            }
        }
    }

    private fun initializeVosk() {
        Log.i(TAG, "Starting Vosk initialization...")
        try {
            voskWrapper.initModel(
                onSuccess = {
                    Log.i(TAG, "Vosk model initialized successfully")
                    currentState = STATE_READY
                },
                onError = { error ->
                    Log.e(TAG, "Vosk initialization failed: $error")
                    // 重试逻辑
                    retryInitialization()
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error during Vosk initialization", e)
            retryInitialization()
        }
    }

    private fun retryInitialization() {
        Log.i(TAG, "Retrying Vosk initialization...")
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            initializeVosk()
        }, 3000) // 3秒后重试
    }

    fun startListening(callback: RecognitionListener) {
        Log.i(TAG, "==== Starting speech recognition ====")

        if (currentState != STATE_READY) {
            Log.e(TAG, "Not ready to start listening, current state: $currentState")
            callback.onError(SpeechRecognizer.ERROR_CLIENT)
            return
        }

        currentState = STATE_MIC

        voskWrapper.startListening(object : org.vosk.android.RecognitionListener {
            override fun onResult(hypothesis: String) {
                Log.i(TAG, "Vosk result: $hypothesis")
                callback.onResults(Bundle().apply {
                    putStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION,
                        arrayListOf(hypothesis))
                })
            }

            override fun onFinalResult(hypothesis: String) {
                Log.i(TAG, "Vosk final result: $hypothesis")
                callback.onResults(Bundle().apply {
                    putStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION,
                        arrayListOf(hypothesis))
                })
                currentState = STATE_DONE
            }

            override fun onPartialResult(hypothesis: String) {
                Log.d(TAG, "Vosk partial result: $hypothesis")
                callback.onPartialResults(Bundle().apply {
                    putStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION,
                        arrayListOf(hypothesis))
                })
            }

            override fun onError(exception: Exception) {
                Log.e(TAG, "Vosk error", exception)
                callback.onError(SpeechRecognizer.ERROR_CLIENT)
                currentState = STATE_DONE
            }

            override fun onTimeout() {
                Log.w(TAG, "Vosk timeout")
                callback.onError(SpeechRecognizer.ERROR_SPEECH_TIMEOUT)
                currentState = STATE_DONE
            }
        })

        callback.onReadyForSpeech(Bundle())
    }

    fun stopListening() {
        if (currentState == STATE_MIC) {
            voskWrapper.stop()
            currentState = STATE_DONE
        }
    }

    fun speak(text: String) {
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
    }

    fun release() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        voskWrapper.release()
        currentState = STATE_START
    }
}