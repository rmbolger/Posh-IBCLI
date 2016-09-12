function Disconnect-IBCLI
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage='Enter the ShellStream object returned by Connect-IBCLI.'
        )]
        [ValidateNotNull()]
        [Renci.SshNet.ShellStream]
        $ShellStream
    )

    $id = $ShellStream.SessionId
    $ShellStream.Dispose()

    Write-Verbose "Disconnecting from SSH session $id"
    Remove-SSHSession -SessionId $id | Out-Null



    <#
    .SYNOPSIS
        Disconnect from an Infoblox remote console.

    .DESCRIPTION
        Disconnect from an SSH session to an Infoblox appliance's remote console.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .EXAMPLE
        Disconnect-IBCLI $stream

        Disconnect from an appliance using a previously retrieved stream object.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    .LINK
        Connect-IBCLI

    #>
}
