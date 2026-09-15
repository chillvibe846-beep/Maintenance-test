# ============================================================
# LAPTOP AUDIT - FINAL V3
# Office IT Asset Management
# Run PowerShell as Administrator
# ============================================================

$ErrorActionPreference = "Continue"

# Friendly asset/laptop name used in reports (does NOT rename Windows)
$assetName = "GEPL-Maintenance"

function Safe-Value($Value, $Default = "Not Available") {
    if ($null -eq $Value) { return $Default }
    $s = "$Value".Trim()
    if ([string]::IsNullOrWhiteSpace($s) -or $s -match '^(x+|unknown|null|n/a)$') {
        return $Default
    }
    return $s
}

function Get-YesNo($Value) {
    if ($null -eq $Value) { return "Not Available" }
    if ($Value -eq $true -or "$Value" -eq "True") { return "Yes" }
    if ($Value -eq $false -or "$Value" -eq "False") { return "No" }
    return (Safe-Value $Value)
}

$now = Get-Date
$timestamp = $now.ToString("yyyyMMdd_HHmmss")

$desktopCandidates = @(
    [Environment]::GetFolderPath("Desktop"),
    "$env:USERPROFILE\OneDrive - Genlite - Personal\Desktop",
    "$env:USERPROFILE\OneDrive - Genlite\Desktop",
    "$env:USERPROFILE\OneDrive\Desktop",
    "$env:USERPROFILE\Desktop"
)
$desktop = $desktopCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $desktop) {
    Write-Host "ERROR: Could not find Desktop folder." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
$outDir = Join-Path $desktop "Laptop_Audit_Reports"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$computer = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ramModules = @(Get-CimInstance Win32_PhysicalMemory)
$disks = @(Get-CimInstance Win32_DiskDrive)
$logicalDisks = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3")
$gpus = @(Get-CimInstance Win32_VideoController)
$netAdapters = @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True")

# -------------------------
# Basic identity
# -------------------------
$manufacturer = Safe-Value $computer.Manufacturer
$model = Safe-Value $computer.Model
$serial = Safe-Value $bios.SerialNumber
$deviceName = $assetName
$windowsComputerName = Safe-Value $env:COMPUTERNAME

# -------------------------
# CPU
# -------------------------
$cpuName = Safe-Value $cpu.Name
$cpuCores = Safe-Value $cpu.NumberOfCores
$cpuThreads = Safe-Value $cpu.NumberOfLogicalProcessors
$cpuMaxGHz = if ($cpu.MaxClockSpeed) { "{0:N2} GHz" -f ($cpu.MaxClockSpeed / 1000) } else { "Not Available" }

# -------------------------
# RAM
# -------------------------
$ramGB = if ($computer.TotalPhysicalMemory) {
    "{0:N2} GB" -f ($computer.TotalPhysicalMemory / 1GB)
} else { "Not Available" }

$ramCount = $ramModules.Count
if ($ramCount -eq 0) { $ramCount = "Not Available" }

$ramTypes = @()
foreach ($r in $ramModules) {
    $type = switch ([int]$r.SMBIOSMemoryType) {
        20 { "DDR" }
        21 { "DDR2" }
        22 { "DDR2 FB-DIMM" }
        24 { "DDR3" }
        26 { "DDR4" }
        34 { "DDR5" }
        default { "Not Available" }
    }
    $ramTypes += $type
}
$ramType = Safe-Value (($ramTypes | Sort-Object -Unique) -join ", ")

# -------------------------
# Storage
# -------------------------
$physicalStorageGB = if ($disks.Count -gt 0) {
    "{0:N2} GB" -f (($disks | Measure-Object Size -Sum).Sum / 1GB)
} else { "Not Available" }

$storageModels = @($disks | ForEach-Object { Safe-Value $_.Model } | Sort-Object -Unique)
$storageModel = Safe-Value ($storageModels -join "; ")

$storageSerials = @($disks | ForEach-Object { Safe-Value $_.SerialNumber } | Sort-Object -Unique)
$storageSerial = Safe-Value ($storageSerials -join "; ")

$freeSpaceGB = if ($logicalDisks.Count -gt 0) {
    "{0:N2} GB" -f (($logicalDisks | Measure-Object FreeSpace -Sum).Sum / 1GB)
} else { "Not Available" }

$totalLogicalGB = if ($logicalDisks.Count -gt 0) {
    "{0:N2} GB" -f (($logicalDisks | Measure-Object Size -Sum).Sum / 1GB)
} else { "Not Available" }

# -------------------------
# GPU
# -------------------------
$gpuNames = @($gpus | ForEach-Object { Safe-Value $_.Name } | Sort-Object -Unique)
$gpu = Safe-Value ($gpuNames -join "; ")

# -------------------------
# Display
# -------------------------
$monitors = @()
try {
    $monitorIds = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID
    foreach ($m in $monitorIds) {
        $name = ""
        if ($m.UserFriendlyName) {
            $name = -join ($m.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })
        }
        $monitors += (Safe-Value $name)
    }
} catch {}
$monitorInfo = Safe-Value (($monitors | Sort-Object -Unique) -join "; ")

