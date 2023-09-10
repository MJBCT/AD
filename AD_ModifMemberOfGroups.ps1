#----------------------------------------------------------------------
#Author    : MJBCT IT
#Data      : 2022-10-02
#Version   : 3.0.0
#CopyRight : MJBCT IT
#----------------------------------------------------------------------
<#
.SYNOPSIS
The script is used to update security group memberships within AD.
    
.DESCRIPTION
The script is used to update security group memberships within AD.

.PARAMETER
-logFolder - the parameter concerns the location of saving the log file, by default C:\Windows\System32\LogFiles
-ExchangeFQDN - the parameter of FQDN Exchange to send email with report

.EXAMPLE
    ./AD-ModifMemberOfGroups.ps1 Takie wywołanie spowoduje że log z informacjami będzie znajdowal się w domyślnym miejscu

    ./AD-ModifMemberOfGroups.ps1 -logFolder "C:\" -ExchangeFQDN "smtp.domain.local"

.INPUTS

.OUTPUTS
The result file is a log of the performed operations. The log is saved in by default path C:\Windows\System32\LogFiles\
File name :AD-Modif-MembersofGroups_"+ $date +".log"

.NOTES
    .
.LINK
    .
#>
Param(
[string] $ExchangeFQDN=, 
[string] $logFolder ="C:\Windows\System32\LogFiles" 
)


#creating log file
$date = get-date -UFormat "%Y-%m-%d"
$logfile = $logFolder +"\AD-Modif-MembersofGroups"+ $date +".log"

#Clear Cach
$Error.Clear()

#Starting log
(get-date).Tostring() + ‘ <=====----- START -----=====>‘| Out-file $logfile -append 

#information of Users
$users=get-aduser -filter * -SearchBase "OU=<organizationUnit>,DC=<Domain>,DC=local" -Properties *|`
where{(($_.userprincipalname -like "<Sufix UPN>" -and $_.userprincipalname -notlike "*test*")) -and $_.company -like "<Company>"}

#function change group members
function Update-GroupMembers($usersList,[string] $groupName, [string[]]$Descriptions, [string]$logfile){
#Creating object for loging of changed
    $newObject=""|select-object ADGroup,Descriptions,Added,Deleted,Error
        $newObject.ADGroup = $groupName
        $newObject.Descriptions = $Descriptions
        $newObject.Added = 0
        $newObject.Deleted = 0
        $newObject.Error = $Error.Clear()
try{
# list of users with specific $Descriptions   
    foreach($itemDescription in $Descriptions){
        $adUsers +=$usersList|where{($_.description -like $itemDescription)}
    }

# take member of $groupName
    $groupMembers=  Get-ADGroupMember $groupName|where{$_.objectclass -eq "User"}

    if($adUsers -eq $null -and $groupMembers -eq $null){
        (get-date).Tostring() + ‘ Zakończono edycję dla opisu ' + $Descriptions| Out-file $logfile -append 
    }
    elseif($adUsers -eq $null){
        $newObject.Deleted = $groupMembers.Count

        $groupMembers| ForEach-Object{
            Remove-ADGroupMember $groupName $_ -Confirm:$false
            (get-date).Tostring() + ' '+ $Descriptions +' usunięto ' + [string] $_.SamAccountname| Out-file $logfile -append
            }
    }
    elseif($groupMembers -eq $null){
        $newObject.Added = $adUsers.Count

        $adUsers|ForEach-Object{
            Add-ADGroupMember $groupName $_ -Confirm:$false
            (get-date).Tostring() + ' ' + $groupName +‘ dodano ' + [string] $_.SamAccountname| Out-file $logfile -append
        }
    }
    else{
        $diferrence=diff $adUsers $groupMembers -Property 'SamAccountName'
        $diferrenceInn=@($diferrence|where{$_.SideIndicator -like "<="})
        $diferrenceOut=@($diferrence|where{$_.SideIndicator -like "=>"})

        $newObject.Added = $diferrenceInn.count
        $newObject.Deleted = $diferrenceOut.count

        if($diferrenceInn){
            Add-ADGroupMember -identity $groupName -Members ($diferrenceInn|select SamAccountname)
            foreach($user in ($diferrenceInn|select SamAccountname)){
                (get-date).Tostring() + ' ' + $groupName +‘ dodano ' + [string] $user.SamAccountname| Out-file $logfile -append}
        }
        if($diferrenceOut){
            Remove-ADGroupMember -identity $groupName -Members ($diferrenceOut|select SamAccountname) -Confirm:$false
            foreach($user in ($diferrenceOut|select SamAccountname)){
                (get-date).Tostring() + ' ' + $groupName + ‘ Deleted ' + [string] $user.SamAccountname| Out-file $logfile -append}
        }
    }
}
Catch{
    $str = "issue occurred"
    (get-date).Tostring() + ‘ ‘ + [string] $str | Out-file $logfile -append 
        
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    (get-date).Tostring() + ‘ ‘ + $errorMessage | Out-file $logfile -append 
    (get-date).Tostring() + ‘ ‘ + $FailedItem | Out-file $logfile -append 
    $newObject.Error = $Error
}
finally{
(get-date).Tostring() + ‘ End editing for ' + $Descriptions| Out-file $logfile -append 
}

return $newObject
}
$wynik = @()

#using function changing member for specific group and specific description
$wynik+=Update-GroupMembers $users "AD Group" @("Description1","Description2") $logfile

#using function change member for specific group. * - means it applies to all accounts 
$wynik+=Update-GroupMembers $users "AD Group" @("*") $logfile

#infor of ending
Write-Host "Finishes script processing. More information in the file " + $logfile -ForegroundColor green
$Body = "
Made changes to group memberships:`n`n
AD Grup | Description | Added | Deleted | Error `n`n"

foreach($item in $wynik){
$Body += $item.ADGroup + " | " + $item.Descriptions+" | "+$item.Added +" | "+$item.Deleted +" | "+$item.Error+"`n
"
}
$Body +="More information in the file "+$LogFile
Send-MailMessage -SmtpServer $ExchangeFQDN -From "<SenderEmaillAddress>" -To "<RecipientEmailAddress>" -Subject "Changing AD Group" -Body $Body -Encoding UTF8

#Entering the end of the action in the LOG file
(get-date).Tostring() + ‘ <=====----- STOP -----=====>‘| Out-file $logfile -append 
