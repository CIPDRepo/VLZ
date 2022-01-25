# Setup ICMPv4 Access
New-NetFirewallRule -Name 'AllowICMPv4' -DisplayName 'AllowICMPv4' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'ICMPv4' -Program 'Any' -LocalAddress 'Any' -RemoteAddress 'Any'

# Install the Freshservice Agent for Reboot
$drive = 'C:\Packages'
$appName = 'fs-windows-agent-2.9.0'
New-Item -Path $drive -Name $appName -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = $drive + '\' + $appName
Set-Location -Path $LocalPath
$URL = 'https://raw.githubusercontent.com/CIPDRepo/VLZ/main/fs-windows-agent-2.9.0.msi'
$msi = 'fs-windows-agent-2.9.0.msi'
$outputPath = $LocalPath + '\' + $msi
Invoke-WebRequest -Uri $URL -OutFile $outputPath
write-host 'Starting the install of fs-windows-agent-2.9.0'
Start-Process -FilePath msiexec.exe -Args "/package $outputPath /quiet" -Wait
write-host 'Finished the install of fs-windows-agent-2.9.0'

# Install the Datto Agent for Servium
$drive = 'C:\Packages'
$appName = 'Datto'
New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = $drive + '\' + $appName 
set-Location $LocalPath
$URL = 'https://raw.githubusercontent.com/CIPDRepo/VLZ/main/DattoAgent.exe'
$URLexe = 'DattoAgent.exe'
$outputPath = $LocalPath + '\' + $URLexe
Invoke-WebRequest -Uri $URL -OutFile $outputPath
write-host 'Starting the install of Datto Agent'
Start-Process -FilePath $outputPath -Args "/install /VERYSILENT " -Wait
write-host 'Finished the install of Datto Agent'
