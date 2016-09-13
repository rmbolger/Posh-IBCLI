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
        $ShellStream,
        [Parameter(
            Position=2,
            HelpMessage='Enter the seconds to wait for the command to complete.'
        )]
        [int]
        $TimeoutSeconds=10
    )

    # Create a regex that will match the different types of prompts that the
    # CLI would be waiting for input on. The standard prompt waiting for a new
    # command is 'Infoblox > '. The other type is when a command is requesting
    # input or confirmation such as:
    #
    # 'Enter Grid Name [Default Infoblox]: '
    # 'Are you sure? (y or n): '
    #
    # All of the input queries seem to end with a colon-space
    $promptRegex = '(?mi)(?:^Infoblox > $|^.*: $)'

    # send the command
    $ShellStream.WriteLine($Command)

    # collect the output while waiting for a known prompt
    $startTime = Get-Date
    $output = ''
    while (!($output -match $promptRegex) -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds)
    {
        Start-Sleep -Seconds 1
        $output += $ShellStream.Read()
    }
    if (((Get-Date) - $startTime).TotalSeconds -ge $TimeoutSeconds) {
        Write-Warning "Timed out waiting for prompt."
    }
    Write-Verbose $output

    # split the lines, discard empty lines, and trim whitespace from each line
    $lines = $output.Split("`r`n") | ?{ (!([String]::IsNullOrWhiteSpace($_))) } | %{ $_.Trim() }

    if ($lines.Count -gt 1) {
        # return all but the first line (the command echo)
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

    .PARAMETER TimeoutSeconds
        The number of seconds (Default: 10) to wait for the command output to finish if a known prompt isn't recognized. If the timeout is reached, the cmdlet will return whatever output it has read up until that point.

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
