#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core

# Variables
Invoke-Expression -Command (Get-Item -Path ($PSScriptRoot + '\Config.ps1'))
[bool]$sshenable = $global:config.host.sshenable
[int]$sshwarn = $global:config.host.sshwarn
[bool]$fix = $global:config.pester.remediate

# Tests
Describe -Name 'Host Configuration: SSH Server' -Fixture {
    foreach ($server in (Get-VMHost)) 
    {
        It -name "$($server.name) Host SSH Service State" -test {
            $value = $server |
            Get-VMHostService |
            Where-Object -FilterScript {
                $_.Key -eq 'TSM-SSH' 
            }
            try 
            {
                $value.Running | Should Be $sshenable
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $server"
                    if ($sshenable -eq $true) 
                    {
                        Start-VMHostService -HostService ($server |
                            Get-VMHostService |
                            Where-Object -FilterScript {
                                $_.Key -eq 'TSM-SSH' 
                        }) -ErrorAction Stop
                    }
                    if ($sshenable -eq $false) 
                    {
                        Stop-VMHostService -HostService ($server |
                            Get-VMHostService |
                            Where-Object -FilterScript {
                                $_.Key -eq 'TSM-SSH' 
                        }) -ErrorAction Stop
                    }
                }
                else 
                {
                    throw $_
                }
            }
        }
        It -name "$($server.name) Host SSH Warning State" -test {
            $value = Get-AdvancedSetting -Entity $server | Where-Object -FilterScript {
                $_.Name -eq 'UserVars.SuppressShellWarning'
            }
            try 
            {
                $value.Value | Should Be $sshwarn
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $server"
                    (Get-AdvancedSetting -Entity $server |
                        Where-Object -FilterScript {
                            $_.Name -eq 'UserVars.SuppressShellWarning'
                        } |
                    Set-AdvancedSetting -Value $sshwarn -Confirm:$false -ErrorAction Stop)
                }
                else 
                {
                    throw $_
                }
            }
        }
    }
}