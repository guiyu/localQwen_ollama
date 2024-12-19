// app/src/main/java/com/qw/sutra/speech/VoskWrapper.kt
package com.qw.sutra.speech

import android.content.Context
import android.util.Log
import org.vosk.LibVosk
import org.vosk.LogLevel
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.SpeechService
import org.vosk.android.StorageService
import java.io.File

class VoskWrapper(private val context: Context) {
    companion object {
        private const val TAG = "VoskWrapper"
        private const val MODEL_NAME = "model-cn"
    }

    private var model: Model? = null
    private var speechService: SpeechService? = null

    init {
        LibVosk.setLogLevel(LogLevel.INFO)
    }

    fun initModel(onSuccess: () -> Unit, onError: (String) -> Unit) {
        Log.i(TAG, "Initializing Vosk model: $MODEL_NAME")
        try {
            // 记录可用文件
            context.assets.list("")?.forEach {
                Log.d(TAG, "Asset file: $it")
            }

            StorageService.unpack(context, MODEL_NAME, "model",
                { unpackedModel ->
                    Log.i(TAG, "Model unpacked successfully")
                    try {
                        model = unpackedModel
                        Log.i(TAG, "Model initialized successfully")
                        onSuccess()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to initialize model", e)
                        onError("Model initialization error: ${e.message}")
                    }
                },
                { exception ->
                    Log.e(TAG, "Failed to unpack model", exception)
                    onError("Failed to unpack model: ${exception.message}")
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error during model initialization", e)
            onError("Error during initialization: ${e.message}")
        }
    }

    fun startListening(listener: org.vosk.android.RecognitionListener): Boolean {
        try {
            if (speechService != null) {
                speechService?.stop()
                speechService?.shutdown()
            }

            val recognizer = Recognizer(model, 16000.0f)
            speechService = SpeechService(recognizer, 16000.0f)
            speechService?.startListening(listener)
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error starting speech service", e)
            return false
        }
    }

    fun stop() {
        speechService?.stop()
        speechService?.shutdown()
        speechService = null
    }

    fun release() {
        stop()
        model?.close()
        model = null
    }
}