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

    Write-Verbose "Connecting over SSH to $ComputerName as $($Credential.UserName)"
    $session = New-SSHSession -ComputerName $ComputerName -Credential $Credential -AcceptKey -ErrorAction Stop
    $stream = New-SSHShellStream -SSHSession $session -TerminalName 'vt100'

    # pre-read the output until the first prompt
    Invoke-IBCLICommand 'show version' $stream | Out-Null

    return $stream



    <#
    .SYNOPSIS
        Connect to an Infoblox remote console.

    .DESCRIPTION
        Connect to an Infoblox appliance's remote console over SSH. Make sure the remote console feature has been enabled on the appliance first.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .OUTPUTS
        Renci.SshNet.ShellStream. Connect-IBCLI returns a stream object that is required for the rest of the Posh-IBCLI commands.

    .EXAMPLE
        $stream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Connect to an appliance using a credential retrieved interactively with Get-Credential

    .EXAMPLE
        $securePass = ConvertTo-SecureString 'mypassword' -AsPlainText -Force
        PS C:\>$cred = New-Object System.Management.Automation.PSCredential ('admin', $securePass)
        PS C:\>$stream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential $cred

        Connect to an appliance using a credential from embedded plaintext username and password. This is generally considered insecure, but works in a pinch.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    .LINK
        Invoke-IBCLICommand

    .LINK
        Disconnect-IBCLI

    #>
}
