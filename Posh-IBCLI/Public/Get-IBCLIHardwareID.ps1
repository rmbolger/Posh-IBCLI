function Get-IBCLIHardwareID
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

    Write-Verbose "Fetching 'show hwid' output from $($ShellStream.Session.ConnectionInfo.Host)"
    <#
        'show hwid' returns a single line that looks something like this

        Hardware ID: 423f04d7abe9dfd536e2d1a73273be9b
    #>

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -Force:$Force -ErrorAction Stop
    }

    try {

        # get the command output
        $output = Invoke-IBCLICommand 'show hwid' $ShellStream

        # just a simple substring to return the ID
        return $output[0].Substring(13)

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Get the hardware ID of an Infoblox appliance.

    .DESCRIPTION
        Runs the 'show hwid' command on the target appliance and returns the result.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER Force
        Disable SSH host key checking

    .EXAMPLE
        Get-IBCLIHardwareID -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get the hardware ID string from the target appliance.

    .EXAMPLE
        $ShellStream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)
        PS C:\>Get-IBCLIHardwareID $ShellStream

        Get the hardware ID string using an existing ShellStream from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
