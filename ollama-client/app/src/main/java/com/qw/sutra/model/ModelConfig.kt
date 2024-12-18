// app/src/main/java/com/qw/sutra/model/ModelConfig.kt
package com.qw.sutra.model

data class ModelConfig(
    val modelName: String = "llama3-chinese",
    val temperature: Float = 0.7f,
    val topP: Float = 0.9f,
    val maxTokens: Int = 2048
) {
    companion object {
        val SUPPORTED_MODELS = listOf(
            "llama3-chinese"
            // 未来可以添加更多模型
        )

        // 获取默认配置
        fun getDefault() = ModelConfig()
    }
}