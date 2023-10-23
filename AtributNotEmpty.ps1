#----------------------------------------------------------------------
#Author    : MJBCT IT/Marcin Jędorowicz
#Data      : 2023-10-24
#Version   : 1.0.0
#CopyRight : MJBCT IT/Marcin Jędorowicz
#----------------------------------------------------------------------

#Case
# We need Preview only attributes with some value


# Result 1
###########

# AD User
$user = 'svc.test'

#AD Object 
$object = Get-ADUser $user -Properties *

#list of All Atributes
$listOfAtributes=$object|Get-Member|?{$_.memberType -eq "Property"}

#Table for Atributes with Value
$ParamResult=@()

#Loop for index of property
for($i=0;$i -lt ($listOfAtributes.Count -1);$i++){
    
    #param name
    $paramValue=$object.($listOfAtributes[$i].Name)

    #if param value is not Empty Add Param name to Table for atribute with value 
    if ($paramValue -notmatch $null -or $paramValue -notmatch "" -or ![string]::IsNullOrEmpty($paramValue)){
    $ParamResult+=$listOfAtributes[$i].Name}
}
#Get all parameters with Value
$object|select $ParamResult


# Result 2
###########

# AD User
$user = 'svc.test'

#AD Object 
$object = Get-ADUser $user -Properties *

#List of Atribute with some value
$ParamResult= $object.PSObject.Properties.Name.Where{![string]::IsNullOrWhiteSpace($object.$_)} | Sort-Object

#Get all parameters with Value
$object|select $ParamResult
