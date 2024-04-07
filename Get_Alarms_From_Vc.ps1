Import-Module -Name "./Conn-viserver.ps1"
Import-Module -Name "./Sendmail.ps1"

#判断vc是否可以连通,如果超过10秒还没连通则报错退出
if (Test-Connection 10.160.159.2 -Quiet) {
    Write-Host "Connection Test passed !!!"
    Get-Conn-VC -Listfile "./sec_vc_list.txt"
}else{
    # Write-Host "starting EasyConnect......"
    # Start-Process -FilePath "C:\Program Files (x86)\Sangfor\SSL\EasyConnect\EasyConnect.exe" -Verb RunAs 
    
    $val = 0
    while($val -ne 10){
        $val++; 
        Start-Sleep -Seconds 1
        if (Test-Connection 10.160.159.2 -Count 1 -Quiet) {   
            Write-Host "starting EasyConnect......Done"       
            break
        }
        Write-Host $val
    }

    if($val -eq 10){
        Write-Host "connect VC is failed !!!"
        sendmail -Subject "vc alarm check failed! " -Body "VC connection failed" -mail_To "zhangtao@yingxuntong.com"
        Exit

    }else{
        Write-Host "connect is successed !!!"
        Get-Conn-VC -Listfile "././sec_vc_list.txt"
    }
    
}


$vcs = "10.160.159.2","10.160.159.4","10.161.252.2"

New-Object -typename System.Text.UTF8Encoding

#从vcenter 获取其下所有数据datacenter的所有告警信息并保存入数组alarm
Function Get-TriggeredAlarms {

    param (
		$vCenter = $(throw "A vCenter must be specified.")
	)

    $rootFolder = Get-Folder -Server $vCenter -Type Datacenter

    Write-Host $rootFolder

    foreach ($ta in $rootFolder.ExtensionData.TriggeredAlarmState) {
        $alarm = "" | Select-Object VC, EntityType, Alarm, Entity, Status, Time, Acknowledged, AckBy, AckTime
        $alarm.VC = $vCenter
        $alarm.Alarm = (Get-View -Server $vCenter $ta.Alarm).Info.Name
        # $entity = Get-View -Server $vCenter $ta.Entity
        $alarm.Entity = (Get-View -Server $vCenter $ta.Entity).Name
        $alarm.EntityType = (Get-View -Server $vCenter $ta.Entity).GetType().Name	
        $alarm.Status = $ta.OverallStatus
        $alarm.Time = ($ta.Time).AddHours(8)
        if($null -ne $ta.Acknowledged){$alarm.Acknowledged = $ta.Acknowledged}
        $alarm.AckBy = $ta.AcknowledgedByUser
        if($null -ne $ta.AcknowledgedTime){$alarm.AckTime = ($ta.AcknowledgedTime).AddHours(8)}
        $alarm
    }
}

#查询列表上的所有vc告警并存入数组alarms

$alarms = @()
foreach ($vc in $vcs) {
	Write-Host "Getting alarms from $vc."
	$alarms += Get-TriggeredAlarms $vc
    Write-Host $alarms
}

#获取当前时间，并初始化日志文件
$datestr = Get-Date -Format "yyyy-MM-dd-HH.mm.ss"
$logfile = ".\checklog\vcenter-alarm.html"
$logfilebak = ".\checklog\vcenter-alarm_" + $datestr + ".html"
$errlog = ".\error.txt"
#从日志文件内获取头两行，分别是告警发生时间和上次刷新时间
if ([System.IO.File]::Exists($logfile)) {
    $headline = $(Get-Content -Path $logfile -TotalCount 1).Split("=")
    $headline2 = $(Get-Content -Path $logfile -TotalCount 2)[1]
    $headline2t = $headline2.Split("=")[1]
    #Write-Host $headline2
    $lastchktimestr = $headline[1]
    $intelval = $headline[2]
}
$curtime = Get-Date


#设置初始刷新时间，也就是第一次运行的时间 10分钟/一年/1天前
if ($lastchktimestr -eq "" -or $null -eq $lastchktimestr) {
    # $lastchktime = $curtime.AddMinutes(-10)
    #$lastchktime = $curtime.AddYears(-1)
    $lastchktime = $curtime.AddDays(-1)
} else {
    $lastchktime = [datetime]::ParseExact($lastchktimestr, "MM/dd/yyyy HH:mm:ss", $null)
 
}

#比较刷新时间，如果告警连续出现两次以上则不再记录
if ($intelval -eq "" -or $null -eq $intelval) {
    Write-Output "Alarm start time=$lastchktime=1" > $logfile
    Write-Output "Current refresh time=$curtime" >> $logfile 
}
if ($intelval -eq 1) {
    Write-Output "Alarm start time=$lastchktime=2" > $logfile 
    Write-Output "Current refresh time=$curtime" >> $logfile
}
if ($intelval -eq 2) {
    #Write-Host $headline2
    $lastchktime = [datetime]::ParseExact($headline2t, "MM/dd/yyyy HH:mm:ss", $null)
    Write-Output "Alarm start time=$lastchktime=1" > $logfile
    Write-Output "Current refresh time=$curtime" >> $logfile
}
Write-Output "<html><head><title>VMware vCenter Alarm</title></head><body>" >>$logfile

