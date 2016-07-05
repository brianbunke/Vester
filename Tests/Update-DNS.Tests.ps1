#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core

# Variables
Invoke-Expression -Command (Get-Item -Path ($PSScriptRoot + '\Config.ps1'))
[array]$esxdns = $global:config.host.esxdns
[array]$searchdomains = $global:config.host.searchdomains
[bool]$fix = $global:config.pester.remediate

# Tests
Describe -Name 'Host Configuration: DNS Server(s)' -Fixture {
    foreach ($server in (Get-VMHost)) 
    {
        It -name "$($server.name) Host DNS Address" -test {
            [array]$value = (Get-VMHostNetwork -VMHost $server).DnsAddress
            try 
            {
                Compare-Object -ReferenceObject $esxdns -DifferenceObject $value | Should Be $null
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $server"
                    Get-VMHostNetwork -VMHost $server | Set-VMHostNetwork -DnsAddress $esxdns -ErrorAction Stop
                }
                else 
                {
                    throw $_
                }
            }
        }
        It -name "$($server.name) Host DNS Search Domain" -test {
            [array]$value = (Get-VMHostNetwork -VMHost $server).SearchDomain
            try 
            {
                Compare-Object -ReferenceObject $searchdomains -DifferenceObject $value | Should Be $null
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $server"
                    Get-VMHostNetwork -VMHost $server | Set-VMHostNetwork -SearchDomain $searchdomains -ErrorAction Stop
                }
                else 
                {
                    throw $_
                }
            }
        }
    }
}