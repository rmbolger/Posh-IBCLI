function Get-IBCLIStatus
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage='Enter the Hostname or IP Address of an Infoblox appliance.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName,
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage='Enter the credentials for the appliance.'
        )]
        [PSCredential]
        $Credential
    )

    Write-Verbose "Fetching 'show status' output from $ComputerName"
    <#
        'show status' returns one line per status item but which status
        items are returned depends on the member's role/config.

        "Grid Status" is always returned and appears to either be "ID Grid Master" or "ID Grid Member"
        "HA Status" is always returned
        "Hostname" is always returned
        "Master Candidate" is only returned on master candidates
        "Grid Master IP" is only returned on non-grid master members
    #>

    $stream = Connect-IBCLI $ComputerName $Credential -ErrorAction Stop

    try {

        # get the command output
        $output = Invoke-IBCLICommand 'show status' $stream

        # setup our hashtable to hold the parsed properties
        $props = @{}
        $props.IsCandidate = $false # default in case it's not returned

        # parse each line with a colon
        $output | ?{ $_ -like "*:*" } | %{

            # split on the colon and trim
            $key,$val = $_.Split(':') | %{ $_.Trim() }

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

        # add a synthesized IP property
        if ($props.Hostname[0] -match "^\d$") {
            # use the hostname value because it's already an IP
            $props.IPAddress = $props.Hostname
        } else {
            # Resolve the hostname using ping from the appliance
            # It's kludgy, but it works on appliances that may not
            # be fully DNS configured yet and doesn't rely on the
            # caller's DNS resolver.
            # PING infoblox.localdomain (10.10.10.10) 56(84) bytes of data.
            $line = (Invoke-IBCLICommand "ping $($props.Hostname) count 1" $stream)[1]
            $ipStart = ($line.IndexOf('(') + 1)
            $ipLength = ($line.IndexOf(')') - $ipStart)
            $props.IPAddress = $line.Substring($ipStart,$ipLength)
        }

        # Grid masters don't return a Master IP property, but it would be nice to still have
        # this info available on the output object.
        if ($props.IsMaster) {
            $props.MasterIP = $props.IPAddress
        }

        # turn the hashtable into a custom object and return it
        return (New-Object PSObject -Property $props)

    } finally {
        # always disconnect
        Disconnect-IBCLI $stream
    }



    <#
    .SYNOPSIS
        Get the status of an Infoblox appliance.

    .DESCRIPTION
        Runs the 'show status' command on the target appliance and returns the parsed result as a custom object.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .OUTPUTS
        A custom object with all of the parsed values returned from the command and some synthesized ones.
            [string] GridStatus
            [string] HAStatus
            [string] Hostname
            [string] IPAddress
            [bool]   IsMaster
            [bool]   IsCandidate
            [string] MasterIP

    .EXAMPLE
        Get-IBCLIStatus -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get the status object from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
