#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core


[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Remediation toggle')]
    [ValidateNotNullorEmpty()]
    [switch]$Remediate,
    [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Path to the configuration file')]
    [ValidateNotNullorEmpty()]
    [string]$Config
)

Process {
    # Variables
    Invoke-Expression -Command (Get-Item -Path $Config)
    [array]$esxdns = $global:config.host.esxdns
    [array]$searchdomains = $global:config.host.searchdomains

    # Tests
    Describe -Name 'Host Configuration: DNS Server(s)' -Fixture {
        foreach ($server in (Get-VMHost -Name $global:config.scope.host)) 
        {
            It -name "$($server.name) Host DNS Address" -test {
                [array]$value = (Get-VMHostNetwork -VMHost $server).DnsAddress
                try 
                {
                    Compare-Object -ReferenceObject $esxdns -DifferenceObject $value | Should Be $null
                }
                catch 
                {
                    if ($Remediate) 
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
}