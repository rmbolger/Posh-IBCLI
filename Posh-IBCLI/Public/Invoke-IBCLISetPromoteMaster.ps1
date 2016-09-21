function Invoke-IBCLISetPromoteMaster
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
            Position=2,
            HelpMessage='Enter the delay in seconds (0-600) between notifications to grid members.'
        )]
        [Parameter(
            ParameterSetName='ExistingStream',
            Position=1,
            HelpMessage='Enter the delay in seconds (0-600) between notifications to grid members.'
        )]
        [ValidateRange(0,600)]
        [int]
        $NotifyDelay=30,
        [Parameter(
            ParameterSetName='NewStream'
        )]
        [Switch]
        $Force
    )

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -Force:$Force -ErrorAction Stop
    }
    Write-Verbose "Promoting candidate $($ShellStream.Session.ConnectionInfo.Host) to grid master."

    try {

        # make sure this machine is actually a candidate
        $status = Get-IBCLIStatus $ShellStream
        if (!$status.IsCandidate) {
            throw "Grid member is not a master candidate."
        } else { Write-Verbose "$ComputerName is a master candidate." }

        # call set promote_master
        $output = Invoke-IBCLICommand 'set promote_master' $ShellStream

        # confirm notification delay
        if ($output[-1] -ne 'Do you want a delay between notification to Grid members? (y or n):') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set promote_master'"
        }
        if ($NotifyDelay -eq 0) {
            $output = Invoke-IBCLICommand 'n' $ShellStream
        } else {
            $output = Invoke-IBCLICommand 'y' $ShellStream

            # enter delay value
            if (!$output[-1].StartsWith('Set delay time for notification to grid member?')) {
                $output | %{ Write-Verbose $_ }
                throw "Unexpected output during 'set promote_master'"
            }
            $output = Invoke-IBCLICommand $NotifyDelay $ShellStream
        }

        # check for reporting site prompt and skip it (continue with no change)
        # until we get around to properly supporting it
        if ($output[-1].StartsWith('Please enter new primary reporting site')) {
            $output = Invoke-IBCLICommand 'c' $ShellStream
        }

        # confirmation 1
        if ($output[-1] -ne 'Are you sure you want to do this? (y or n):') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set promote_master'"
        }
        $output = Invoke-IBCLICommand 'y' $ShellStream

        # confirmation 2
        if ($output[-1] -ne 'Are you really sure you want to do this? (y or n):') {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set promote_master'"
        }
        $output = Invoke-IBCLICommand 'y' $ShellStream 2 "Master promotion beginning on this member`r`n"

        if ($output[-1] -eq 'Master promotion beginning on this member') {
            Write-Verbose "Promotion complete."
            return $true
        } else {
            $output | %{ Write-Verbose $_ }
            throw "Unexpected output during 'set promote_master'"
        }

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Promote a grid master candidate to grid master.

    .DESCRIPTION
        Runs the 'set promote_master' command and answers the follow up prompts in order to promote the target appliance to grid master.

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER NotifyDelay
        Time in seconds between notifications for grid members to join the new master. (Default: 30)

    .PARAMETER Force
        Disable SSH host key checking

    .OUTPUTS
        $true if the promotion was successful.

    .EXAMPLE
        Invoke-IBCLISetPromoteMaster 'ns2.example.com' (get-credential)

        Promotes the ns2.example.com appliance to grid master.

    .EXAMPLE
        $ShellStream = Connect-IBCLI 'ns2.example.com' (Get-Credential)
        PS C:\>Invoke-IBCLISetPromoteMaster $ShellStream 60

        Promotes the ns2.example.com appliance to grid master with a 60 second member notification delay.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    .LINK
        Connect-IBCLI

    .LINK
        Disconnect-IBCLI

    #>
}
