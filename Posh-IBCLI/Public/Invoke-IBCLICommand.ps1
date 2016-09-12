function Invoke-IBCLICommand
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage='Enter the Infoblox CLI command to run'
        )]
        [ValidateNotNullOrEmpty()]
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

    $prompt = 'Infoblox > '

    $ShellStream.WriteLine($Command)
    $output = ''

    $timeout = 0
    while (!($output.EndsWith($prompt)) -and !($output.EndsWith(': ')) -and $timeout -le 10)
    {
        Start-Sleep -Seconds 1
        $output += $ShellStream.Read()
        Write-Verbose $output
        $timeout++
    }

    # split the lines, discard empty lines, and trim whitespace from each line
    $lines = $output.Split("`r`n") | ?{ (!([String]::IsNullOrWhiteSpace($_))) } | %{ $_.Trim() }

    return $lines
}
