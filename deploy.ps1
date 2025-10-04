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

    [switch]$Force
)

$FolderPath = Resolve-Path $FolderPath

$module_name = "ps-jsonlogger"
$copyright = "(c) $(Get-Date -f "yyyy") Bryan Cuneo. Made available under the terms of the MIT License."
$description = "ps-jsonlogger is a small, dependency-free JSON logger designed to be easily embedded in automation scripts. It supports several log levels and writes compact, structured JSON entries to disk."
$psd_path = Join-Path -Path $FolderPath -ChildPath "$module_name.psd1"

$parameters = @{
    Path              = $psd_path
    RootModule        = $module_name
    Author            = "Bryan Cuneo"
    ModuleVersion     = $Version
    Copyright         = $copyright
    Description       = $description
    FunctionsToExport = "New-JsonLogger"
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
    $pkg_path = "$((Get-PSRepository "BCPS").SourceLocation)$module_name.$($Version).nupkg"

    Write-Host "Removing $pkg_path if it exists..." -NoNewline
    Remove-Item `
        -Path $pkg_path `
        -ErrorAction SilentlyContinue `
        -ProgressAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
}

Write-Host "Publishing module..." -NoNewline
Publish-Module -Path $FolderPath -Repository "BCPS"
Write-Host " Done" -ForegroundColor Green