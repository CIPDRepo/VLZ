[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint a, X509Certificate b, WebRequest c, int d) { return true; }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$ErrorActionPreference = 'Stop'
$global:HadErrors = $false

$logDir = "C:\Temp"
$transcriptLog = Join-Path $logDir "setup_log.txt"
$stepsLog = Join-Path $logDir "setup_log_steps.txt"
$packagesRoot = "C:\Packages"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null
New-Item -ItemType Directory -Path $packagesRoot -Force | Out-Null

function LogStep { param([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "$timestamp`t$Message" | Out-File -FilePath $stepsLog -Append -Encoding UTF8
  Write-Host $Message
}

function Try-Step { param([scriptblock]$Action,[string]$OnSuccess,[string]$OnError)
  try { & $Action; if ($OnSuccess) { LogStep $OnSuccess } }
  catch { $global:HadErrors = $true; LogStep "$($OnError): $($_.Exception.Message)" }
}

# Helper: download file
function Get-File { param([Parameter(Mandatory)][string]$Uri,[Parameter(Mandatory)][string]$OutFile)
  Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
}

# Helper: wait for a process with timeout
function Wait-ForExitOrTimeout {
  param([System.Diagnostics.Process]$Process,[int]$TimeoutSeconds = 600)
  if (-not $Process) { return $true }
  return $Process.WaitForExit($TimeoutSeconds * 1000)
}

# Helper: detect Datto installed/running
function Test-DattoPresent {
  try {
    $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Datto*" -or $_.DisplayName -like "Datto*" }
    $proc = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Datto*" }
    return ($svc -or $proc)
  } catch { return $false }
}

Start-Transcript -Path $transcriptLog -Append

Try-Step -Action {
  if (-not (Get-NetFirewallRule -Name 'AllowICMPv4' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'AllowICMPv4' -DisplayName 'AllowICMPv4' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'ICMPv4' -Program 'Any' -LocalAddress 'Any' -RemoteAddress 'Any' | Out-Null
  }
} -OnSuccess "ICMPv4 rule ensured." -OnError "Failed to ensure ICMPv4 firewall rule"

Try-Step -Action {
  if (-not (Get-NetFirewallRule -Name 'AllowWMIforPRTG' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'AllowWMIforPRTG' -DisplayName 'AllowWMIforPRTG' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'TCP' -LocalPort 135,1024-5000,49152-65535 -Program 'Any' -LocalAddress 'Any' -RemoteAddress '10.100.8.6' | Out-Null
  }
} -OnSuccess "WMI rule ensured." -OnError "Failed to ensure WMI firewall rule"

Try-Step -Action {
  $fsDir = Join-Path $packagesRoot "fs-windows-agent-2.9.0"
  New-Item -ItemType Directory -Path $fsDir -Force | Out-Null
  $fsMsi = Join-Path $fsDir "fs-windows-agent-2.9.0.msi"
  $fsUrl = "https://raw.githubusercontent.com/CIPDRepo/VLZ/main/fs-windows-agent-2.9.0.msi"
  LogStep "Downloading Freshservice Agent..."
  Get-File -Uri $fsUrl -OutFile $fsMsi
  LogStep "Installing Freshservice Agent..."
  $p = Start-Process msiexec.exe -ArgumentList "/i `"$fsMsi`" /quiet /norestart" -PassThru
  if (-not (Wait-ForExitOrTimeout -Process $p -TimeoutSeconds 600)) { throw "Timeout waiting for Freshservice MSI to exit" }
  if ($p.ExitCode -ne 0) { throw "MSI exit code: $($p.ExitCode)" }
} -OnSuccess "Freshservice Agent installed." -OnError "Failed to install Freshservice Agent"

Try-Step -Action {
  $dattoDir = Join-Path $packagesRoot "Datto"
  New-Item -ItemType Directory -Path $dattoDir -Force | Out-Null
  $dattoExe = Join-Path $dattoDir "DattoAgent.exe"
  $dattoUrl = "https://raw.githubusercontent.com/CIPDRepo/VLZ/main/DattoAgent.exe"
  LogStep "Downloading Datto Agent..."
  Get-File -Uri $dattoUrl -OutFile $dattoExe
  LogStep "Installing Datto Agent..."
  $args = "/install /VERYSILENT /NORESTART /SUPPRESSMSGBOXES"
  $p = Start-Process $dattoExe -ArgumentList $args -PassThru
  if (-not (Wait-ForExitOrTimeout -Process $p -TimeoutSeconds 600)) {
    LogStep "Datto installer did not exit within timeout. Checking if agent is present..."
    if (Test-DattoPresent) {
      LogStep "Datto agent appears installed/running; proceeding."
    } else {
      throw "Timeout waiting for Datto installer and agent not detected"
    }
  } else {
    if ($p.ExitCode -ne 0) { throw "Datto installer exit code: $($p.ExitCode)" }
  }
} -OnSuccess "Datto Agent installed (or already present)." -OnError "Failed to install Datto Agent"

Try-Step -Action {
  LogStep "Configuring IE ESC..."
  $adminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
  $userKey  = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
  if (Test-Path $adminKey) { Set-ItemProperty -Path $adminKey -Name "IsInstalled" -Value 0 -Force }
  if (Test-Path $userKey)  { Set-ItemProperty -Path $userKey  -Name "IsInstalled" -Value 1 -Force }
  Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
} -OnSuccess "IE ESC configured." -OnError "Failed to configure IE ESC"

Try-Step -Action {
  LogStep "Setting Timezone to GMT Standard Time..."
  Set-TimeZone -Id "GMT Standard Time"
} -OnSuccess "Timezone set to GMT Standard Time." -OnError "Failed to set timezone"

Stop-Transcript

if ($global:HadErrors) { exit 1 } else { exit 0 }
