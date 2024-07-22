# wait-for-domain-join.ps1
$joined = $false
$maxRetries = 12
$retryInterval = 10

for ($i = 0; $i -lt $maxRetries; $i++) {
    try {
        $domain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
        if ($domain -eq "your-domain.local") {
            Write-Output "Domain join successful."
            $joined = $true
            break
        }
    } catch {
        Write-Output "Checking domain join status..."
    }
    Start-Sleep -Seconds $retryInterval
}

if (-not $joined) {
    throw "Domain join did not complete within the expected time."
}
