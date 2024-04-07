#定义邮件服务器
$smtpServer = "smtp.exmail.qq.com"
$smtpUser = "alarm@tpitc.cn"
$smtpPassword = "jSWBwTNggivTWexd"
$mail = New-Object System.Net.Mail.MailMessage

#定义发件人邮箱地址、收件人邮箱地址
$MailAddress="alarm@tpitc.cn"
$MailtoAddress="zhangtao@yingxuntong.com"

$mail.From = New-Object System.Net.Mail.MailAddress($MailAddress)
$mail.To.Add($MailtoAddress)

#定义邮件标题、优先级和正文
$mail.Subject = "Testmail";
$mail.Priority  = "High"
$mail.Body = "Test Mail"
$smtp = New-Object System.Net.Mail.SmtpClient -argumentList $smtpServer,25 #使用25端口
$smtp.Enablessl = $true  #使用TLS加密
$smtp.Credentials = New-Object System.Net.NetworkCredential -argumentList $smtpUser,$smtpPassword
$smtp.Send($mail)

