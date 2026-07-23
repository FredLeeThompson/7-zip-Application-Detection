<#
.SYNOPSIS
Evaluates the local system to detect the presence of 7-Zip for Microsoft Intune Win32 App deployments.

.DESCRIPTION
This script acts as a highly reliable custom detection rule for Microsoft Intune. Relying strictly on MSI product
codes or default installation paths can result in false negatives if the user installs a 32-bit version on a
64-bit OS, or if uninstalls leave orphaned registry keys.

This script eliminates those errors by utilizing a multi-layered verification approach:

Queries the System (HKLM), User (HKCU), and 32-bit (WOW6432Node) registry hives to locate the exact installation path.

Verifies the physical presence of "7z.exe" at that targeted location.

Falls back to standard Windows environmental program paths (%ProgramFiles% and %ProgramFiles(x86)%) if registry keys are missing.

If detected, it writes a standard output string (STDOUT), which the Intune Management Extension (IME) reads as a success state to mark the application as "Installed".

.NOTES
Version:        1.0
Author:         Frederick Thompson
Creation Date:  July 2026
Purpose:        Robust custom detection logic for 7-Zip Win32 deployments.
Requirements:   Intune Management Extension (IME). No external modules required.

.EXAMPLE
.\7zip-Detect.ps1
Runs the detection script. If 7-Zip is installed, it outputs a success message containing the installation path and allows Intune to mark the app as "Installed".

.EXAMPLE
Get-Help .\7zip-Detect.ps1 -Full
Displays this comprehensive help documentation.
#>

[CmdletBinding()]
param()
 
 # Initialize a boolean variable to track whether 7-Zip is found. 
# We start by assuming it is not installed ($false).
$isInstalled = $false

# Initialize an empty string variable that will store the directory path if 7-Zip is found.
$installPath = ""

# =====================================================================
# Step 1: Registry Checks (The most reliable method)
# =====================================================================

# Define an array of registry paths where the 7-Zip installer commonly writes its information.
# HKLM is HKEY_LOCAL_MACHINE (System-wide installs)
# HKCU is HKEY_CURRENT_USER (User-specific installs)
# WOW6432Node is where 32-bit apps write their keys on a 64-bit operating system.
$registryPaths = @(
    "HKLM:\SOFTWARE\7-Zip",
    "HKCU:\SOFTWARE\7-Zip",
    "HKLM:\SOFTWARE\WOW6432Node\7-Zip"
)

# Loop through each of the registry paths defined in the array above.
foreach ($reg in $registryPaths) {
    
    # Check if the current registry path actually exists on this computer.
    if (Test-Path $reg) {
        
        # Read the "Path" property from the registry key, which contains the folder where 7-Zip is installed.
        # -ErrorAction SilentlyContinue prevents red error text if the key exists but the "Path" property is missing.
        $pathValue = (Get-ItemProperty -Path $reg -Name "Path" -ErrorAction SilentlyContinue).Path
        
        # Verify two things: 
        # 1) The path string isn't blank/empty.
        # 2) The actual '7z.exe' file exists inside that folder.
        # This double-check prevents false positives if a broken uninstall left registry keys behind but deleted the files.
        if (-not [string]::IsNullOrWhiteSpace($pathValue) -and (Test-Path "$pathValue\7z.exe")) {
            
            # If the file exists, change our tracker variable to true.
            $isInstalled = $true
            
            # Save the confirmed installation directory to our path variable.
            $installPath = $pathValue
            
            # We found it, so we break out of the loop immediately (no need to check the remaining registry keys).
            break
        }
    }
}

# =====================================================================
# Step 2: Fallback Checks (For portable versions or missing registry keys)
# =====================================================================

# Fallback check if 7-Zip was NOT found during the standard registry check.
if (-not $isInstalled) {
    
    # Define an array of the other default Windows installation folders where 7-Zip might be located.
    # $env:ProgramFiles resolves to "C:\Program Files" (for 64-bit apps).
    # ${env:ProgramFiles(x86)} resolves to "C:\Program Files (x86)" (for 32-bit apps).
    $defaultPaths = @(
        "$env:ProgramFiles\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
    )
    
    # Loop through each of those default file paths.
    foreach ($path in $defaultPaths) {
        
        # Check if the '7z.exe' file physically exists at this exact location.
        if (Test-Path $path) {
            
            # If the file exists, mark 7-Zip as installed.
            $isInstalled = $true
            
            # Use Split-Path to extract just the folder path (e.g., "C:\Program Files\7-Zip") 
            # from the full file path and save it to our variable.
            $installPath = Split-Path $path
            
            # We found it, so break out of the loop.
            break
        }
    }
}

# =====================================================================
# Step 3: Display the Output
# =====================================================================

# Check if our tracker variable was set to true at any point during the script.
if ($isInstalled) {
    
    # Print a success message to the console in green text.
    Write-Host "7-Zip installed." -ForegroundColor Green
    
    # Print the exact folder where 7-Zip is located in cyan text.
    Write-Host "Installation Directory: $installPath" -ForegroundColor Cyan
    exit 0
    
} else {
    
    # If the tracker is still false, print a failure message to the console in red text.
    Write-Host "7-Zip NOT installed" -ForegroundColor Red
    exit 1
}
