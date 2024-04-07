function Get_mail_sec_pwd {
    param (
        [string]$username = "",
        [string]$secPasswd = "",
        [string]$keypath = ""
    )
    $key = Get-Content $keypath
    $passwd = Get-Content $secPasswd
    $unsec_pwd = ConvertTo-SecureString -Key $key $passwd
    $VCCred = New-Object System.Management.Automation.PSCredential -ArgumentList $username,$unsec_pwd
    return $VCCred
    
}

function sendmail{
    param (
        [string]$Subject = "",
        [string]$mail_To = "",
        [string]$Body = "",
        [string]$SMTPPort = "25",
        [string]$From = "alarm@tpitc.cn",
        [string]$SMTPServer = "smtp.exmail.qq.com"
        # [string]$SMTPServer = "157.148.36.163"
        
    )
    $Passwd_sec = Get_mail_sec_pwd -username "alarm@tpitc.cn" -secPasswd "./sec_mailinfo.txt" -keypath "./aes.key"  
    # Send-MailMessage -From $From -to $mail_To  -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl -Credential $Passwd_sec -BodyAsHtml
    Send-MailMessage -From $From -to $mail_To  -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Credential $Passwd_sec -BodyAsHtml
}

# #HTML Template 
# $EmailBody = @"
# <table style="width: 68%" style="border-collapse: collapse; border: 1px solid #008080;"> 
#         <tr> 
#             <td colspan="2" bgcolor="#008080" style="color: #FFFFFF; font-size: large; height: 35px;"> 
#             Site Delete Script - Daily Report on VarReportDate </td> 
#         </tr> <tr style="border-bottom-style: solid; border-bottom-width: 1px; padding-bottom: 1px"> 
#             <td style="width: 201px; height: 35px">  Number of requests Approved</td> 
#             <td style="text-align: center; height: 35px; width: 233px;"> 
#             <b>VarApproved</b></td> </tr> 
#     <tr style="height: 39px; border: 1px solid #008080"> 
#         <td style="width: 201px; height: 39px">  Number of requests Rejected</td> 
#         <td style="text-align: center; height: 39px; width: 233px;"> 
#         <b>VarRejected</b></td> 
#     </tr> 
# </table> 
# "@

# $EmailBody2 = @"
# Alarm start time=11/09/2022 17:21:08=2
# Current refresh time=11/09/2023 17:23:12
# <table style="width: 68%" style="border-collapse: collapse; border: 1px solid #008080;"> 
#     <tr> 
#         <td colspan="2" bgcolor="#008080" style="color: #FFFFFF; font-size: large; height: 35px;"> TEST - Daily Report on TEST </td> 
#     </tr> <tr style="border-bottom-style: solid; border-bottom-width: 1px; padding-bottom: 1px"> 
#             <td style="width: 201px; height: 35px">  Number of requests Approved</td> 
#             <td style="text-align: center; height: 35px; width: 233px;"> 
#             <b>VarApproved</b></td> </tr> 
#     <tr style="height: 39px; border: 1px solid #008080"> 
#         <td style="width: 201px; height: 39px">  Number of requests Rejected</td> 
#         <td style="text-align: center; height: 39px; width: 233px;"> 
#         <b>VarRejected</b></td> 
#     </tr> 
# </table> 
# "@



# sendmail -Subject "test" -mail_To "zhangtao@yingxuntong.com" -Body $EmailBody2




