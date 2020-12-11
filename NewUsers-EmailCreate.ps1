Import-Module ActiveDirectory
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

$timestamp = get-date -format yyyyMMddHHmmss
$datestamp = get-date -format yyyy-MM-dd

$LogFileLocation = "D:\powershell-scripts\Logs\Exchange-EnableRemoteMailbox\errors\NewMailbox-Errors-$datestamp.txt"

start-transcript -path D:\powershell-scripts\Logs\Exchange-EnableRemoteMailbox\transcript\NewUsers-Email-$timestamp.log -noclobber

$users = Get-ADGroupMember -Identity "O365 New Mailbox Buffer"
$O365cloudSuffix = "@towerhealth.mail.onmicrosoft.com"

#search for users with on prem mailboxes already and DO NOT RUN!!

$SMTPserver = "smtp.trhmc.org"

$from = "No-Reply-NewMailboxNotification@towerhealth.org"

$to = "TSKNewMailboxNotifications@towerhealth.org"
#$to = "wes.marderness@readinghealth.org"


$mailer = new-object Net.Mail.SMTPclient($SMTPserver)

ECHO "Start"
foreach ($line in $users)
{
	try{
		Echo "Created mailbox for $($line.SamAccountName)"
		####Checking if mailbox exists
		$HasMailbox = Get-Mailbox $line.SamAccountName
		set-aduser $line.SamAccountName -clear msExchHomeServerName
		#SetSIP 
		$UPN = $line.UserPrincipalName
		$newsip = "sip:$UPN"
		Set-ADUser $line.SamAccountName -replace @{'msRTCSIP-PrimaryUserAddress' = $newsip}
		If($HasMailbox -eq $Null){
			$HasMailbox = Get-RemoteMailbox $line.SamAccountName
		}
		#If Mailbox doesn't exist run the command to enable one in O365, if they already have one, skip this step.
		If($HasMailbox -eq $Null){
			#Errors from this command will stop further commands, and goto next iteration of loop.
			Enable-RemoteMailbox $line.SamAccountName -RemoteRoutingAddress ($line.SamAccountName+$O365cloudSuffix) -ErrorAction stop
		}
		#Check User Account to add to exception group
		$UserAccountType = Get-ADUser $line.SamAccountName -properties extensionAttribute5
		if ($UserAccountType.extensionAttribute5 -ne "E"){
			Add-ADGroupMember -Identity "O365 License Exceptions" -Members ($line)
			(get-date).Tostring() + ' @@ ' + ' ' + $line + ' Added to exception group' | Out-file $LogFileLocation -append
			$subject = "User added to O365 License Exception group by New Mailbox Process"
			$emailbody = "This user was not properly licened. $($line ), this user had to be added the O365 License Exception Group."
			$msg = new-object Net.Mail.MailMessage($from, $to, $subject, $emailbody)
			$mailer.send($msg)
			Echo "Adding to Exception group for : $($_) Sending email"
		}
		#Remove from buffer group
		Remove-ADGroupMember -Identity "O365 New Mailbox Buffer" -Members $line.SamAccountName -Confirm:$false		
	}
	catch{
		Echo $_
		Echo "There was an error processing Account $($line.SamAccountName) Check the logs"
		(get-date).Tostring() + ' @@ '+ ' There was an error processing Account ' + [string] $line.SamAccountName + ' Check logs for more detail' | Out-file $LogFileLocation -append
		(get-date).Tostring() + ' @@ ' + ' ' + [string] $_ + ' ' | Out-file $LogFileLocation -append
	}
}

ECHO "Sleeping 30sec"
Start-Sleep -s 30
ECHO "Halfway"

foreach ($line in $users)
{	
	Echo "Updating UPN for $($line.SamAccountName)"
	$userEM = Get-ADUser $line.SamAccountName -properties *
	$Address = $userEM.mail.tostring()
	$Address
	$Name = $Address.Split("@")[0]
	$newUPN = "$($Name)@towerhealth.org"
	
	Set-ADUser $line.SamAccountName -UserPrincipalName $newUPN										
	
}

stop-transcript