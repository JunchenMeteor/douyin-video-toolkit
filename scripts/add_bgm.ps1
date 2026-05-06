param(
    [Parameter(Mandatory = $true)][string]$Video,
    [Parameter(Mandatory = $true)][string]$Bgm,
    [double]$Volume = 0.25,
    [double]$FadeStart = 59,
    [double]$FadeDuration = 3.5,
    [string]$Output = "output_with_bgm.mp4"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    throw "ffmpeg is required. Install FFmpeg and add it to PATH."
}
if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
    throw "ffprobe is required. Install FFmpeg and add it to PATH."
}
if (-not (Test-Path $Video)) {
    throw "Video file does not exist: $Video"
}
if (-not (Test-Path $Bgm)) {
    throw "BGM file does not exist: $Bgm"
}

$audioStream = & ffprobe -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 $Video
if (-not $audioStream) {
    throw "Video has no audio stream and cannot be mixed with BGM."
}

$outputDir = Split-Path -Parent $Output
if ($outputDir) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Adding BGM..."
Write-Host "Video: $Video"
Write-Host "BGM: $Bgm"
Write-Host "Volume: $Volume"
Write-Host "Fade out: ${FadeStart}s, duration ${FadeDuration}s"
Write-Host "Output: $Output"

$filter = "[1:a]volume=${Volume},afade=t=in:d=1.5,afade=t=out:st=${FadeStart}:d=${FadeDuration}[bgm];[0:a][bgm]amix=inputs=2:duration=first:weights=1 0.3"

& ffmpeg -i $Video -i $Bgm -filter_complex $filter -c:v copy -c:a aac -b:a 128k -shortest -movflags +faststart -y $Output

if (-not (Test-Path $Output) -or (Get-Item $Output).Length -eq 0) {
    throw "BGM mixing failed."
}

Write-Host "BGM mixing completed: $Output"
