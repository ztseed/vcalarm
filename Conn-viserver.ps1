function Get_sec_pwd {
    param (
        [string]$secPasswd = "",
        [string]$keypath = ""
    )
    $key = Get-Content $keypath
    $unsec_pwd = ConvertTo-SecureString -Key $key $secPasswd
    return $unsec_pwd
    
}


function Get-Conn-VC {

    [CmdletBinding()] 
    param (
        [string]$Listfile = "Nofile",
        [string]$VCName = "",
        [string]$UserName= "",
        [string]$Passwd = ""

    )
    if ($Listfile -eq "Nofile"){


        $secpasswd = ConvertTo-SecureString -String $Passwd -AsPlainText -Force
        $VCCred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $secpasswd


        try {
            Set-PowerCLIConfiguration -Confirm:$false -DefaultVIServerMode 'Multiple' -Scope ([VMware.VimAutomation.ViCore.Types.V1.ConfigurationScope]::User -bor [VMware.VimAutomation.ViCore.Types.V1.ConfigurationScope]::AllUsers)

            connect-viserver -server $vcServer -Credential $vcCred -AllLinked
        } catch {
            write-host "There was an error connecting to $vcServer!"
            exit -3072
        }

    }
    elseif (Test-Path -Path $Listfile){

        # Set-PowerCLIConfiguration -Confirm:$false -DefaultVIServerMode 'Multiple' -Scope ([VMware.VimAutomation.ViCore.Types.V1.ConfigurationScope]::User -bor [VMware.VimAutomation.ViCore.Types.V1.ConfigurationScope]::AllUsers)
        Set-PowerCLIConfiguration -Confirm:$false -DefaultVIServerMode 'Multiple'
        $vcinfos = Get-Content $Listfile
        foreach($vcinfo in $vcinfos){

            $vcs = $vcinfo.split(" ")
            # Write-Host $vcs[0]
            # Write-Host $vcs[1]
            # Write-Host $vcs[2]
            # $secpasswd = ConvertTo-SecureString -String $vcs[2] -AsPlainText -Force
            $secpasswd = Get_sec_pwd -secPasswd $vcs[2] -keypath "./aes.key"
            $VCCred = New-Object System.Management.Automation.PSCredential -ArgumentList $vcs[1], $secpasswd

            try {
                  connect-viserver -server $vcs[0] -Credential $vcCred -AllLinked
            } 
            catch {

                write-host "There was an error connecting to" $vcs[0]

            }
        }


    }
    else{
        Write-Host "please check your param if is right!"
    }

}

function Remove-Conn-VC {

    param (
        [string]$Listfile = "Nofile",
        [string]$VCName = ""
    )

    if ($Listfile -eq "Nofile"){

        try {
            Disconnect-VIServer -server $VCName  -Confirm:$false
            write-host "Disconnecting to" $VCName
        } catch {
            write-host "Can't Disconnecting to $VCName!"
            exit -3072
        }

    }
    elseif (Test-Path -Path $Listfile){

        $vcinfos = Get-Content $Listfile
        foreach($vcinfo in $vcinfos){

            $vcs = $vcinfo.split(" ")
            try {
                  
                Disconnect-VIServer -server $vcs[0] -Confirm:$false
                write-host "Disconnecting to" $vcs[0]
            } 
            catch {

                write-host "There was an error disconnecting to" $vcs[0]

            }
        }


    }
    else{

        Write-Output "error param ,please check!"
    }
}





#TEST

# Get-Conn-VC -Listfile "./sec_vc_list.txt"

# $hostlist = (Get-VMHost | select Name).Name

# $hostlist1 = (Get-VMHost -server 10.160.159.2 | select Name).Name
# $hostlist2 = (Get-VMHost -server 10.160.159.4 | select Name).Name



# Write-Host "On  ALL:"
# Write-Host $hostlist
# Write-Host '10.160.159.2'
# Write-Host $hostlist1
# Write-Host '10.160.159.4'
# Write-Host $hostlist2
# Remove-Conn-VC -Listfile "./sec_vc_list.txt"


# Get_sec_pwd -secPasswd "76492d1116743f0423413b16050a5345MgB8AG4AbgBWAFcAbABUAFQAdABoAE4AcgBXAEQAbwB1AGQAVwBIAEgALwB0AGcAPQA9AHwAOQA1ADAAMwBjAGMAZQA5ADMAMwBmADQAYwAzAGUAZgA0AGIAMgA0ADYANwBmADkAYQAwAGIAZgA5ADQAMgBkADkANABhADIAYwAyADMANQA5AGMAYgA4ADkAYQAyAGMANwBhAGYAMAA5ADgANQA0AGQAZAA0ADEANQA1ADUAMgA=" -keypath "./aes.key"