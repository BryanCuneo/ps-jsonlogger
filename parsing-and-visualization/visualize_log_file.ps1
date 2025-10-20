param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
)

Import-Module ps-jsonlogger

$log = Import-Log -Path $Path
$log.entries | ForEach-Object { 
    switch ($_.level) {
        "INFO"    { Write-Host "󰰄 " -NoNewline }
        "SUCCESS" { Write-Host " " -NoNewline -ForegroundColor Green }
        "WARNING" { Write-Host " " -NoNewline -ForegroundColor Yellow }
        "ERROR"   { Write-Host " " -NoNewline -ForegroundColor Red }
        "FATAL"   { Write-Host " " -NoNewline -ForegroundColor DarkRed }
        "DEBUG"   { Write-Host " " -NoNewline -ForegroundColor Blue }
        "VERBOSE" { Write-Host "󰰫 " -NoNewline -ForegroundColor DarkYellow }
    }
}

Write-Host "`n$($log.programName) - PSv$($log.PSVersion) - $($log.entries.count) entries" -ForegroundColor Gray
Write-Host "Started at $($log.startTime) and ran for $($log.duration)" -ForegroundColor Gray

if ($log.hasWarning) {
    Write-Host "  Contains $(($log.entries | Where-Object { $_.level -eq "WARNING" }).Count) warning(s)" -ForegroundColor Yellow
}
if ($log.hasError) {
    Write-Host "  Contains $(($log.entries | Where-Object { $_.level -eq "ERROR" }).Count) error(s)" -ForegroundColor Red
}
if ($log.hasFatal) {
    Write-Host "  Contains a fatal error." -ForegroundColor DarkRed
}