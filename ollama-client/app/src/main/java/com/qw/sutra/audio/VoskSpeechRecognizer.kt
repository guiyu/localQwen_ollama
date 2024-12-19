// app/src/main/java/com/qw/sutra/audio/VoskRecognizer.kt
package com.qw.sutra.audio

import android.content.Context
import android.util.Log
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import java.io.File
import java.io.FileOutputStream

class VoskRecognizer(private val context: Context) {
    companion object {
        private const val TAG = "VoskRecognizer"
        private const val SAMPLE_RATE = 16000
        private const val MODEL_PATH = "model-cn"
    }

    private var model: Model? = null
    private var speechService: SpeechService? = null

    init {
        initModel()
    }

    private fun initModel() {
        try {
            val modelDir = File(context.filesDir, MODEL_PATH)
            if (!modelDir.exists()) {
                modelDir.mkdirs()
                copyAssets(modelDir)
            }
            model = Model(modelDir.absolutePath)
            Log.i(TAG, "Vosk model initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Vosk model", e)
        }
    }

    private fun copyAssets(modelDir: File) {
        val assetManager = context.assets
        assetManager.list(MODEL_PATH)?.forEach { filename ->
            try {
                val inputStream = assetManager.open("$MODEL_PATH/$filename")
                val outFile = File(modelDir, filename)
                FileOutputStream(outFile).use { out ->
                    inputStream.copyTo(out)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error copying asset file: $filename", e)
            }
        }
    }

    fun startListening(listener: RecognitionListener) {
        try {
            val recognizer = Recognizer(model, SAMPLE_RATE.toFloat())
            speechService = SpeechService(recognizer, SAMPLE_RATE.toFloat())
            speechService?.startListening(listener)
            Log.i(TAG, "Started listening with Vosk")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting Vosk recognition", e)
            listener.onError(e)
        }
    }

    fun stop() {
        speechService?.stop()
        speechService = null
    }

    fun release() {
        stop()
        model?.close()
        model = null
    }
}