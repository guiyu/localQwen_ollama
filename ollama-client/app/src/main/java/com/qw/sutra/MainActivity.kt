// app/src/main/java/com/qw/sutra/MainActivity.kt
package com.qw.sutra

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import android.util.Log
import android.widget.Button
import android.widget.EditText
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.qw.sutra.model.ModelConfig
import com.qw.sutra.network.ApiManager
import com.qw.sutra.network.NetworkMonitor
import com.qw.sutra.speech.SpeechManager
import com.qw.sutra.storage.ChatHistoryManager

class MainActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val PERMISSIONS_REQUEST_RECORD_AUDIO = 1
    }

    private lateinit var speechManager: SpeechManager
    private lateinit var apiManager: ApiManager
    private lateinit var chatHistoryManager: ChatHistoryManager
    private lateinit var recognitionStatus: TextView
    private lateinit var networkMonitor: NetworkMonitor

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 检查录音权限
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSIONS_REQUEST_RECORD_AUDIO)
        } else {
            initializeServices()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int,
                                            permissions: Array<String>,
                                            grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSIONS_REQUEST_RECORD_AUDIO) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initializeServices()
            } else {
                finish()
            }
        }
    }

    private fun initializeServices() {
        initializeManagers()
        setupViews()
        setupTestInterface()
        initializeNetworkMonitor()
    }

    private fun initializeManagers() {
        speechManager = SpeechManager(this)
        apiManager = ApiManager(this)
        chatHistoryManager = ChatHistoryManager(this)
    }

    private fun setupViews() {
        recognitionStatus = findViewById(R.id.recognitionStatus)
        findViewById<ImageButton>(R.id.voiceButton).setOnClickListener {
            checkPermissionAndStart()
        }
    }

    private fun setupTestInterface() {
        val testInput = findViewById<EditText>(R.id.testInput)
        findViewById<Button>(R.id.testSendButton).setOnClickListener {
            val text = testInput.text.toString()
            if (text.isNotEmpty()) {
                handleUserInput(text)
                testInput.setText("")
            }
        }
    }

    private fun initializeNetworkMonitor() {
        networkMonitor = NetworkMonitor(this)
        networkMonitor.startMonitoring { isAvailable ->
            runOnUiThread {
                if (!isAvailable) {
                    Toast.makeText(this, "网络连接已断开", Toast.LENGTH_SHORT).show()
                    recognitionStatus.text = "网络连接已断开"
                }
            }
        }
    }

    private fun checkPermissionAndStart() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSIONS_REQUEST_RECORD_AUDIO)
        } else {
            startVoiceInteraction()
        }
    }

    private fun startVoiceInteraction() {
        recognitionStatus.text = "正在准备语音识别..."

        val recognitionListener = object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d(TAG, "onReadyForSpeech")
                runOnUiThread {
                    recognitionStatus.text = "请开始说话..."
                }
            }

            override fun onBeginningOfSpeech() {
                Log.d(TAG, "onBeginningOfSpeech")
                runOnUiThread {
                    recognitionStatus.text = "正在聆听..."
                }
            }

            override fun onRmsChanged(rmsdB: Float) {
                runOnUiThread {
                    val volume = (rmsdB * 2).coerceIn(0f, 10f)
                    recognitionStatus.text = "正在聆听: ${"▮".repeat(volume.toInt())}"
                }
            }

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                Log.d(TAG, "onEndOfSpeech")
                runOnUiThread {
                    recognitionStatus.text = "处理中..."
                }
            }

            override fun onError(error: Int) {
                val errorMessage = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "音频录制错误"
                    SpeechRecognizer.ERROR_CLIENT -> "语音识别初始化中，请稍后重试"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "权限不足"
                    SpeechRecognizer.ERROR_NETWORK -> "网络错误"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "网络超时"
                    SpeechRecognizer.ERROR_NO_MATCH -> "未能匹配语音"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "识别服务忙"
                    SpeechRecognizer.ERROR_SERVER -> "服务器错误"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "语音超时"
                    else -> "未知错误"
                }
                Log.e(TAG, "onError: $errorMessage")
                runOnUiThread {
                    Toast.makeText(this@MainActivity, errorMessage, Toast.LENGTH_SHORT).show()
                    recognitionStatus.text = "错误: $errorMessage"
                }
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { text ->
                    Log.i(TAG, "Recognition result: $text")
                    runOnUiThread {
                        handleUserInput(text)
                    }
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                matches?.firstOrNull()?.let { text ->
                    Log.d(TAG, "Partial result: $text")
                    runOnUiThread {
                        recognitionStatus.text = "识别中: $text"
                    }
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        }

        speechManager.startListening(recognitionListener)
    }

    private fun handleUserInput(text: String) {
        chatHistoryManager.saveMessage("user", text)

        recognitionStatus.text = "正在处理: $text"

        val modelConfig = ModelConfig(
            modelName = "llama3-chinese",
            stream = false
        )

        apiManager.startChatStream(
            prompt = text,
            modelConfig = modelConfig,
            onResponse = { response ->
                runOnUiThread {
                    recognitionStatus.text = response
                    speechManager.speak(response)
                    chatHistoryManager.saveMessage("assistant", response)
                }
            },
            onComplete = {
                runOnUiThread {
                    recognitionStatus.text = "处理完成"
                }
            },
            onError = { error ->
                runOnUiThread {
                    Toast.makeText(this, error, Toast.LENGTH_SHORT).show()
                    recognitionStatus.text = "错误: $error"
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        networkMonitor.stopMonitoring()
        speechManager.release()
    }
}