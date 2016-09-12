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
    Remove-SSHSession -SessionId $id | Out-Null
}
