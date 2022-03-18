####### Set Auto Connect  #######
$VPNName = "AOVPN"
$currentUser = (Get-CimInstance -ClassName WIn32_Process -Filter 'Name="explorer.exe"' | Invoke-CimMethod -MethodName GetOwner)[0]
$requiredFolder = "C:\Users\$($currentUser.user)\AppData\Roaming\Microsoft\Network\Connections\Pbk"
$rasManKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Config"


function Get-CurrentUserSID {
[CmdletBinding()]

$sid = $(whoami /user)
$ndx = (($sid | Select-String -Pattern '^(=+ =+)$').Matches.Groups[1].Value).IndexOf(' ')
return $sid[$sid.Length - 1].Substring($ndx + 1)
}

#region Functions
function Convert-HexToByte {
  [cmdletbinding()]
  param (
    [string]$HexString
  )
  $splitString = ($HexString -replace '(..)','$1,').Trim(',')
  [byte[]]$hexified = $splitString.Split(',') | ForEach-Object { "0x$_"}
  return $hexified
}

function Set-ComputerRegistryValues {
  param (
      [Parameter(Mandatory = $true)]
      [array]$RegistryInstance
  )
  try {
      foreach ($key in $RegistryInstance) {
          $keyPath = $key.Path
          if (!(Test-Path $keyPath)) {
              Write-Host "Registry path : $keyPath not found. Creating now." -ForegroundColor Green
              New-Item -Path $key.Path -Force | Out-Null
              Write-Host "Creating item property: $($key.Name)" -ForegroundColor Green
              New-ItemProperty -Path $keyPath -Name $key.Name -Value $key.Value -Type $key.Type -Force
          }
          else {
              Write-Host "Creating item property: $($key.Name)" -ForegroundColor Green
              New-ItemProperty -Path $keyPath -Name $key.Name -Value $key.Value -Type $key.Type -Force
          }
      }
  }
  catch {
      Throw $_.Exception.Message
  }
}
#endregion

#region Configure Always On
$regKeys = @(
  @{
    Path = $rasManKeyPath
    Name = 'AutoTriggerDisabledProfilesList'
    Value = $null
    Type = 'MultiString'
  }
  @{
    Path = $rasManKeyPath
    Name = 'AutoTriggerProfilePhonebookPath'
    Value = "$RequiredFolder\rasphone.pbk"
    Type = 'String'
  }
  @{
    Path = $rasManKeyPath
    Name = 'AutoTriggerProfileEntryName'
    Value = $VPNName
    Type = 'String'
  }
@{
    Path = $rasManKeyPath
    Name = 'UserSID'
    Value = Get-CurrentUserSID
    Type = 'String'
  }
@{
    Path = $rasManKeyPath
    Name = 'AutoTriggerProfileGUID'
    Value = Convert-HexToByte -HexString $vpnGuid
    Type = 'Binary'
  }
@{
    Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\RasMan'
    Name = 'Start'
    Value = 2
    Type = 'DWord'
}
)
Set-ComputerRegistryValues $regKeys
#endregion
