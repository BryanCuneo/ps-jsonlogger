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
    [Parameter(Mandatory = $true)]
    [string]$FolderPath,

    [Parameter(Mandatory = $true)]
    [version]$Version,

    [string]$Author = "Bryan Cuneo",
    [string]$ModuleName = "ps-jsonlogger",
    [string]$LocalRepository = "BCPS",
    [switch]$Force
)

$FolderPath = Resolve-Path $FolderPath

$copyright = "(c) $(Get-Date -f "yyyy") $Author. Made available under the terms of the MIT License."
$description = "ps-jsonlogger is a small, dependency-free structured logging module for PowerShell that offers both compact JSON logs on-disk and human-readble console output. It supports log levels, context objects, full call stack inclusion, and more."
$psd_path = Join-Path -Path $FolderPath -ChildPath "$ModuleName.psd1"

$parameters = @{
    Path              = $psd_path
    RootModule        = $ModuleName
    Author            = $Author
    ModuleVersion     = $Version
    Copyright         = $copyright
    Description       = $description
    FunctionsToExport = "New-Logger", "Write-Log", "Close-Log", "Import-Log", "Convert-Log"
    LicenseUri        = "https://opensource.org/license/MIT"
    ProjectUri        = "https://github.com/BryanCuneo/ps-jsonlogger"
}

if (Test-Path $psd_path) {
    Write-Host "Updating module manifest..." -NoNewline
    Update-ModuleManifest @parameters -ErrorAction Stop
    Write-Host " Done" -ForegroundColor Green
}
else {
    Write-Host "Generating module manifest..." -NoNewline
    New-ModuleManifest @parameters -ErrorAction Stop
    Write-Host " Done" -ForegroundColor Green
}

if ($Force) {
    $pkg_path = "$((Get-PSRepository $LocalRepository).SourceLocation)$ModuleName.$($Version).nupkg"

    Write-Host "Removing $pkg_path if it exists..." -NoNewline
    Remove-Item `
        -Path $pkg_path `
        -ErrorAction SilentlyContinue `
        -ProgressAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
}

Write-Host "Publishing module..." -NoNewline
Publish-Module -Path $FolderPath -Repository $LocalRepository
Write-Host " Done" -ForegroundColor Green