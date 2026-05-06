param(
    [Parameter(Mandatory = $true)][string]$InputVideo,
    [Parameter(Mandatory = $true)][string]$StartTime,
    [Parameter(Mandatory = $true)][string]$EndTime,
    [string]$Output = "clip_$(Get-Date -Format yyyyMMddHHmmss).mp4"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    throw "ffmpeg is required. Install FFmpeg and add it to PATH."
}
if (-not (Test-Path $InputVideo)) {
    throw "Input video does not exist: $InputVideo"
}

function Convert-ToSeconds {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -match '^(\d+):(\d+):(\d+(?:\.\d+)?)$') {
        return [double]$matches[1] * 3600 + [double]$matches[2] * 60 + [double]$matches[3]
    }
    if ($Value -match '^(\d+):(\d+(?:\.\d+)?)$') {
        return [double]$matches[1] * 60 + [double]$matches[2]
    }
    if ($Value -match '^\d+(?:\.\d+)?$') {
        return [double]$Value
    }
    throw "Invalid time format: $Value"
}

$startSec = Convert-ToSeconds $StartTime
$endSec = Convert-ToSeconds $EndTime
if ($endSec -le $startSec) {
    throw "End time must be later than start time."
}

$outputDir = Split-Path -Parent $Output
if ($outputDir) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "Extracting clip..."
Write-Host "Input: $InputVideo"
Write-Host "Range: $StartTime -> $EndTime"
Write-Host "Duration: $([math]::Round($endSec - $startSec, 3))s"
Write-Host "Output: $Output"

& ffmpeg -ss $StartTime -to $EndTime -i $InputVideo -c copy -avoid_negative_ts make_zero -y $Output

if (-not (Test-Path $Output) -or (Get-Item $Output).Length -eq 0) {
    throw "Clip extraction failed."
}

Write-Host "Clip extraction completed: $Output"
