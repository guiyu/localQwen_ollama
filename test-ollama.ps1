$body = @{
    model = "qwen:7b-chat"
    prompt = "Hello, are you working?"
} | ConvertTo-Json

try {
    # 使用 Invoke-WebRequest 来获取原始响应
    $response = Invoke-WebRequest `
        -Uri "http://localhost:11434/api/generate" `
        -Method Post `
        -Body $body `
        -ContentType "application/json"
    
    # 处理流式响应
    $responses = $response.Content -split "`n" | Where-Object { $_ }
    $fullResponse = ""
    
    foreach ($line in $responses) {
        $jsonResponse = $line | ConvertFrom-Json
        if ($jsonResponse.response) {
            $fullResponse += $jsonResponse.response
            # 实时显示正在生成的内容
            Write-Host $jsonResponse.response -NoNewline
        }
    }
    
    Write-Host "`n`nFull response:"
    Write-Host $fullResponse
    
} catch {
    Write-Host "Error testing the API: $_"
    Write-Host "`nDebug information:"
    Write-Host "Request URL: http://localhost:11434/api/generate"
    Write-Host "Request body: $body"
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorBody = $reader.ReadToEnd()
        Write-Host "Error response: $errorBody"
    }
}