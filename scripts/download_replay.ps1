param(
    [Parameter(Mandatory = $true)][string]$M3U8Url,
    [string]$OutputName = "douyin_replay"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    throw "ffmpeg is required. Install FFmpeg and add it to PATH."
}
if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
    throw "ffprobe is required. Install FFmpeg and add it to PATH."
}
if ($M3U8Url -notmatch '^https?://') {
    throw "M3U8 URL must start with http:// or https://"
}

$drive = Get-PSDrive -Name (Get-Location).Path.Substring(0,1)
$freeGb = [math]::Floor($drive.Free / 1GB)
if ($freeGb -lt 5) {
    Write-Warning "Available disk space is below 5GB: ${freeGb}GB"
}

$outputFile = "$OutputName.mp4"
$logFile = "${OutputName}_download.log"
$outputDir = Split-Path -Parent $outputFile
if ($outputDir) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Downloading replay..."
Write-Host "URL: $M3U8Url"
Write-Host "Output: $outputFile"

& ffmpeg -i $M3U8Url -c copy -bsf:a aac_adtstoasc -movflags +faststart -y $outputFile 2>&1 |
    Tee-Object -FilePath $logFile

if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -gt 0)) {
    $duration = (& ffprobe -v error -show_entries format=duration -of csv=p=0 $outputFile 2>$null)
    Write-Host ""
    Write-Host "Download completed."
    Write-Host "File: $outputFile"
    Write-Host "Duration: $duration seconds"
    Write-Host "Log: $logFile"
} else {
    throw "Download failed or output file is empty."
}
