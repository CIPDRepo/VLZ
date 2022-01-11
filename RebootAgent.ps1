$drive = 'C:\Packages'
$appName = 'fs-windows-agent-2.9.0'
New-Item -Path $drive -Name $appName -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = $drive + '\' + $appName
Set-Location -Path $LocalPath
$URL = 'https://github.com/CIPDRepo/VLZ/blob/45aca86dc22564d29ab35404c4ba1780797e5e14/fs-windows-agent-2.9.0.msi'
$msi = 'fs-windows-agent-2.9.0.msi'
$outputPath = $LocalPath + '\' + $msi
Invoke-WebRequest -Uri $URL -OutFile $outputPath
write-host 'Starting Install fs-windows-agent-2.9.0'
Start-Process -FilePath msiexec.exe -Args "/package $outputPath /qn" -Wait
write-host 'Finished Install the of fs-windows-agent-2.9.0'