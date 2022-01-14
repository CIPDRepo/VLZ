$vms = Get-AzVM | Select-Object ResourceGroupName,Name,Location

ForEach ($vm in $vms) {
    Set-AzVMRunCommand `
    -ResourceGroupName $vm.ResourceGroupName `
    -VMName $vm.Name `
    -RunCommandName "AllowICMPv4" `
    -Location $vm.Location `
    -SourceScript "New-NetFirewallRule -Name 'AllowICMPv4' -DisplayName 'AllowICMPv4' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'ICMPv4' -Program 'Any' -LocalAddress 'Any' -RemoteAddress 'Any'"
}

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
Start-Process -FilePath msiexec.exe -Args "/package $outputPath /quiet" -Wait
write-host 'Finished Install the of fs-windows-agent-2.9.0'