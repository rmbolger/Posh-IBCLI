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
        $output = Get-IBCLIOutput $stream 'show status'

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
            # resolve the hostname using the appliance's resolver
            # seems more likely to work than using the caller's resolver
            # (it's also easier on legacy OSes)
            $props.IPAddress = (Get-IBCLIOutput $stream "dig $($props.Hostname) +short")[1].Trim()
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
