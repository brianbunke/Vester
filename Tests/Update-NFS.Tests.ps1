#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core

# Variables
Invoke-Expression -Command (Get-Item -Path ($PSScriptRoot + '\Config.ps1'))
[System.Collections.Hashtable]$nfsadvconfig = $global:config.nfsadvconfig
[bool]$fix = $global:config.pester.remediate

# Tests
Describe -Name 'Host Configuration: NFS Advanced Configuration' -Fixture {
    foreach ($server in (Get-VMHost).name) 
    {
        It -name "$server NFS Settings" -test {
            $value = @()
            $nfsadvconfig.Keys | ForEach-Object -Process {
                $value += (Get-AdvancedSetting -Entity $server -Name $_).Value
            }
            $compare = @()
            $nfsadvconfig.Values | ForEach-Object -Process {
                $compare += $_
            }
            try 
            {
                $value | Should Be $compare
            }
            catch 
            {
                if ($fix) 
                {
                    Write-Warning -Message $_
                    Write-Warning -Message "Remediating $server"                    
                    $nfsadvconfig.Keys | ForEach-Object -Process {
                        Get-AdvancedSetting -Entity $server -Name $_ | Set-AdvancedSetting -Value $nfsadvconfig.Item($_) -Confirm:$false -ErrorAction Stop
                    }
                }
                else 
                {
                    throw $_
                }
            }
        }
    }
}