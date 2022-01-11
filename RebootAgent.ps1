$drive = 'C:\Packages'
$appName = 'fs-windows-agent-2.9.0'
New-Item -Path $drive -Name $appName -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = $drive + '\' + $appName
Set-Location -Path $LocalPath
$URL = 'https://raw.githubusercontent.com/CIPDRepo/VLZ/main/fs-windows-agent-2.9.0.msi'
$msi = 'fs-windows-agent-2.9.0.msi'
$outputPath = $LocalPath + '\' + $msi
Invoke-WebRequest -Uri $URL -OutFile $outputPath
write-host 'Starting Install fs-windows-agent-2.9.0'
Start-Process -FilePath msiexec.exe -Args "/package $outputPath /quite" -Wait
write-host 'Finished Install the of fs-windows-agent-2.9.0'
