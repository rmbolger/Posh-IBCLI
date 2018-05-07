#Requires -Version 3.0

# grab Posh-SSH if it's not installed
if (!(Get-Module Posh-SSH -ListAvailable)) {
    $answer = Read-Host "Posh-SSH not found. Download and Install? [y/n]: "
    if ($answer -eq 'y') {
        iex (Invoke-RestMethod 'https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev')
    }
}

# create user-specific modules folder if it doesn't exist
$targetondisk = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
New-Item -ItemType Directory -Force -Path $targetondisk | out-null

if ([String]::IsNullOrWhiteSpace($PSScriptRoot)) {
    # likely running from online, so download and extract
    $webclient = New-Object System.Net.WebClient
    $url = 'https://github.com/rmbolger/Posh-IBCLI/archive/master.zip'
    Write-Host "Downloading latest version of Posh-IBCLI from $url" -ForegroundColor Cyan
    $file = "$($env:TEMP)\Posh-IBCLI.zip"

    # GitHub now requires TLS 1.2
    # https://blog.github.com/2018-02-23-weak-cryptographic-standards-removed/
    $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__,[Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }

    $webclient.DownloadFile($url,$file)
    Write-Host "File saved to $file" -ForegroundColor Green
    $shell_app=new-object -com shell.application
    $zip_file = $shell_app.namespace($file)
    Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
    $destination = $shell_app.namespace($targetondisk)
    $destination.Copyhere($zip_file.items(), 0x10)
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item "$($targetondisk)\Posh-IBCLI-master\Posh-IBCLI" $targetondisk -Recurse -Force
    Remove-Item "$($targetondisk)\Posh-IBCLI-master" -recurse -confirm:$false
    Import-Module -Name Posh-IBCLI
} else {
    # running locally
    Copy-Item "$PSScriptRoot\Posh-IBCLI" $targetondisk -Recurse -Force
    # force re-load the module (assuming you're editing locally and want to see changes)
    Import-Module -Name Posh-IBCLI -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module Posh-IBCLI
