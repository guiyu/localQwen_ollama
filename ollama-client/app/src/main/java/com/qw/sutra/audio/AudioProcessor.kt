// app/src/main/java/com/qw/sutra/audio/AudioProcessor.kt
package com.qw.sutra.audio

import android.content.Context
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class AudioProcessor(context: Context) {
    private val speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
    private val textToSpeech = TextToSpeech(context) { }

    fun startListening(): Flow<String> = flow {
        // 实现语音识别
    }

    fun speak(text: String) {
        textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
    }
}