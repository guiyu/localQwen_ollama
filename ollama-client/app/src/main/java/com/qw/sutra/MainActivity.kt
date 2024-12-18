// app/src/main/java/com/qw/sutra/MainActivity.kt
package com.qw.sutra

import android.os.Bundle
import android.Manifest
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.lifecycleScope
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.qw.sutra.audio.AudioProcessor
import com.qw.sutra.network.OllamaApi
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val audioProcessor by lazy { AudioProcessor(this) }
    private lateinit var voiceButton: FloatingActionButton

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (!isGranted) {
            Toast.makeText(this, "需要录音权限才能使用语音功能", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        voiceButton = findViewById(R.id.voiceButton)
        voiceButton.setOnClickListener {
            checkPermissionAndStartListening()
        }

        // 请求录音权限
        permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
    }

    private fun checkPermissionAndStartListening() {
        lifecycleScope.launch {
            try {
                audioProcessor.startListening()
                    .collect { text ->
                        // 发送到服务器并获取响应
                        handleUserInput(text)
                    }
            } catch (e: Exception) {
                Toast.makeText(this@MainActivity, "语音识别失败", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun handleUserInput(text: String) {
        lifecycleScope.launch {
            try {
                // TODO: 实现API调用
                val response = "模拟的响应"
                audioProcessor.speak(response)
            } catch (e: Exception) {
                Toast.makeText(this@MainActivity, "获取响应失败", Toast.LENGTH_SHORT).show()
            }
        }
    }
}