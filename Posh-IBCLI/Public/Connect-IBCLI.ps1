function Connect-IBCLI
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

    $session = New-SSHSession -ComputerName $ComputerName -Credential $Credential -AcceptKey -ErrorAction Stop
    $stream = New-SSHShellStream -SSHSession $session -TerminalName 'vt100'

    # pre-read the output until the first prompt
    Invoke-IBCLICommand 'show version' $stream | Out-Null

    return $stream
}
