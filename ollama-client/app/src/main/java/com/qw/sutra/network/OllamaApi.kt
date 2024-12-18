// app/src/main/java/com/qw/sutra/network/OllamaApi.kt
package com.qw.sutra.network

import kotlinx.coroutines.flow.Flow
import retrofit2.http.Body
import retrofit2.http.POST

interface OllamaApi {
    @POST("api/generate")
    fun generateStream(
        @Body request: GenerateRequest
    ): Flow<GenerateResponse>

    data class GenerateRequest(
        val model: String = "llama3-chinese",
        val prompt: String
    )

    data class GenerateResponse(
        val response: String,
        val done: Boolean
    )
}