# -------------------------
# Windows
# -------------------------
$windowsEdition = Safe-Value (Get-ComputerInfo -Property WindowsProductName).WindowsProductName
$windowsVersion = Safe-Value $os.Version
$windowsBuild = Safe-Value $os.BuildNumber
$architecture = Safe-Value $os.OSArchitecture

$activation = "Not Available"
try {
    $lic = Get-CimInstance SoftwareLicensingProduct |
        Where-Object { $_.Name -like "Windows*" -and $_.PartialProductKey } |
        Sort-Object LicenseStatus -Descending |
        Select-Object -First 1
    if ($lic) {
        $activation = switch ([int]$lic.LicenseStatus) {
            1 { "Activated" }
            0 { "Unlicensed" }
            default { "Not Available" }
        }
    }
} catch {}

# -------------------------
# Office / Microsoft 365
# -------------------------
$officeDetected = "Not Detected"
$officePaths = @(
    "$env:ProgramFiles\Microsoft Office",
    "$env:ProgramFiles\Microsoft Office\root\Office16",
    "${env:ProgramFiles(x86)}\Microsoft Office",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16"
)
if ($officePaths | Where-Object { Test-Path $_ }) {
    $officeDetected = "Detected"
}
try {
    $officeApps = Get-AppxPackage -AllUsers | Where-Object {
        $_.Name -match "MicrosoftOffice|Office"
    }
    if ($officeApps) { $officeDetected = "Detected" }
} catch {}

# -------------------------
# TPM
# -------------------------
$tpmPresent = "Not Available"
$tpmReady = "Not Available"
$tpmVersion = "Not Available"
try {
    $tpm = Get-Tpm
    $tpmPresent = Get-YesNo $tpm.TpmPresent
    $tpmReady = Get-YesNo $tpm.TpmReady
    $tpmVersion = Safe-Value $tpm.ManufacturerVersion
} catch {}

# -------------------------
# Secure Boot
# -------------------------
$secureBoot = "Not Available"
try {
    $secureBoot = Get-YesNo (Confirm-SecureBootUEFI)
} catch {}

# -------------------------
# BitLocker
# -------------------------
$bitlockerStatus = "Not Available"
$bitlockerPercent = "Not Available"
try {
    $bl = @(Get-BitLockerVolume -MountPoint $env:SystemDrive)
    if ($bl.Count -gt 0) {
        $bitlockerStatus = Safe-Value $bl[0].VolumeStatus
        if ($null -ne $bl[0].EncryptionPercentage) {
            $bitlockerPercent = "$($bl[0].EncryptionPercentage)%"
        }
    }
} catch {}

# -------------------------
# Defender / Firewall
# -------------------------
$defenderStatus = "Not Available"
$realTimeProtection = "Not Available"
try {
    $def = Get-MpComputerStatus
    $defenderStatus = if ($def.AntivirusEnabled) { "Enabled" } else { "Disabled" }
    $realTimeProtection = if ($def.RealTimeProtectionEnabled) { "Enabled" } else { "Disabled" }
} catch {}

$firewall = "Not Available"
try {
    $profiles = Get-NetFirewallProfile
    $firewall = if (($profiles | Where-Object Enabled -eq $true).Count -gt 0) { "Enabled" } else { "Disabled" }
} catch {}

# -------------------------
# Network
# -------------------------
$wifi = @($netAdapters | Where-Object { $_.Description -match "Wi-Fi|Wireless|802.11" })
$ethernet = @($netAdapters | Where-Object { $_.Description -notmatch "Wi-Fi|Wireless|802.11" })

