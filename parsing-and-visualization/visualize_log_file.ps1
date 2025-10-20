# Copyright (c) 2025 Bryan Cuneo

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path
)

Import-Module ps-jsonlogger

$log = Import-Log -Path $Path
$log.entries | ForEach-Object {
    switch ($_.level) {
        "INFO" { Write-Host "󰰄 " -NoNewline }
        "SUCCESS" { Write-Host " " -NoNewline -ForegroundColor Green }
        "WARNING" { Write-Host " " -NoNewline -ForegroundColor Yellow }
        "ERROR" { Write-Host " " -NoNewline -ForegroundColor Red }
        "FATAL" { Write-Host " " -NoNewline -ForegroundColor DarkRed }
        "DEBUG" { Write-Host " " -NoNewline -ForegroundColor Blue }
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