// app/src/main/java/com/qw/sutra/MainActivity.kt
package com.qw.sutra

import ApiManager
import SpeechManager
import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.ImageButton
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : AppCompatActivity() {
    private lateinit var speechManager: SpeechManager
    private lateinit var apiManager: ApiManager

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        speechManager = SpeechManager(this)
        apiManager = ApiManager()

        findViewById<ImageButton>(R.id.voiceButton).setOnClickListener {
            checkPermissionAndStart()
        }
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
        speechManager.startListening { text ->
            // 显示识别中的提示
            Toast.makeText(this, "正在处理: $text", Toast.LENGTH_SHORT).show()

            apiManager.sendPrompt(text) { response ->
                runOnUiThread {
                    speechManager.speak(response)
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        speechManager.release()
    }
}