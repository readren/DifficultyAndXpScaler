<#
.SYNOPSIS
    Builds DifficultyMod.pak and copies it directly to your DOS2 Mods folder.
#>
$ErrorActionPreference = "Stop"

$projectRoot = "C:\projects\games\divinity\difficulty-mod"
$staging = "$env:TEMP\DifficultyMod_Staging"
$divine = "$env:TEMP\ExportTool\ExportTool-v1.18.7\Tools\divine.exe"

if (-not (Test-Path $divine)) {
    Write-Host "Downloading LSLib / divine.exe..."
    $zip = "$env:TEMP\ExportTool.zip"
    Invoke-WebRequest -Uri "https://github.com/Norbyte/lslib/releases/download/v1.18.7/ExportTool-v1.18.7.zip" -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath "$env:TEMP\ExportTool" -Force
}

if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

Copy-Item -Path "$projectRoot\Mods" -Destination $staging -Recurse -Force
if (Test-Path "$projectRoot\Public") {
    Copy-Item -Path "$projectRoot\Public" -Destination $staging -Recurse -Force
}

$pakName = "DifficultyMod_e3d48d57-3f32-4d2a-9e1e-28b9a712f101.pak"
$localPak = "$projectRoot\$pakName"

# Build package
& $divine -g dos2de -a create-package -s $staging -d $localPak

Write-Host "`n[SUCCESS] $pakName successfully built: $localPak" -ForegroundColor Green

# Deploy strictly to standard user Documents Mods folder
$myDocs = [Environment]::GetFolderPath("MyDocuments")
$standardModDir = "$myDocs\Larian Studios\Divinity Original Sin 2 Definitive Edition\Mods"

# Fallback check for OneDrive redirection if path doesn't exist
if (-not (Test-Path $standardModDir)) {
    $oneDriveDocs = "$env:USERPROFILE\OneDrive\Documents\Larian Studios\Divinity Original Sin 2 Definitive Edition\Mods"
    if (Test-Path $oneDriveDocs) {
        $standardModDir = $oneDriveDocs
    }
}

if (Test-Path $standardModDir) {
    $destFile = Join-Path $standardModDir $pakName
    try {
        Copy-Item -Path $localPak -Destination $destFile -Force -ErrorAction Stop
        Write-Host "[DEPLOYED] $destFile" -ForegroundColor Cyan
    } catch {
        Write-Host "[ERROR] Could not copy to $destFile (ensure game is closed so file is not locked): $_" -ForegroundColor Red
    }
} else {
    Write-Host "[WARNING] Documents Mods folder not found: $standardModDir" -ForegroundColor Yellow
}
