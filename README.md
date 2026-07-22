# Intune Custom Detection: 7-Zip (Win32 App)

A highly reliable PowerShell detection script designed for **Microsoft Intune** to verify the successful installation of 7-Zip via the Win32 application deployment framework (`.intunewin`). 

Relying strictly on MSI product codes or default installation paths can result in false negatives if users deploy 32-bit versions on 64-bit operating systems, or if legacy registry keys are left behind after uninstalls. This script eliminates those errors by utilizing a multi-layered verification approach.

## 🚀 Features

* **Registry Precision:** Queries `HKLM`, `HKCU`, and `WOW6432Node` registry hives to locate the exact path written by the official 7-Zip installer.
* **Physical File Verification:** Prevents false positives by ensuring `7z.exe` actually exists at the targeted registry path.
* **Fallback Logic:** Automatically checks default Windows environmental paths (`%ProgramFiles%` and `%ProgramFiles(x86)`) in case the application was deployed portably or registry keys are corrupted.
* **Intune-Ready Exit Codes:** Properly structured to exit cleanly so the Microsoft Intune Management Extension (IME) can read the standard output for success/fail states.

## 🛠️ How It Works

1. The script first checks the standard installation registry keys for 7-Zip.
2. If a registry key is found, it extracts the `Path` property.
3. It then runs a `Test-Path` check to ensure the executable is physically present in that directory.
4. If the registry check fails, it defaults to checking standard 64-bit and 32-bit program file directories.
5. Outputs a standard `STDOUT` string (which Intune uses to flag the installation as "Installed").

## ⚙️ Intune Configuration Guide

When creating your Win32 App in the Microsoft Intune admin center, configure the **Detection rules** step as follows:

1. **Rules format:** Select `Use a custom detection script`
2. **Script file:** Upload `7zip-Detect.ps1`
3. **Run script as 32-bit process on 64-bit clients:** `No`
4. **Enforce script signature check and run quietly:** `No` *(Unless you are signing your scripts in your environment)*

## 📄 The Script

You can view the fully commented script in this repository: [`7zip-Detect.ps1`](./7zip-Detect.ps1)

## 🤝 Contributing

This script was built as part of an ongoing initiative to engineer zero-touch deployments and prepare for modern endpoint management certifications (MD-102). 

If you have suggestions for optimizing the fallback logic, dealing with stubborn legacy applications, or handling complex `.exe` deployments, feel free to open an issue or submit a pull request!

---
*Maintained by Frederick Thompson | LevelCore Technologies*
