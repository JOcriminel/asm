$ErrorActionPreference = 'Stop'

# Step 1: Obtain token via client_credentials
$tokenBody = @{
    client_id     = 'asm-apis'
    client_secret = 'WIIWVngUsQgSTyXB50AXm1YyeVtaog7V'
    grant_type    = 'client_credentials'
}

Write-Host ">> Requesting OAuth token..." -ForegroundColor Cyan
$tokenResp = Invoke-RestMethod `
    -Method Post `
    -Uri 'https://duxweb.pre-produx.asmtechtn.com/auth/realms/DuxWeb/protocol/openid-connect/token' `
    -Body $tokenBody `
    -ContentType 'application/x-www-form-urlencoded'

$token = $tokenResp.access_token
Write-Host ">> Token obtained (first 40 chars): $($token.Substring(0, [Math]::Min(40, $token.Length)))..." -ForegroundColor Green

# Step 2: Call the real endpoint
$baseUrl = 'https://skimmed-reapprove-editor.ngrok-free.dev'
$url = "$baseUrl/api/timetree/dashboard"

Write-Host "" 
Write-Host ">> GET $url" -ForegroundColor Cyan

$headers = @{
    Authorization            = "Bearer $token"
    'ngrok-skip-browser-warning' = '1'
}

try {
    $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
    Write-Host ">> HTTP 200 OK" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== RESPONSE JSON ===" -ForegroundColor Yellow
    $resp | ConvertTo-Json -Depth 10
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host ">> HTTP $statusCode" -ForegroundColor Red
    Write-Host $_.Exception.Message
    # Try to read the body
    $stream = $_.Exception.Response.GetResponseStream()
    if ($stream) {
        $reader = [System.IO.StreamReader]::new($stream)
        Write-Host ">> Body: $($reader.ReadToEnd())"
    }
}
