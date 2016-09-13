function Get-IBCLIHardwareID
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

    Write-Verbose "Fetching 'show hwid' output from $ComputerName"
    <#
        'show hwid' returns a single line that looks something like this

        Hardware ID: 423f04d7abe9dfd536e2d1a73273be9b
    #>

    $stream = Connect-IBCLI $ComputerName $Credential -ErrorAction Stop

    try {

        # get the command output
        $output = Invoke-IBCLICommand 'show hwid' $stream

        # just a simple substring to return the ID
        return $output[0].Substring(13)

    } finally {
        # always disconnect
        Disconnect-IBCLI $stream
    }



    <#
    .SYNOPSIS
        Get the hardware ID of an Infoblox appliance.

    .DESCRIPTION
        Runs the 'show hwid' command on the target appliance and returns the result.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .EXAMPLE
        Get-IBCLIHardwareID -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get the hardware ID string from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