$wifiIP = Safe-Value (($wifi | ForEach-Object { $_.IPAddress } | Where-Object { $_ }) -join ", ")
$wifiMAC = Safe-Value (($wifi | ForEach-Object { $_.MACAddress } | Where-Object { $_ }) -join ", ")

$ethernetIP = Safe-Value (($ethernet | ForEach-Object { $_.IPAddress } | Where-Object { $_ }) -join ", ")
$ethernetMAC = Safe-Value (($ethernet | ForEach-Object { $_.MACAddress } | Where-Object { $_ }) -join ", ")

$bluetooth = if (Get-PnpDevice -Class Bluetooth -Status OK) { "Detected" } else { "Not Detected" }

# -------------------------
# Battery
# -------------------------
$battery = @(Get-CimInstance Win32_Battery)
$batteryStatus = if ($battery.Count -gt 0) {
    Safe-Value (($battery | ForEach-Object { $_.Status } | Sort-Object -Unique) -join ", ")
} else { "Not Available" }

$designCapacity = "Not Available"
$fullChargeCapacity = "Not Available"
$batteryHealth = "Not Available"

try {
    $batStatic = @(Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData)
    $batFull = @(Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity)

    if ($batStatic.Count -gt 0 -and $batStatic[0].DesignedCapacity) {
        $designCapacity = "{0:N0} mWh" -f $batStatic[0].DesignedCapacity
    }
    if ($batFull.Count -gt 0 -and $batFull[0].FullChargedCapacity) {
        $fullChargeCapacity = "{0:N0} mWh" -f $batFull[0].FullChargedCapacity
    }

    if ($designCapacity -ne "Not Available" -and $fullChargeCapacity -ne "Not Available") {
        $d = [double]$batStatic[0].DesignedCapacity
        $f = [double]$batFull[0].FullChargedCapacity
        if ($d -gt 0) {
            $batteryHealth = "{0:N1}%" -f (($f / $d) * 100)
        }
    }
} catch {}

# -------------------------
# Domain / Entra ID
# -------------------------
$domain = Safe-Value $computer.Domain
$domainJoined = Get-YesNo $computer.PartOfDomain

$entraJoined = "Not Available"
try {
    $dsreg = dsregcmd /status 2>$null
    $line = $dsreg | Select-String "AzureAdJoined"
    if ($line) {
        $entraJoined = if ($line.ToString() -match "YES") { "Yes" } elseif ($line.ToString() -match "NO") { "No" } else { "Not Available" }
    }
} catch {}

# -------------------------
# Local Administrators
# -------------------------
$localAdmins = "Not Available"
try {
    $members = Get-LocalGroupMember -Group "Administrators"
    $localAdmins = Safe-Value (($members | ForEach-Object { $_.Name }) -join "; ")
} catch {}

# -------------------------
# BIOS / boot
# -------------------------
$biosVersion = Safe-Value $bios.SMBIOSBIOSVersion
$biosDate = if ($bios.ReleaseDate) {
    try { ([Management.ManagementDateTimeConverter]::ToDateTime($bios.ReleaseDate)).ToString("yyyy-MM-dd") }
    catch { "Not Available" }
} else { "Not Available" }

$lastBoot = if ($os.LastBootUpTime) {
    try { ([Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)).ToString("yyyy-MM-dd HH:mm:ss") }
    catch { "Not Available" }
} else { "Not Available" }

# -------------------------
# Ports / webcam / keyboard
# -------------------------
$usbCount = "Not Available"
try {
    $usbCount = @(Get-PnpDevice -Class USB -Status OK).Count
} catch {}

$webcam = if (@(Get-PnpDevice -Class Camera -Status OK).Count -gt 0) { "Detected" } else { "Not Detected" }

# -------------------------
# Updates
# -------------------------
$lastHotfix = "Not Available"
try {
    $hf = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    if ($hf.InstalledOn) {
        $lastHotfix = ([datetime]$hf.InstalledOn).ToString("yyyy-MM-dd")
    }
} catch {}

