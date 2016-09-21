function Invoke-IBCLISetMembership
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
            ParameterSetName='NewStream',
            Mandatory=$true,
            Position=2,
            HelpMessage='Enter the Hostname or IP Address of the grid master.'
        )]
        [Parameter(
            ParameterSetName='ExistingStream',
            Mandatory=$true,
            Position=1,
            HelpMessage='Enter the Hostname or IP Address of the grid master.'
        )]
        [string]
        $GridMaster,
        [Parameter(
            ParameterSetName='NewStream',
            Mandatory=$true,
            Position=3,
            HelpMessage='Enter the name of the grid.'
        )]
        [Parameter(
            ParameterSetName='ExistingStream',
            Mandatory=$true,
            Position=2,
            HelpMessage='Enter the name of the grid.'
        )]
        [string]
        $GridName,
        [Parameter(
            ParameterSetName='NewStream',
            Mandatory=$true,
            Position=4,
            HelpMessage='Enter grid shared secret.'
        )]
        [Parameter(
            ParameterSetName='ExistingStream',
            Mandatory=$true,
            Position=3,
            HelpMessage='Enter grid shared secret.'
        )]
        [string]
        $GridSecret,
        [Parameter(
            ParameterSetName='NewStream'
        )]
        [Switch]
        $Force
    )

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -Force:$Force -ErrorAction Stop
    }
    Write-Verbose "Joining $($ShellStream.Session.ConnectionInfo.Host) to $GridName grid on master $GridMaster."

    try {

        # call set membership
        $output = Invoke-IBCLICommand 'set membership' $ShellStream

        # enter grid master
        if ($output[-1] -ne 'Enter new Grid Master VIP:') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set membership'"
        }
        $output = Invoke-IBCLICommand $GridMaster $ShellStream

        # enter grid name
        if ($output[-1] -ne 'Enter Grid Name [Default Infoblox]:') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set membership'"
        }
        $output = Invoke-IBCLICommand $GridName $ShellStream

        # enter grid secret
        if ($output[-1] -ne 'Enter Grid Shared Secret:') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set membership'"
        }
        $output = Invoke-IBCLICommand $GridSecret $ShellStream

        # confirmation 1
        if ($output[-1] -ne 'Is this correct? (y or n):') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set membership'"
        }
        $output = Invoke-IBCLICommand 'y' $ShellStream

        # confirmation 2
        if ($output[-1] -ne 'Are you sure? (y or n):') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set membership'"
        }
        $output = Invoke-IBCLICommand 'y' $ShellStream 2 "until it has been configured on the grid master.`r`n"

        if ($output[-1] -eq 'until it has been configured on the grid master.') {
            Write-Verbose "Join complete. Member restarting."
            return $true
        } else {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set membership'"
        }

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Join an Infoblox appliance to a grid.

    .DESCRIPTION
        Runs the 'set membership' command and answers the follow up prompts in order to join the target appliance to a grid.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER GridMaster
        Hostname or IP Address of the grid master.

    .PARAMETER GridName
        The cosmetic name of the grid. 'Infoblox' is the default value on a new appliance.

    .PARAMETER GridSecret
        The grid's shared secret value used to join new members.

    .PARAMETER Force
        Disable SSH host key checking

    .OUTPUTS
        $true if the join was successful.

    .EXAMPLE
        Invoke-IBCLISetMembership 'ns2.example.com' (get-credential) 'ns1.example.com' 'MyGrid' 'MySecret'

        Joins the ns2.example.com appliance to the grid called MyGrid running on ns1.example.com.

    .EXAMPLE
        $ShellStream = Connect-IBCLI 'ns2.example.com' (Get-Credential)
        PS C:\>Invoke-IBCLISetMembership $ShellStream 'ns1.example.com' 'MyGrid' 'MySecret'

        Joins the ns2.example.com appliance to the grid called MyGrid running on ns1.example.com.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    .LINK
        Connect-IBCLI

    .LINK
        Disconnect-IBCLI

    #>
}
