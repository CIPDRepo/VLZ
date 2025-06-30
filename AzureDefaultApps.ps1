# Enforce TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Bypass certificate validation (temporary fix for GitHub SSL in ISE or missing certs)
Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Set paths
$logDir = "C:\Temp"
$transcriptLog = "$logDir\setup_log.txt"
$stepsLog = "$logDir\setup_log_steps.txt"

# Ensure log directory exists
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Start transcript for full output
Start-Transcript -Path $transcriptLog -Append

# Use a separate log for step logs (to avoid conflicts with transcript)
function LogStep {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp`t$message" | Out-File -FilePath $stepsLog -Append -Encoding UTF8
    Write-Host $message
}

# Bypass elevation if running in ISE
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
    if ($psISE) {
        LogStep "Running in ISE – skipping elevation check."
    } else {
        LogStep "Script not running as administrator. Relaunching elevated..."
        if ($PSCommandPath) {
            Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        } else {
            LogStep "Cannot re-launch script – PSCommandPath is null."
        }
        Stop-Transcript
        exit
    }
}

# Fix TLS errors for Invoke-WebRequest
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Setup ICMP rule
LogStep "Checking if ICMPv4 firewall rule exists..."
if (-not (Get-NetFirewallRule -Name 'AllowICMPv4' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'AllowICMPv4' -DisplayName 'AllowICMPv4' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'ICMPv4' -Program 'Any' -LocalAddress 'Any' -RemoteAddress 'Any'
    LogStep "ICMPv4 rule created."
} else {
    LogStep "ICMPv4 rule already exists. Skipped."
}

# Setup WMI rule
LogStep "Checking if WMI firewall rule exists..."
if (-not (Get-NetFirewallRule -Name 'AllowWMIforPRTG' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'AllowWMIforPRTG' -DisplayName 'AllowWMIforPRTG' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'TCP' -LocalPort 135,1024-5000,49152-65535 -Program 'Any' -LocalAddress 'Any' -RemoteAddress '10.100.8.6'
    LogStep "WMI rule created."
} else {
    LogStep "WMI rule already exists. Skipped."
}

# Download and install Freshservice Agent
$drive = 'C:\Packages'
$fsApp = 'fs-windows-agent-2.9.0'
$fsPath = Join-Path $drive $fsApp
New-Item -ItemType Directory -Path $fsPath -Force | Out-Null
$fsUrl = 'https://raw.githubusercontent.com/CIPDRepo/VLZ/main/fs-windows-agent-2.9.0.msi'
$fsMsi = Join-Path $fsPath 'fs-windows-agent-2.9.0.msi'

LogStep "Downloading Freshservice Agent..."
try {
    Invoke-WebRequest -Uri $fsUrl -OutFile $fsMsi -ErrorAction Stop
    LogStep "Download successful: $fsMsi"
    LogStep "Installing Freshservice Agent..."
    Start-Process msiexec.exe -ArgumentList "/i `"$fsMsi`" /quiet /norestart" -Wait
    LogStep "Freshservice Agent installed."
} catch {
    LogStep "Failed to download or install Freshservice Agent: $_"
}

# Download and install Datto Agent
$dattoApp = 'Datto'
$dattoPath = Join-Path $drive $dattoApp
New-Item -ItemType Directory -Path $dattoPath -Force | Out-Null
$dattoUrl = 'https://raw.githubusercontent.com/CIPDRepo/VLZ/main/DattoAgent.exe'
$dattoExe = Join-Path $dattoPath 'DattoAgent.exe'

LogStep "Downloading Datto Agent..."
try {
    Invoke-WebRequest -Uri $dattoUrl -OutFile $dattoExe -ErrorAction Stop
    LogStep "Download successful: $dattoExe"
    LogStep "Installing Datto Agent..."
    Start-Process $dattoExe -ArgumentList "/install /VERYSILENT" -Wait
    LogStep "Datto Agent installed."
} catch {
    LogStep "Failed to download or install Datto Agent: $_"
}

# Disable IE Enhanced Security
function Disable-InternetExplorerESC {
    LogStep "Disabling IE ESC..."
    $adminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $userKey  = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    if (Test-Path $adminKey) {
        Set-ItemProperty -Path $adminKey -Name "IsInstalled" -Value 0
        LogStep "Admin ESC disabled."
    }
    if (Test-Path $userKey) {
        Set-ItemProperty -Path $userKey -Name "IsInstalled" -Value 1
        LogStep "User ESC enabled."
    }
    Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
    LogStep "Explorer restarted."
}
Disable-InternetExplorerESC

# Set Timezone
LogStep "Setting Timezone to GMT Standard Time..."
Set-TimeZone -Id "GMT Standard Time"
LogStep "Timezone set."

# End transcript
Stop-Transcript
