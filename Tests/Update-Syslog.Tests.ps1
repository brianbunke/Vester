#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core

# Variables
Invoke-Expression -Command (Get-Item -Path ($PSScriptRoot + '\Config.ps1'))
[array]$esxsyslog = $global:config.host.esxsyslog
[bool]$fix = $global:config.pester.remediate

# Tests
Describe -Name 'Host Configuration: Syslog Server' -Fixture {
    foreach ($server in (Get-VMHost)) 
    {
        It -name "$($server.name) Host Syslog Service State" -test {
            [array]$value = Get-VMHostSysLogServer -VMHost $server
            try 
            {
                Compare-Object -ReferenceObject $esxsyslog -DifferenceObject $value | Should Be $null
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $server"
                    Set-VMHostSysLogServer -VMHost $server -SysLogServer $esxsyslog -ErrorAction Stop
                    (Get-EsxCli -VMHost $server).system.syslog.reload()
                }
                else 
                {
                    throw $_
                }
            }
        }
    }
}