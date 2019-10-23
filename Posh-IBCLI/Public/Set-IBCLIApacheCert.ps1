function Set-IBCLIApacheCert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Serial,
        [Parameter(ParameterSetName='NewStream',Mandatory,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        [Parameter(ParameterSetName='ExistingStream',Mandatory,Position=1)]
        [ValidateNotNull()]
        [Renci.SshNet.ShellStream]$ShellStream,
        [Parameter(ParameterSetName='NewStream',Mandatory,Position=2)]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName='NewStream')]
        [Switch]$Force
    )

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -Force:$Force -ErrorAction Stop
    }

    <#
        The 'set apache_https_cert' command, is an interactive menu that lists
        the currently available certs with an index and asks to enter the index
        you want to switch to or quit with 'q'. It looks something like this:

        Current apache certificate:
            Serial: 73000000313fc79913148368ae000000000031
            Common name: ib1test.example.com

        Available certificates:
            1. Serial: 259fb5e9e47c9ea8e64ba3bba692b070 , Common name: infoblox.localdomain
            2. Serial: 641ba8024f8a93879a504a49bf58bbef , Common name: infoblox.localdomain
            3. Serial: 59b86fe0dc3337606a87ce0dedc09076 , Common name: ib1test.example.com
            4. Serial: 73000000313fc79913148368ae000000000031 , Common name: ib1test.example.com


        Select certificate (1-4) or q to quit:
    #>

    # Make sure the specified serial is an available choice
    $certs = Get-IBCLIApacheCert $ShellStream

    if ($Serial -notin $certs.Serial) {
        throw "Certificate with serial $Serial not found in the available list."
    }

    $cert = $certs | Where-Object { $_.Serial -eq $Serial }
    if ($cert.IsCurrent) {
        Write-Warning "The specified serial is already the currently active certificate. No changes will be made."
        return
    }

    # use the index from the matching cert object to set the new one
    try {

        # ignore the initial command output because we already got it via Get-IBCLIApacheCert
        Invoke-IBCLICommand 'set apache_https_cert' $ShellStream | Out-Null

        # send the appropriate index
        $output = Invoke-IBCLICommand $cert.Index $ShellStream
        if ($output[-1] -ne 'Are you sure you want to do this? (y or n):') {
            $output | ForEach-Object { Write-Verbose $_ }
            throw "Unexpected output during 'set apache_https_cert'"
        }

        $output = Invoke-IBCLICommand 'y' $ShellStream
        if ($output[-2] -ne 'Certificate updated') {
            $output | ForEach-Object { Write-Verbose $_ }
            throw "Unexpected output during 'set apache_https_cert'"
        }

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Set a new certificate for this member.

    .DESCRIPTION
        Runs the 'set apache_https_cert' command on the target appliance and selects the certificate matching the specified serial if it exists.

        Requires NIOS 8.4+

    .PARAMETER Serial
        The certificate serial number to configure for this appliance. It must have been previously imported for this command to work properly.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER Force
        Disable SSH host key checking

    .EXAMPLE
        Set-IBCLIApacheCert 38fc97d5ec7e96283aa2d1d7f1f8af8d -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Set the certificate with the specified serial number on the target appliance.

    .EXAMPLE
        $ShellStream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)
        PS C:\>Set-IBCLIApacheCert 38fc97d5ec7e96283aa2d1d7f1f8af8d $ShellStream

        Set the certificate with the specified serial number on the target appliance using an existing ShellStream.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
