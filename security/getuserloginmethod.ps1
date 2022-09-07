"""
This script does the following 
    connects to azure ad
    looks at the signin log and analyzes the method used to login
    returning the single factor auth methods as well as some other properties
"""
Add-Type -Path "C:\Users\rissa\Downloads\sqlite-netFx20-binary-bundle-x64-2005-1.0.116.0\System.Data.SQLite.dll"
$con = New-Object -TypeName System.Data.SQLite.SQLiteConnection
#$con.ConnectionString
Import-Module azureadpreview
connect-azuread

while ($true) { 
   # get-azureadauditsigninlogs -Top 999 | ? { ($_.ClientAppUsed -ne "Browser") -and ($_.ClientAppUsed -ne "Mobile Apps and Desktop clients")} | select userprincipalname,ClientAppUsed,{$_.DeviceDetail.OperatingSystem},{$_.DeviceDetail.IsManaged},{$_.Status.ErrorCode},{(get-azureaduser -SearchString $_.userprincipalname).accountenabled} -Unique | ft -AutoSize

    get-azureadauditsigninlogs -Top 999 | ? { ($_.ClientAppUsed -ne "Browser") -and ($_.ClientAppUsed -ne "Mobile Apps and Desktop clients")} | select @{l="Email";e={$_.userprincipalname}},ClientAppUsed,@{l="OS_Type";e={$_.DeviceDetail.OperatingSystem}},@{l="IsManaged?";e={$_.DeviceDetail.IsManaged}},@{l="ErrorCode";e={$_.Status.ErrorCode}},@{l="AccountEnabled";e={(get-azureaduser -SearchString $_.userprincipalname).accountenabled}} -Unique | ft -AutoSize
}

