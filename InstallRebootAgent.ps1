$vms = Get-AzVM | Select-Object ResourceGroupName,Name,Location
$SourceScriptURI = 'https://raw.githubusercontent.com/CIPDRepo/VLZ/main/RebootAgent.ps1'

ForEach ($vm in $vms) {
    Set-AzVMRunCommand `
    -ResourceGroupName $vm.ResourceGroupName `
    -VMName $vm.Name `
    -RunCommandName 'InstallRebootAgent' `
    -Location $vm.Location `
    -SourceScriptUri $SourceScriptURI
}