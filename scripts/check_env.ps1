param()

$ErrorActionPreference = "Stop"
$failed = $false

function Test-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Hint
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "OK  ${Name}: $($cmd.Source)"
    } else {
        Write-Host "ERR ${Name}: missing ($Hint)"
        $script:failed = $true
    }
}

function Test-Filter {
    param([Parameter(Mandatory = $true)][string]$Name)

    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        return
    }

    $filters = & ffmpeg -hide_banner -filters 2>$null
    if ($filters -match "\s$Name\s") {
        Write-Host "OK  ffmpeg filter: $Name"
    } else {
        Write-Host "WARN ffmpeg filter missing: $Name"
    }
}

Test-Command ffmpeg "install FFmpeg and add it to PATH"
Test-Command ffprobe "install FFmpeg and add ffprobe to PATH"

Test-Filter tmix
Test-Filter drawtext
Test-Filter afade
Test-Filter ass
Test-Filter subtitles

if ($failed) {
    Write-Host ""
    Write-Host "Environment check failed. Install the missing required commands and retry."
    exit 1
}

Write-Host ""
Write-Host "Environment check completed. Warnings may be acceptable if you do not use that feature."
