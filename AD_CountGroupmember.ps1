#----------------------------------------------------------------------
#Author    : MJBCT IT/Marcin Jędorowicz
#Data      : 2025-08-13
#Version   : 1.0.0
#CopyRight : MJBCT IT/Marcin Jędorowicz
#----------------------------------------------------------------------

<#
.Synopsis
   Script for counting group membership.
.DESCRIPTION
    This script is used to count membership in AD groups. It can be used for the full group name or a part of its name..

.PARAMETER
    - groupName - precisely GroupName

    - groupPartName - part of the group name

.EXAMPLE
    .\AD_CountGroupMember.ps1 -groupName TestGroup
    Counting Member of specific Groupname in ActiveDirecotry.

.EXAMPLE
    .\AD_CountGroupMember.ps1 -groupPartName PartName
    Counting member of all group in Active Direcotry with specific part name
#>
[CmdletBinding()]
param(
    #precisely group Name
    $groupName="", 

    #part of the group name"
    $groupPartName=""
)

#Reult like a list
$result=@()

#Sum of All groups members
$resultSumAll=0

#clearing grouplist
$groupList=@()

#check which parameter was used
if($groupName -eq "" -and $groupPartName -eq ""){

    Write-Host "Please fill one of the attribute groupName or groupPartName"

}elseif($groupName -ne ""){
    
    #set list of group
    $groupList+=get-adgroup $groupName -properties * -server ((Get-ADDomain).Name + ":3268")|select samaccountname, distinguishedName|sort-object samaccountname

}else{
    #set list of group
    $groupList+=get-adgroup -filter * -properties * -server ((Get-ADDomain).Name + ":3268")|?{$_.samaccountname -like "*"+$groupPartName+"*"}|select samaccountname, distinguishedName|sort-object samaccountname
}


if($groupList.Count -gt 0){
    
    #Counter for progress activity View
    $item=0

    #for each of item on list, count group member and add to sum member of all groups
    foreach($groupItem in $groupList){
        Write-Progress -Activity ("Checing member of " + $groupItem+ " group.") -Status ("Verified: "+$item+" from: "+$groupList.count) -PercentComplete (($item / $groupList.count) * 100)
        
        $newObject=""|select-object ADgroup,ADGroupMemberCount,ADgroupDistingished
        $newObject.ADgroup = $groupItem.samaccountname
        $newObject.ADGroupMemberCount = (Get-ADGroupMember $groupItem.samaccountname -Server (($groupItem.distinguishedName -split "," | where-object {$_ -match "DC="})[0] -replace "DC=") -Recursive).count
        $newObject.ADgroupDistingished = $groupItem.distinguishedName

        $result+=$newObject
        $resultSumAll+=$newObject.ADGroupMemberCount
        $item+=1
    }
    #show result as string
    $result|Out-String

    Write-Host "Sum members of all groups " $resultSumAll
}
