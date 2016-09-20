function Get-IBCLILicenses
{
    [CmdletBinding()]
    param(
        [Parameter(
            ParameterSetName='NewStream',
            Mandatory=$true,
            Position=0,
            HelpMessage='Enter the Hostname or IP Address of an Infoblox appliance.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName,
        [Parameter(
            ParameterSetName='ExistingStream',
            Mandatory=$true,
            Position=0,
            HelpMessage='Enter the ShellStream object returned by Connect-IBCLI.'
        )]
        [ValidateNotNull()]
        [Renci.SshNet.ShellStream]
        $ShellStream,
        [Parameter(
            ParameterSetName='NewStream',
            Mandatory=$true,
            Position=1,
            HelpMessage='Enter the credentials for the appliance.'
        )]
        [PSCredential]
        $Credential
    )

    Write-Verbose "Fetching 'show license csv' output from $($ShellStream.Session.ConnectionInfo.Host)"
    <#
        'show license csv' returns CSV formatted output of all the licenses
        on that member. If the appliance is a grid master, it will return
        all the licenses in the grid. Sample output:

        public_ip,license_type,exp_date,replaced_hardware_id,license_string
        10.1.1.1,Grid,11/09/2016,,GQAAAEm0SGfKtggLHTJvy3v5iA/jTWP/Ezo7w8E=
        10.1.1.1,vNIOS (model IB-VM-810),11/09/2016,,GQAAAFq0VW3LukhREm5vy3i0hw/gWWP4Sz9qysE=
        10.1.1.1,DNS,11/09/2016,,EgAAAEi0T36K9QZbEmUjyH750kvoSw==
        10.1.1.1,DHCP,11/09/2016,,EwAAAEiyX3LE9EkeVyshyXmzzUrkSzQ=
        10.2.2.2,Grid,11/09/2016,,GQAAAHkkdF6RlSaK81y3fgDfOPvJkaP5jpOBov0=
        10.2.2.2,vNIOS (model IB-VM-810),11/09/2016,,GQAAAGokaVSQmWbQ/AC3fgOSN/vKhaP+1pbQq/0=
        10.2.2.2,DNS,11/09/2016,,EgAAAHgkc0fR1ija/Av7fQXfYr/Clw==
        10.2.2.2,DHCP,11/09/2016,,EwAAAHgiY0uf12efuUX5fAKVfb7Ol/Q=
    #>

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -ErrorAction Stop
    }

    try {

        # the current hardware ID is only returned when you use 'show license'
        # by itself. But we can still get it separately first.
        $hwid = Get-IBCLIHardwareID $ShellStream
        Write-Verbose $hwid

        # If this is a grid master, the 'show license csv' command will return
        # all licenses in the grid differentiated by IP address of the member.
        # So we need to get this member's IP to filter the results with.
        $ip = (Get-IBCLIStatus $ShellStream).IPAddress

        # get the command output and parse the csv
        $output = Invoke-IBCLICommand 'show license csv' $ShellStream
        $csv = $output[0..($output.length-2)] | ConvertFrom-Csv

        $ret = $csv | ?{ $_.public_ip -eq $ip } |
            Select `
            @{L='LicenseType';E={$_.license_type}}, `
            @{L='LicenseString';E={$_.license_string}}, `
            @{L='HardwareID';E={$hwid}}, `
            @{L='Expiration';E={
                $outdate = [DateTime]::MinValue
                if ([DateTime]::TryParse($_.exp_date,[ref]$outdate)) {
                    $outdate
                } else {
                    # unparseable usually means 'Permanent'
                    [DateTime]::MaxValue
                }
            }}

        # inject the type name for each result
        $ret | %{
            $_.PSObject.TypeNames.Insert(0,'Dvolve.IBCLI.License')
        }

        return $ret

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Get the licenses installed on an Infoblox appliance.

    .DESCRIPTION
        Runs the 'show license csv' command on the target appliance and returns the parsed result as a set of License objects.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .OUTPUTS
        A Dvolve.IBCLI.License object for each license with all of the parsed values returned from the command. Permanent licenses will have Expiration set to DateTime.MaxValue (https://msdn.microsoft.com/en-us/library/system.datetime.maxvalue(v=vs.110).aspx).
            [string] LicenseType
            [string] LicenseString
            [DateTime] Expiration
            [string] HardwareID

    .EXAMPLE
        Get-IBCLILicenses -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get the license objects from the target appliance.

    .EXAMPLE
        $ShellStream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)
        PS C:\>Get-IBCLILicenses $ShellStream

        Get the license object using an existing ShellStream from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