# -------------------------
# Installed Software Inventory
# -------------------------
$softwareList = @()
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($path in $registryPaths) {
    try {
        $softwareList += Get-ItemProperty $path -ErrorAction Stop |
            Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } |
            ForEach-Object {
                [PSCustomObject]@{
                    SoftwareName = Safe-Value $_.DisplayName
                    Version = Safe-Value $_.DisplayVersion
                    Publisher = Safe-Value $_.Publisher
                    InstallDate = Safe-Value $_.InstallDate
                    InstallLocation = Safe-Value $_.InstallLocation
                    EstimatedSizeMB = if ($_.EstimatedSize) { [math]::Round($_.EstimatedSize / 1024, 2) } else { "Not Available" }
                }
            }
    } catch {
        Write-Warning "Could not read software registry path: $path"
    }
}
$softwareList = @($softwareList | Sort-Object SoftwareName, Version -Unique)
$softwareCount = $softwareList.Count
$softwareCsvPath = Join-Path $outDir "Installed_Software_${deviceName}_${timestamp}.csv"
$softwareList | Export-Csv -Path $softwareCsvPath -NoTypeInformation -Encoding UTF8

# -------------------------
# Build report
# -------------------------
$report = [ordered]@{
    "Audit Date" = $now.ToString("yyyy-MM-dd")
    "Audit Time" = $now.ToString("HH:mm:ss")
    "Device Name" = $deviceName
    "Windows Computer Name" = $windowsComputerName
    "Manufacturer" = $manufacturer
    "Model" = $model
    "Serial Number" = $serial
    "BIOS Version" = $biosVersion
    "BIOS Date" = $biosDate
    "Processor" = $cpuName
    "CPU Cores" = $cpuCores
    "CPU Threads" = $cpuThreads
    "CPU Max Speed" = $cpuMaxGHz
    "RAM" = $ramGB
    "RAM Type" = $ramType
    "RAM Module Count" = $ramCount
    "Storage Total (Physical)" = $physicalStorageGB
    "Storage Model" = $storageModel
    "Storage Serial" = $storageSerial
    "Logical Storage Total" = $totalLogicalGB
    "Free Storage" = $freeSpaceGB
    "GPU" = $gpu
    "Monitor" = $monitorInfo
    "Windows Edition" = $windowsEdition
    "Windows Version" = $windowsVersion
    "Windows Build" = $windowsBuild
    "OS Architecture" = $architecture
    "Windows Activation" = $activation
    "Office / M365 Detected" = $officeDetected
    "TPM Present" = $tpmPresent
    "TPM Ready" = $tpmReady
    "TPM Version" = $tpmVersion
    "Secure Boot" = $secureBoot
    "BitLocker Status" = $bitlockerStatus
    "BitLocker Encryption" = $bitlockerPercent
    "Defender" = $defenderStatus
    "Real-Time Protection" = $realTimeProtection
    "Firewall" = $firewall
    "Wi-Fi IP" = $wifiIP
    "Wi-Fi MAC" = $wifiMAC
    "Ethernet IP" = $ethernetIP
    "Ethernet MAC" = $ethernetMAC
    "Bluetooth" = $bluetooth
    "Battery Status" = $batteryStatus
    "Battery Design Capacity" = $designCapacity
    "Battery Full Charge Capacity" = $fullChargeCapacity
    "Battery Health" = $batteryHealth
    "Domain" = $domain
    "Domain Joined" = $domainJoined
    "Entra ID Joined" = $entraJoined
    "Local Administrators" = $localAdmins
    "Last Boot" = $lastBoot
    "USB Devices Available" = $usbCount
    "Webcam" = $webcam
    "Latest Hotfix Date" = $lastHotfix
    "Installed Software Count" = $softwareCount
    "Software Inventory CSV" = $softwareCsvPath
    "Report Folder" = $outDir
}

# CSV
$csvPath = Join-Path $outDir "Laptop_Audit_${deviceName}_${timestamp}.csv"
[pscustomobject]$report | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Human-readable TXT
$txtPath = Join-Path $outDir "Laptop_Audit_${deviceName}_${timestamp}.txt"
$report.GetEnumerator() | ForEach-Object {
    "{0}: {1}" -f $_.Key, $_.Value
} | Out-File -FilePath $txtPath -Encoding UTF8

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " LAPTOP AUDIT COMPLETED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Asset  : $deviceName"
Write-Host "Windows: $windowsComputerName"
Write-Host "Serial : $serial"
Write-Host "Date   : $($now.ToString('yyyy-MM-dd'))"
Write-Host "Time   : $($now.ToString('HH:mm:ss'))"
Write-Host ""
Write-Host "CSV report: $csvPath" -ForegroundColor Yellow
Write-Host "TXT report: $txtPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Software inventory: $softwareCsvPath" -ForegroundColor Yellow
Write-Host "No passwords or BitLocker recovery keys were collected." -ForegroundColor Green
Write-Host ""
