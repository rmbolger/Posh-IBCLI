function Get-IBCLIStatus
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
        $Credential,
        [Parameter(
            ParameterSetName='NewStream'
        )]
        [Switch]
        $Force
    )

    <#
        'show status' returns one line per status item but which status
        items are returned depends on the member's role/config.

        "Grid Status" is always returned and appears to either be "ID Grid Master" or "ID Grid Member"
        "HA Status" is always returned
        "Hostname" is always returned
        "Master Candidate" is only returned on master candidates
        "Grid Master IP" is only returned on non-grid master members
    #>

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -Force:$Force -ErrorAction Stop
    }
    Write-Verbose "Fetching 'show status' output from $($ShellStream.Session.ConnectionInfo.Host)"

    try {

        # get the command output
        $output = Invoke-IBCLICommand 'show status' $ShellStream

        # setup our hashtable to hold the parsed properties
        $props = @{}
        $props.IsCandidate = $false # default in case it's not returned

        # parse each line with a colon
        $output | Where-Object { $_ -like "*:*" } | ForEach-Object {

            # split on the colon and trim
            $key,$val = $_.Split(':') | ForEach-Object { $_.Trim() }

            switch ($key) {
                "Grid Status" { $props.GridStatus = $val }
                "HA Status" { $props.HAStatus = $val }
                "Hostname" { $props.Hostname = $val }
                "Master Candidate" { $props.IsCandidate = [Boolean]::Parse($val) }
                "Grid Master IP" { $props.MasterIP = $val }
                default { Write-Warning "Unrecognized status property: $key" }
            }
        }

        # add a synthesized IsMaster property
        $props.IsMaster = ($props.GridStatus -eq 'ID Grid Master')

        # add synthesized IsActiveHA/IsPassiveHA properties
        $props.IsActiveHA = $false
        $props.IsPassiveHA = $false
        if ($props.HAStatus -eq 'Active') {
            $props.IsActiveHA = $true
        } elseif ($props.HAStatus -eq 'Passive') {
            $props.IsPassiveHA = $true
        }

        # add a synthesized IP property which should (as far as I've tested)
        # always be the LAN1 IP which shows up as "IPv4 Address" for
        # non-HA members and "Public Local IPv4 Address" for HA members
        $lines = Invoke-IBCLICommand 'show network' $ShellStream
        $inLAN1 = $false
        foreach ($line in $lines[0..($lines.Count-2)])
        {
            if (!$inLAN1 -and $line -eq 'Current LAN1 Network Settings:') {
                $inLAN1 = $true
                continue
            }
            if ($inLAN1 -and $line -match "(?i)^(?:Public Local )?IPv4 Address:\s+(.*)") {
                $props.IPAddress = $matches[1]
                break
            }
        }
        if ([String]::IsNullOrWhiteSpace($props.IPAddress)) {
            throw "Unable to parse IP address from show network"
        }

        # Grid masters don't return a Master IP property, but it would be nice to still have
        # this property be non-null on the output object.
        if ($props.IsMaster) {
            $props.MasterIP = $props.IPAddress
        }

        # turn the hashtable into a custom object and return it
        $ret = (New-Object PSObject -Property $props)
        $ret.PSObject.TypeNames.Insert(0,'IBCLI.Status')
        return $ret

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Get the status of an Infoblox appliance.

    .DESCRIPTION
        Runs the 'show status' command on the target appliance and returns the parsed result as a custom object.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER Force
        Disable SSH host key checking

    .OUTPUTS
        A IBCLI.Status object with all of the parsed values returned from the command and some synthesized ones.
            [string] GridStatus
            [string] HAStatus
            [string] Hostname
            [string] IPAddress
            [string] MasterIP
            [bool]   IsMaster
            [bool]   IsCandidate
            [bool]   IsActiveHA
            [bool]   IsPassiveHA

    .EXAMPLE
        Get-IBCLIStatus -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get the status object from the target appliance.

    .EXAMPLE
        $ShellStream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)
        PS C:\>Get-IBCLIStatus $ShellStream

        Get the status object using an existing ShellStream from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
