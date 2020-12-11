Import-Module ActiveDirectory
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

$timestamp = get-date -format yyyyMMddHHmmss
$datestamp = get-date -format yyyy-MM-dd

$LogFileLocation = "D:\powershell-scripts\Logs\Exchange-EnableRemoteMailbox\errors\NewMailbox-Errors-$datestamp.txt"

start-transcript -path D:\powershell-scripts\Logs\Exchange-EnableRemoteMailbox\transcript\NewUsers-Email-$timestamp.log -noclobber

$users = Get-ADGroupMember -Identity "O365 New Mailbox Buffer"

<#
Generate a random pair of passwords
http://woshub.com/generating-random-password-with-powershell/
Import System.Web assembly
#>
Add-Type -AssemblyName System.Web
# Generate random password
$PS1 = [System.Web.Security.Membership]::GeneratePassword(22,8)
$PS2 = [System.Web.Security.Membership]::GeneratePassword(25,9)
$secPw1 = ConvertTo-SecureString -String $PS1 -AsPlainText -Force
$secPw2 = ConvertTo-SecureString -String $PS2 -AsPlainText -Force

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

<#
Script
Sign in to Azure
Sign in to AD

Disable AD account
Disable-ADAccount -Identity johndoe  
Generate random password twice 
Reset password twice
Set-ADAccountPassword -Identity johndoe -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "p@ssw0rd1" -Force)
Set-ADAccountPassword -Identity johndoe -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "p@ssw0rd2" -Force)

Hide from address list
Block Azure sign in
1. Disable the user in Azure AD. Refer to Set-AzureADUser.
PowerShellCopy
Set-AzureADUser -ObjectId johndoe@contoso.com -AccountEnabled $false
2. Revoke the user’s Azure AD refresh tokens. Refer to Revoke-AzureADUserAllRefreshToken.
PowerShellCopy
Revoke-AzureADUserAllRefreshToken -ObjectId johndoe@contoso.com
3. Disable the user’s devices. Refer to Get-AzureADUserRegisteredDevice.
PowerShellCopy
Get-AzureADUserRegisteredDevice -ObjectId johndoe@contoso.com | Set-AzureADDevice -AccountEnabled $false
Log it
https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/users-revoke-access

https://www.thecloudtechnologist.com/use-powershell-to-connect-to-exchange-online-unattended-in-a-scheduled-task/

Sign in to Azure AD Powershell with an Admin account $pwd = "Kab32@xeti491$"
**** https://docs.microsoft.com/en-us/powershell/azure/active-directory/signing-in-service-principal?view=azureadps-2.0
***** More on this https://office365itpros.com/2020/08/13/exo-certificate-based-authentication-powershell/
****** More https://www.quadrotech-it.com/blog/certificate-based-authentication-for-exchange-online-remote-powershell/ 
Roles we want to use - Device Administrators -  User Account Administrator

Steps to get AzureAD
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
 Install-PackageProvider Nuget –Force
 Register-PSRepository -Default
 Install-Module –Name PowerShellGet –Force
 Update-Module PowerShellGet -Force
 Install-Module -Name AzureAD

 An Office 365 access token is valid for an hour https://petri.com/blocking-access-office-365-user


 Code to create Azure App
 $pwd = "Kab32@xeti491$"
$notAfter = (Get-Date).AddMonths(13) # Valid for 13 months
$thumb = (New-SelfSignedCertificate -DnsName "drumkit.onmicrosoft.com" -CertStoreLocation "cert:\LocalMachine\My"  -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint
$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath c:\temp\examplecert.pfx -Password $pwd


$application = New-AzureADApplication -DisplayName "ADS-UrgentDelete" -IdentifierUris "https://rodejo2177668"
New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier "ADS-UrgentDelete" -Type AsymmetricX509Cert -Usage Verify -Value $keyValue -EndDate $notAfter

#>