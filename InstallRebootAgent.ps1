$vms = Get-AzVM | Select-Object ResourceGroupName,Name,Location
$SourceScriptURI = 'https://github.com/CIPDRepo/VLZ/blob/45aca86dc22564d29ab35404c4ba1780797e5e14/RebootAgent.ps1'


ForEach ($vm in $vms) {
    Set-AzVMRunCommand `
    -ResourceGroupName $vm.ResourceGroupName `
    -VMName $vm.Name `
    -RunCommandName 'InstallRebootAgent' `
    -Location $vm.Location `
    -SourceScriptUri $SourceScriptURI
}