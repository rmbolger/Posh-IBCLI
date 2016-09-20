function Get-IBCLINetwork
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

    <#
        'show network' returns a section of output per configured interface.
        Labels seem to vary primarily depending on whether the member is part
        of an HA pair or not.

        Because I don't have any IPv6 configured nodes to test with, we'll make
        a best effort to add those properties as well. But they'll likely have
        bugs until I get some more concrete output samples as the Infoblox CLI
        docs don't seem very consistent.

        Current LAN1 Network Settings:
          IPv4 Address:               10.10.10.10
          Network Mask:               255.255.255.0
          Gateway Address:            10.10.10.1
          HA enabled:                 false
          Grid Status:                Master of Infoblox Grid

        Current LAN1 Network Settings:
          Virtual IPv4 Address:       10.10.10.10
          Network Mask:               255.255.255.0
          Gateway Address:            10.10.10.1
          HA enabled:                 true
          Public Local IPv4 Address:  10.10.10.11
          HA Local IPv4 Address:      10.10.10.12
          Grid Status:                Member of Infoblox Grid

        Current Management Network Settings:
          Management Port enabled:        true
          Management IPv4 Address:        10.10.10.10
          Management Netmask:             255.255.255.0
          Management Gateway Address:     10.10.10.1
          Restrict Support and remote console access to MGMT port:        false

        Current LAN2 Network Settings:
          LAN2 Port enabled:                            true
          NIC failover for LAN1 and LAN2 enabled:       false
          LAN2 IPv4 Address:                            10.10.10.10
          LAN2 Netmask:                                 255.255.255.0
          LAN2 Gateway:                                 10.10.10.1
    #>

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -ErrorAction Stop
    }
    Write-Verbose "Fetching 'show network' output from $($ShellStream.Session.ConnectionInfo.Host)"

    try {

        # get the command output
        $output = Invoke-IBCLICommand 'show network' $ShellStream

        # setup our hashtable to hold the parsed properties
        $props = @{}

        $reInterface = "^Current (\w+) Network Settings:$"
        $curInterface = [String]::Empty

        foreach ($line in $output[0..($output.Count-2)])
        {
            if ($line -match $reInterface)
            {
                # close up the last interface object
                if ($curInterface -ne [String]::Empty) {
                    Write-Output (New-Object PSObject -Property $props)
                }

                # start the new interface object
                $props = @{}
                $curInterface = $matches[1]
                $props.IFName = $curInterface
                Write-Verbose "Found $($props.IFName) interface"

                continue
            }

            # split on the colon and trim
            $key,$val = $line.Split(':') | %{ $_.Trim() }

            if ($key -eq 'IPv4 Address' -or $key -eq 'Public Local IPv4 Address' -or $key -eq "$curInterface IPv4 Address") {
                $props.IPAddress = $val
                continue
            }
            if ($key -eq 'Network Mask' -or $key -eq "$curInterface Netmask") {
                $props.NetMask = $val
                continue
            }
            if ($key -eq 'Gateway Address' -or $key.StartsWith("$curInterface Gateway")) {
                $props.Gateway = $val
                continue
            }
            if ($key -eq 'HA Enabled') {
                $props.IsHAEnabled = [Boolean]::Parse($val)
                continue
            }
            if ($key -eq 'Virtual IPv4 Address') {
                $props.IPAddressVIP = $val
                continue
            }
            if ($key -eq 'HA Local IPv4 Address') {
                $props.IPAddressHALocal = $val
                continue
            }
            if ($key.StartsWith('Restrict Support and remote console access')) {
                $props.RestrictSupportAndConsole = [Boolean]::Parse($val)
                continue
            }
            if ($key -eq 'Grid Status') {
                $val -match "^(M(?:emb|ast)er) of ([\w\d ]+) Grid$" | Out-Null
                $props.IsMaster = $false
                if ($matches[1] -eq 'Master') { $props.IsMaster = $true }
                $props.GridName = $matches[2]
            }
            # For the rest of these properties we're just going from the CLI docs
            # and some educated guesses as I don't have any appliances to test
            # them with.
            if ($key -eq 'VLAN Tag') {
                $props.VLANTag = $val
                continue
            }
            if ($key -eq 'DSCP Value') {
                $props.DSCPValue = $val
                continue
            }
            if ($key -eq 'IPv6 Address' -or $key -eq 'Public Local IPv6 Address' -or $key -eq "$curInterface IPv6 Address") {
                $props.IPv6Address = $val
                continue
            }
            if ($key -eq 'IPv6 Gateway Address' -or $key.StartsWith("$curInterface IPv6 Gateway")) {
                $props.IPv6Gateway = $val
                continue
            }
            if ($key -eq 'IPv6 VLAN Tag') {
                $props.IPv6VLANTag = $val
                continue
            }
            if ($key -eq 'IPv6 DSCP Value') {
                $props.IPv6DSCPValue = $val
                continue
            }
        }
        # close up the last interface object
        Write-Output (New-Object PSObject -Property $props)

        return

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Get the network interface details of an Infoblox appliance.

    .DESCRIPTION
        Runs the 'show network' command on the target appliance and returns the parsed result as a custom object.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .OUTPUTS
        A custom object for each interface with all of the parsed values returned from the command and some synthesized ones. Not all of these properties will exist for every interface.
            [string] IFName
            [string] IPAddress
            [string] NetMask
            [string] Gateway
            [bool]   IsHAEnabled
            [string] IPAddressVIP
            [string] IPAddressHALocal
            [bool]   RestrictSupportAndConsole
            [bool]   IsMaster
            [string] GridName
            [string] VLANTag
            [string] DSCPValue
            [string] IPv6Address
            [string] IPv6Gateway
            [string] IPv6VLANTag
            [string] IPv6DSCPValue

    .EXAMPLE
        Get-IBCLINetwork -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get a collection of network interface objects from the target appliance.

    .EXAMPLE
        $ShellStream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)
        PS C:\>Get-IBCLINetwork $ShellStream

        Get a collection of network interface objects using an existing ShellStream from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
