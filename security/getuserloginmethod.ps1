"""
This script does the following 
    connects to azure ad
    looks at the signin log and analyzes the method used to login
    returning the single factor auth methods as well as some other properties
"""
Add-Type -Path "C:\SQLite\System.Data.SQLite.dll"

Import-Module azureadpreview


$con = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con.ConnectionString = "Data Source=C:\SQLite\db4.db"
$con.Open()
$createTableQuery = "CREATE TABLE legacy_auth(
    hash TEXT NOT NULL PRIMARY KEY,
    email TEXT NOT NULL,
    client_app_used TEXT NOT NULL,
    os_type TEXT NULL,
    is_managed TEXT NOT NULL,
    error_code INTEGER NOT NULL,
    account_enabled TEXT NOT NULL                    
);"

$CMD = $con.CreateCommand()
$CMD.CommandText = $createTableQuery
$CMD.ExecuteNonQuery() # returns 0

$CMD.Dispose()


while ($true) { 

    $rows = get-azureadauditsigninlogs -Top 999 | ? { ($_.ClientAppUsed -ne "Browser") -and ($_.ClientAppUsed -ne "Mobile Apps and Desktop clients")} #| select @{l="Email";e={$_.userprincipalname}},ClientAppUsed,@{l="OS_Type";e={$_.DeviceDetail.OperatingSystem}},@{l="IsManaged";e={$_.DeviceDetail.IsManaged}},@{l="ErrorCode";e={$_.Status.ErrorCode}},@{l="AccountEnabled";e={(get-azureaduser -SearchString $_.userprincipalname).accountenabled}} -Unique | ft -AutoSize -HideTableHeaders
  
    foreach ($row in $rows){
        $CMD = $con.CreateCommand()

        $hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::New([System.Text.Encoding]::ASCII.GetBytes($row.userprincipalname + "," + $row.client_app_used + "," + $row.DeviceDetail.OperatingSystem + "," + $row.DeviceDetail.IsManaged + "," + $row.status.ErrorCode + "," + (get-azureaduser -SearchString $row.userprincipalname).accountenabled)))
        
        $CMD.Parameters.AddWithValue("@hash", $hash.hash)
        $CMD.Parameters.AddWithValue("@email", $row.userprincipalname)
        $CMD.Parameters.AddWithValue("@client_app_used", $row.ClientAppUsed)
        $CMD.Parameters.AddWithValue("@os_type", $row.DeviceDetail.OperatingSystem)
        $CMD.Parameters.AddWithValue("@is_managed", $row.DeviceDetail.IsManaged)
        $CMD.Parameters.AddWithValue("@error_code", $row.Status.ErrorCode)
        $CMD.Parameters.AddWithValue("@account_enabled", (get-azureaduser -SearchString $row.userprincipalname).accountenabled)

        $sql = "INSERT OR REPLACE INTO legacy_auth (hash,email,client_app_used,os_type,is_managed,error_code,account_enabled)"
        $sql += " VALUES (@hash,@email,@client_app_used,@os_type,@is_managed,@error_code,@account_enabled);"
        
        $CMD.CommandText = $sql
        $CMD.ExecuteNonQuery()
        $cmd.Dispose()


    }     
 
}


