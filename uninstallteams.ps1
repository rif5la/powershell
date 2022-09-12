
###############
## Stop teams process

Get-Process teams | %{Stop-Process $_.id  -force -ErrorAction SilentlyContinue}

################
##REMOVE Teams User Files  
$users = ls C:\users | select -ExpandProperty name
foreach ($user in $users) {
    if (Test-Path -Path "C:\Users\$user\appdata\local\miicrosoft\teams") {
        remove-item -Recurse "C:\Users\$user\appdata\local\miicrosoft\teams" -Force
    }    
}

##################
##REMOVE REGISTRY KEY that prevents install
New-PSDrive -PSProvider registry -Name HKU -root HKEY_USERS
CD HKU:\
ls | select -ExpandProperty name | % {get-item "$_\SOFTWARE\Microsoft\Office\Teams\"}

#################
##FIREWALL RULE INSTALL
$users = Get-ChildItem (Join-Path -Path $env:SystemDrive -ChildPath 'Users') -Exclude 'Public', 'ADMINI~*'
if ($null -ne $users) {
    foreach ($user in $users) {
        $progPath = Join-Path -Path $user.FullName -ChildPath "AppData\Local\Microsoft\Teams\Current\Teams.exe"
        if (Test-Path $progPath) {
            if (-not (Get-NetFirewallApplicationFilter -Program $progPath -ErrorAction SilentlyContinue)) {
                $ruleName = "Teams.exe for user $($user.Name)"
                "UDP", "TCP" | ForEach-Object { New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Profile Domain -Program $progPath -Action Allow -Protocol $_ }
                Clear-Variable ruleName
            }
        }
        Clear-Variable progPath
    }
}


#####Download teams
Start-BitsTransfer -TransferType Download "https://statics.teams.cdn.office.net/production-windows-x64/1.5.00.21668/Teams_windows_x64.msi" "C:\windows\Temp\teams.msi"

## INSTALL APP
msiexec /i C:\windows\temp\Teams.msi OPTIONS="noAutoStart=true" ALLUSERS=1

