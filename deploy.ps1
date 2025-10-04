param(
    [Parameter(Mandatory = $true)]
    [string]$FolderPath,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [switch]$Force
)

$FolderPath = Resolve-Path $FolderPath

$module_name = "ps-jsonlogger"
$copyright = "(c) $(Get-Date -f "yyyy") Bryan Cuneo. Made available under the terms of the MIT License."
$description = "The ps-jsonlogger module provides a small, dependency-free JSON logger implemented as a class-based module. It supports several log levels and writes compact JSON entries to a file. Designed to be simple to embed in CI or automation scripts."
$psd_path = Join-Path -Path $FolderPath -ChildPath "$module_name.psd1"

Write-Host "Generating module manifest..." -NoNewline
New-ModuleManifest `
    -Path $psd_path `
    -RootModule $module_name `
    -Author "Bryan Cuneo" `
    -ModuleVersion $Version `
    -Copyright $copyright `
    -Description $description `
    -FunctionsToExport "New-JsonLogger" `
    -LicenseUri "https://opensource.org/license/MIT" `
    -ProjectUri "https://github.com/BryanCuneo/ps-jsonlogger" `
    -ErrorAction Stop
Write-Host " Done" -ForegroundColor Green

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