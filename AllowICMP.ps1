$vms = Get-AzVM | Select-Object ResourceGroupName,Name,Location

ForEach ($vm in $vms) {
    Set-AzVMRunCommand `
    -ResourceGroupName $vm.ResourceGroupName `
    -VMName $vm.Name `
    -RunCommandName "AllowICMPv4" `
    -Location $vm.Location `
    -SourceScript "New-NetFirewallRule -Name 'AllowICMPv4' -DisplayName 'AllowICMPv4' -Profile 'Any' -Direction 'Inbound' -Action 'Allow' -Protocol 'ICMPv4' -Program 'Any' -LocalAddress 'Any' -RemoteAddress 'Any'"
}
