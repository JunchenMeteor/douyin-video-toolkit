param(
    [Parameter(Mandatory = $true)][string]$InputVideo,
    [double]$SlowStart = 4,
    [double]$SlowEnd = 6.5,
    [double]$SlomoFactor = 1.5,
    [string]$Output = "slowmo_vertical.mp4"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    throw "ffmpeg is required. Install FFmpeg and add it to PATH."
}
if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
    throw "ffprobe is required. Install FFmpeg and add it to PATH."
}
if (-not (Test-Path $InputVideo)) {
    throw "Input video does not exist: $InputVideo"
}

$audioStream = & ffprobe -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 $InputVideo
if (-not $audioStream) {
    throw "Input video has no audio stream. This script requires audio to keep slow motion synchronized."
}

$totalDuration = [double](& ffprobe -v error -show_entries format=duration -of csv=p=0 $InputVideo)
if ($SlowStart -lt 0 -or $SlowEnd -le $SlowStart -or $SlowEnd -gt $totalDuration) {
    throw "Invalid slow-motion range. Require 0 <= SlowStart < SlowEnd <= video duration."
}

$atempo = 1.0 / $SlomoFactor
if ($atempo -lt 0.5 -or $atempo -gt 2.0) {
    throw "The computed atempo=$atempo is outside FFmpeg's single-filter range 0.5-2.0."
}

$endTime = "{0:N1}" -f $totalDuration
$atempoText = "{0:N4}" -f $atempo
$outputDir = Split-Path -Parent $Output
if ($outputDir) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Creating slow-motion vertical video..."
Write-Host "Input: $InputVideo"
Write-Host "Slow range: ${SlowStart}s -> ${SlowEnd}s"
Write-Host "Slomo factor: ${SlomoFactor}x (atempo: $atempoText)"
Write-Host "Output: $Output"

$filter = @"
[0:v]trim=0:${SlowStart},setpts=PTS-STARTPTS[v1];
[0:v]trim=${SlowStart}:${SlowEnd},setpts=PTS-STARTPTS,tmix=frames=3:weights='1 1 1',setpts=${SlomoFactor}*PTS[v2];
[0:v]trim=${SlowEnd}:${endTime},setpts=PTS-STARTPTS[v3];
[0:a]atrim=0:${SlowStart},asetpts=PTS-STARTPTS[a1];
[0:a]atrim=${SlowStart}:${SlowEnd},asetpts=PTS-STARTPTS,atempo=${atempoText}[a2];
[0:a]atrim=${SlowEnd}:${endTime},asetpts=PTS-STARTPTS[a3];
[v1][a1][v2][a2][v3][a3]concat=n=3:v=1:a=1[joined];
[joined]crop=ih*9/16:ih,scale=1080:1920:force_original_aspect_ratio=increase[fg];
[joined]scale=1080:6080,boxblur=20:5,crop=1080:1920[bg];
[bg][fg]overlay=(W-w)/2:(H-h)/2:format=auto
"@

& ffmpeg -i $InputVideo -filter_complex $filter -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart -y $Output

if (-not (Test-Path $Output) -or (Get-Item $Output).Length -eq 0) {
    throw "Rendering failed."
}

Write-Host "Rendering completed: $Output"
