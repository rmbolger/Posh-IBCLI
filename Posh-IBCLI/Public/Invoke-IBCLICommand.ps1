function Invoke-IBCLICommand
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage='Enter the Infoblox CLI command to run'
        )]
        [AllowEmptyString()]
        [string]
        $Command,
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage='The ShellStream object returned by Connect-IBCLI.'
        )]
        [ValidateNotNull()]
        [Renci.SshNet.ShellStream]
        $ShellStream
    )

    # create a regex that will match the different types of prompts
    # that the CLI would be waiting for input on.
    # The standard prompt waiting for a new command is simply 'Infoblox > ' as the final line.
    # The other type is when a command is requesting input or confirmation such as:
    # 'Enter Grid Name [Default Infoblox]: '
    # 'Are you sure? (y or n): '
    # All of the input queries seem to end with a colon-space
    $promptRegex = '(?mi)(?:^Infoblox > $|^.*: $)'

    $ShellStream.WriteLine($Command)
    $output = ''

    $timeout = 0
    while (!($output -match $promptRegex) -and $timeout -le 10)
    {
        Start-Sleep -Seconds 1
        $outPartial = $ShellStream.Read()
        Write-Verbose $outPartial
        $output += $outPartial
        $timeout++
    }

    # split the lines, discard empty lines, and trim whitespace from each line
    $lines = $output.Split("`r`n") | ?{ (!([String]::IsNullOrWhiteSpace($_))) } | %{ $_.Trim() }

    if ($lines.Count -gt 1) {
        # return all but the first line which should be the echo of the command that was sent
        return ($lines[1..($lines.length-1)])
    } else {
        # just return the single (or empty) line
        return $lines
    }



    <#
    .SYNOPSIS
        Run an Infoblox remote console CLI command and return the output.

    .DESCRIPTION
        The given command is sent to the remote CLI and the resulting output is captured and returned as a string array.

    .PARAMETER Command
        The CLI command to run on the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .OUTPUTS
        System.String[]. Invoke-IBCLICommand returns a string array that contains each non-empty line of output from the command sent. The returned lines have leading and trailing whitespace trimmed.

    .EXAMPLE
        Invoke-IBCLICommand -Command 'show status' -ShellStream $stream

        Run the 'show status' command against the appliance referenced by $stream.

    .EXAMPLE
        Invoke-IBCLICommand 'reboot' $stream
        REBOOT THE SYSTEM? (y or n):
        PS C:\>Invoke-IBCLICommand 'y' $stream
        SYSTEM REBOOTING!

        Run the 'reboot' command followed by 'y' to confirm the reboot operation.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    .LINK
        Connect-IBCLI

    .LINK
        Disconnect-IBCLI

    #>
}
