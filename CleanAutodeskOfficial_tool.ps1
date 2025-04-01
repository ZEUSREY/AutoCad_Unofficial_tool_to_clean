<#
.SYNOPSIS
    Clean uninstall Autodesk products from Windows.

.DESCRIPTION
    This script follows the Autodesk Support instructions to remove Autodesk software,
    residual files, folders, and registry keys. It performs the following actions:
      - (Optional) Runs Autodesk Uninstall Tool if available.
      - Uninstalls Autodesk Access by running RemoveODIS.exe.
      - Uninstalls Autodesk Licensing Desktop Service.
      - Deletes temporary files.
      - Removes residual Autodesk files in FLEXnet.
      - Deletes Autodesk folders from Program Files, ProgramData, and user profiles.
      - Deletes Autodesk registry keys (HKLM and HKCU).
      - Prompts the user to manually uninstall Autodesk Genuine Service if necessary.
      
.NOTES
    - Run this script with administrator privileges.
    - Backup your system and registry before proceeding.
    - Use at your own risk.
#>

function Confirm-Action {
    param(
        [string]$Message
    )
    $response = Read-Host "$Message [Y/N]"
    if ($response -notmatch '^(Y|y)') {
        Write-Host "Aborting." -ForegroundColor Red
        exit
    }
}

# Ensure running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}

Write-Host "WARNING: This script will remove ALL Autodesk software, files, folders, and registry keys." -ForegroundColor Yellow
Confirm-Action "Do you want to continue?"

# 1. (Optional) Attempt to run Autodesk Uninstall Tool if available.
# Note: This tool may not be available on systems using the new Installation Experience.
$uninstallTool = Get-Command "Uninstall Tool" -ErrorAction SilentlyContinue
if ($uninstallTool) {
    Write-Host "Found Autodesk Uninstall Tool. Launching it..."
    Start-Process "Uninstall Tool"
    Write-Host "Please use the tool to remove Autodesk products, then press Enter to continue..."
    Read-Host
} else {
    Write-Host "Autodesk Uninstall Tool not found. Proceeding with manual steps..."
}

# 2. Uninstall Autodesk software via Control Panel is not directly automatable.
Write-Host "NOTE: To uninstall any remaining Autodesk software, please review 'Programs and Features' manually." -ForegroundColor Cyan

# 3. Uninstall Autodesk Access (RemoveODIS.exe)
$odisPath = "C:\Program Files\Autodesk\AdODIS\V1\RemoveODIS.exe"
if (Test-Path $odisPath) {
    Write-Host "Running RemoveODIS.exe to uninstall Autodesk Access..."
    Start-Process -FilePath $odisPath -Wait
} else {
    Write-Host "RemoveODIS.exe not found at $odisPath"
}

# 4. Uninstall Autodesk Licensing Desktop Service
$licensingUninstall = "C:\Program Files (x86)\Common Files\Autodesk Shared\AdskLicensing\uninstall.exe"
if (Test-Path $licensingUninstall) {
    Write-Host "Running uninstall.exe for Autodesk Licensing Desktop Service..."
    Start-Process -FilePath $licensingUninstall -Wait
} else {
    Write-Host "Autodesk Licensing uninstall executable not found at $licensingUninstall"
}

# 5. (Optional) Invoke Microsoft Program Install and Uninstall Troubleshooter manually.
Write-Host "NOTE: For residual software removal, please run the Microsoft Program Install and Uninstall Troubleshooter manually." -ForegroundColor Cyan

# 6. Clean Temp folder
$TempPath = $env:TEMP
Write-Host "Deleting contents of Temp folder: $TempPath"
try {
    Get-ChildItem -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "Temp folder cleaned."
} catch {
    Write-Host "Failed to remove ${TempPath}: ${_}" -ForegroundColor Red
}

# 7. Remove files in FLEXnet folder starting with "adsk"
$fleetPath = "C:\ProgramData\FLEXnet"
if (Test-Path $fleetPath) {
    Write-Host "Removing files starting with 'adsk' in $fleetPath"
    try {
        Get-ChildItem -Path $fleetPath -Filter "adsk*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "Files removed."
    } catch {
        Write-Host "Error removing files: ${_}" -ForegroundColor Red
    }
} else {
    Write-Host "FLEXnet folder not found at $fleetPath"
}

# 8. Remove Autodesk folders
$foldersToRemove = @(
    "C:\Program Files\Autodesk",
    "C:\Program Files\Common Files\Autodesk Shared",
    "C:\Program Files (x86)\Autodesk",
    "C:\Program Files (x86)\Common Files\Autodesk Shared",
    "C:\ProgramData\Autodesk",
    "$env:LOCALAPPDATA\Autodesk",
    "$env:APPDATA\Autodesk"
)

foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        Write-Host "Removing folder: $folder"
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Removed $folder"
        } catch {
            Write-Host "Failed to remove ${folder}: ${_}" -ForegroundColor Red
        }
    } else {
        Write-Host "Folder not found: $folder"
    }
}

# 9. Remove Autodesk registry keys
$registryKeys = @(
    "HKLM:\SOFTWARE\Autodesk",
    "HKCU:\SOFTWARE\Autodesk"
)

foreach ($regKey in $registryKeys) {
    if (Test-Path $regKey) {
        Write-Host "Removing registry key: $regKey"
        try {
            Remove-Item -Path $regKey -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Removed registry key $regKey"
        } catch {
            Write-Host "Failed to remove registry key ${regKey}: ${_}" -ForegroundColor Red
        }
    } else {
        Write-Host "Registry key not found: $regKey"
    }
}

# 10. Uninstall Autodesk Genuine Service via Control Panel
Write-Host "NOTE: To uninstall Autodesk Genuine Service, please open Control Panel (appwiz.cpl) and uninstall it manually if it remains." -ForegroundColor Cyan

Write-Host "Clean uninstall procedure completed. It is recommended to reboot your system after this script."
