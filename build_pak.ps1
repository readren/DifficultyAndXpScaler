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

# Optional: Deploy to standard Mods directories if reachable
$candidateDirs = @(
    "$env:USERPROFILE\Documents\Larian Studios\Divinity Original Sin 2 Definitive Edition\Mods",
    "$env:USERPROFILE\OneDrive\Documents\Larian Studios\Divinity Original Sin 2 Definitive Edition\Mods",
    "C:\Program Files (x86)\Steam\steamapps\common\Divinity Original Sin 2\DefEd\Data\Mods"
)

foreach ($dir in $candidateDirs) {
    if (Test-Path $dir) {
        $destFile = Join-Path $dir $pakName
        try {
            Copy-Item -Path $localPak -Destination $destFile -Force -ErrorAction Stop
            Write-Host "[DEPLOYED] $destFile" -ForegroundColor Cyan
        } catch {
            Write-Host "[NOTE] Could not copy directly to $destFile (file may be in use or protected): $_" -ForegroundColor Yellow
        }
    }
}
