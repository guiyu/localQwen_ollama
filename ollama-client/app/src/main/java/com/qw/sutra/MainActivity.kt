// app/src/main/java/com/qw/sutra/MainActivity.kt
package com.qw.sutra

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.ImageButton
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.qw.sutra.model.ModelConfig
import com.qw.sutra.network.ApiManager
import com.qw.sutra.network.NetworkMonitor
import com.qw.sutra.speech.SpeechManager
import com.qw.sutra.storage.ChatHistoryManager

class MainActivity : AppCompatActivity() {
    private lateinit var speechManager: SpeechManager
    private lateinit var apiManager: ApiManager
    private lateinit var chatHistoryManager: ChatHistoryManager
    private lateinit var recognitionStatus: TextView
    private lateinit var networkMonitor: NetworkMonitor

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initializeManagers()
        setupViews()
        setupTestInterface()
        initializeNetworkMonitor()

    }

    @SuppressLint("NewApi")
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
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

    private fun handleUserInput(text: String) {
        // 保存用户输入到历史
        chatHistoryManager.saveMessage("user", text)

        // 显示处理状态
        recognitionStatus.text = "正在处理: $text"

        // 使用非流式请求
        val modelConfig = ModelConfig(
            modelName = "llama3-chinese",
            stream = false  // 设置为非流式请求
        )

        apiManager.startChatStream(
            prompt = text,
            modelConfig = modelConfig,
            onResponse = { response ->
                runOnUiThread {
                    // 更新UI显示完整响应
                    recognitionStatus.text = response
                    // 播放完整响应
                    speechManager.speak(response)
                    // 保存响应到历史
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

    private fun checkPermissionAndStart() {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST_CODE
            )
        } else {
            startVoiceInteraction()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE &&
            grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            startVoiceInteraction()
        } else {
            Toast.makeText(this, "需要录音权限才能使用语音功能", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startVoiceInteraction() {
        speechManager.startListening(object : SpeechManager.SpeechCallback {
            override fun onListeningStart() {
                runOnUiThread {
                    recognitionStatus.text = "正在聆听..."
                }
            }

            override fun onRmsChanged(rmsdB: Float) {
                // 可以用这个值来更新UI显示音量变化
                runOnUiThread {
                    val volume = (rmsdB * 2).coerceIn(0f, 10f)
                    recognitionStatus.text = "正在聆听: ${"▮".repeat(volume.toInt())}"
                }
            }

            override fun onResult(text: String) {
                runOnUiThread {
                    handleUserInput(text)
                }
            }

            override fun onError(errorMessage: String) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity, errorMessage, Toast.LENGTH_SHORT).show()
                    recognitionStatus.text = errorMessage
                }
            }

            override fun onReadyForSpeech() {
                runOnUiThread {
                    recognitionStatus.text = "请开始说话..."
                }
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        networkMonitor.stopMonitoring()
        speechManager.release()
    }
}