#过滤关键字，如果告警和关键字相符则忽略记录
$filter = @()
$foundalarm = 0
foreach ($al in $alarms) {
    foreach ($item in $al) {
        #Write-Host $item.VC
        foreach ($key in $filter) {
            if ($key -ne "" -and $null -ne $key -and ($item.Alarm).contains($key)) {
                Write-Output "The filter keyword is matched: $key" >> $errlog 
                $keyfound = 1
            }
        }
        if ($keyfound -eq 1) {
                $keyfound = 0
                continue
        }
        #告警信息写入日志
        $altime = [datetime]::ParseExact($item.Time, "MM/dd/yyyy HH:mm:ss", $null)
        # $altime2=$altime.AddHours(8)
        Write-Output $altime
        # Write-Output $altime2
        # Write-Output $lastchktime
        if ($altime -ge $lastchktime) {
            $foundalarm = 1
            Write-Output "found alarm!"
            if ($item.Status -match "red") {
                $wlevel = "Alert"
                Write-Output "<pre> VC:  $($item.VC)</pre>" >> $logfile
                Write-Output "<pre> Alarm object type:  $($item.EntityType)</pre>" >> $logfile 
                Write-Output "<pre> Alarm name:  <font color='red'><strong>$($item.Alarm)</strong></font></pre>" >> $logfile 
                Write-Output "<pre> Alarm object:  $($item.Entity)</pre>" >> $logfile 
                Write-Output "<pre> Level:  <font color='red'><strong>$wlevel-$($item.Status)</strong></font></pre>" >> $logfile 
                Write-Output "<pre> Start Time:  $($item.Time)</pre>" >> $logfile 
                Write-Output "<pre> Acknowledged Status:  $($item.Acknowledged)</pre>" >> $logfile
                Write-Output "<pre> Acknowledged By User:  $($item.AckBy)</pre>" >> $logfile
                Write-Output "<pre> Acknowledged Time:  $($item.AckTime)</pre>" >> $logfile
                Write-Output "<pre>--------------------------------------------</pre><br>" >> $logfile
            }
            else {
                $wlevel = "Warning"
                Write-Output "<pre> VC:  $($item.VC)</pre>" >> $logfile 
                Write-Output "<pre> Alarm object type:  $($item.EntityType)</pre>" >> $logfile 
                Write-Output "<pre> Alarm name:  <font color='orange'><strong>$($item.Alarm)</strong></font></pre>" >> $logfile 
                Write-Output "<pre> Alarm object:  $($item.Entity)</pre>" >> $logfile 
                Write-Output "<pre> Level:  <font color='orange'><strong>$wlevel-$($item.Status)</strong></font></pre>" >> $logfile 
                Write-Output "<pre> Start Time:  $($item.Time)</pre>" >> $logfile 
                Write-Output "<pre> Acknowledged Status:  $($item.Acknowledged)</pre>" >> $logfile 
                Write-Output "<pre> Acknowledged By User:  $($item.AckBy)</pre>" >> $logfile 
                Write-Output "<pre> Acknowledged Time:  $($item.AckTime)</pre>" >> $logfile 
                Write-Output "<pre>--------------------------------------------</pre><br>" >> $logfile
            }
        }
    }
 
}
if ($foundalarm -eq 0) {
    Write-Output "<pre>--------------------------------------------</pre><br>" >> $logfile 
    Write-Output "<pre>No new alarms were found!!!</pre><br>" >> $logfile 
}
Write-Output "</body></html>" >>$logfile 
#判断是否找到新的告警，并发邮件
if ($foundalarm -eq 1) {

    $mail_body = Get-Content -Path $logfile -Raw
    Write-Output $mail_body
    $Subject = "New alarm from vcenter $curtime" 
    sendmail -Subject $Subject -Body $mail_body -mail_To "zhangtao@yingxuntong.com"
}
#是否有新告警信息都直接发送邮件
# $mail_body = Get-Content -Path $logfile -Raw
# Write-Output $mail_body
# $Subject = "New alarm from vcenter $curtime" 
# sendmail -Subject $Subject -Body $mail_body -mail_To "zhangtao@yingxuntong.com"

#备份告警信息
Copy-Item $logfile $logfilebak
#记录错误日志
$Error | Add-Content $errlog 

#检查后关闭VPN


# Get-Process | Where-Object {$_.HasExited}

Remove-Conn-VC -Listfile "./sec_vc_list.txt"

#Write-Output "Stop EasyConnect...."
#$p1 = Get-Process -Name "EasyConnect"
#$p2 = Get-Process -Name "Sangfor*"
#Stop-Process $p1 -Force
#Stop-Process $p2 -Force
#Write-Output "Stop EasyConnect....Done"