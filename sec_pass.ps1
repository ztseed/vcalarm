
$infile = "./mail_info.txt"
$outfile = "./sec_mailinfo.txt"
$keyFile = "./aes.key"


# if($keyFile -eq "Nofile"){
    
#     $key = New-Object Byte[] 32
#     [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($key)
#     $key | out-file $keyFile
# }

# $VCIP = Read-Host "Enter vcenter IP"
# $username = Read-Host "Enter user name"
# $passwd = Read-Host "Enter Password" -AsSecureString | ConvertFrom-SecureString -key $key

$vcinfos = Get-Content $infile
$key = Get-Content $keyFile
foreach($vcinfo in $vcinfos){

    $vcs = $vcinfo.split(" ")
    $vcip = $vcs[0]
    $user = $vcs[1]
    $passwd = $vcs[2]
    $SecPwd = ConvertTo-SecureString $passwd -AsPlainText -Force
    $insecpwd = ConvertFrom-SecureString -key $key $SecPwd
    Write-Output $passwd
    Write-Output $insecpwd
    Write-Output "$vcip $user $insecpwd" >> $outfile

}

function Get_sec_pwd {
    param (
        [string]$Passwd = "",
        [string]$keyFileS = ""
    )
    $key = Get-Content $keyFileS
    $unsec_pwd = ConvertTo-SecureString -Key $key $Passwd
    return $unsec_pwd
    
}





