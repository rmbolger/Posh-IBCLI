function Get-IBCLIApacheCert {
    [CmdletBinding()]
    [OutputType('IBCLI.ApacheCert')]
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

    if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
        $ShellStream = Connect-IBCLI $ComputerName $Credential -Force:$Force -ErrorAction Stop
    }

    Write-Verbose "Fetching 'set apache_https_cert' output from $($ShellStream.Session.ConnectionInfo.Host)"
    <#
        There's no 'show apache_https_cert' command, but the 'set' equivalent
        outputs all the info we need and we can just quit the prompt without
        making changes.  It looks something like this:

        Current apache certificate:
            Serial: 73000000313fc79913148368ae000000000031
            Common name: ib1test.example.com

        Available certificates:
            1. Serial: 259fb5e9e47c9ea8e64ba3bba692b070 , Common name: infoblox.localdomain
            2. Serial: 641ba8024f8a93879a504a49bf58bbef , Common name: infoblox.localdomain
            3. Serial: 59b86fe0dc3337606a87ce0dedc09076 , Common name: ib1test.example.com
            4. Serial: 73000000313fc79913148368ae000000000031 , Common name: ib1test.example.com


        Select certificate (1-4) or q to quit:
    #>

    try {

        # make sure this appliance supports the command (NIOS 8.4+)
        $output = Invoke-IBCLICommand 'help set' $ShellStream
        if ($null -eq ($output | Where-Object { $_ -like '*set apache_https_cert*' })) {
            throw "The NIOS version on this appliance does not support the 'set apache_https_cert' command required to get the certificate info."
        }

        # get the command output
        $output = Invoke-IBCLICommand 'set apache_https_cert' $ShellStream

        $reCert = '(?<index>\d+)\. [^:]+: (?<serial>\w+) , [^:]+: (?<cn>.+)'

        $gotCurrent = $false
        for ($i=0; $i -lt $output.Count; $i++) {
            $line = $output[$i]
            if (-not $gotCurrent -and $line -like 'Current apache certificate:*') {
                $curSerial = $output[$i+1].Trim()
                $curSerial = $curSerial.Substring($curSerial.IndexOf(':')+2)
                Write-Debug $curSerial
                $curCN = $output[$i+2].Trim()
                $curCN = $curCN.Substring($curCN.IndexOf(':')+2)
                Write-Debug $curCN
                $i += 2
                $gotCurrent = $true
                continue
            }

            if ($gotCurrent -and $line -match $reCert) {
                $index = $matches['index']
                $serial = $matches['serial']
                $cn = $matches['cn']

                [pscustomobject]@{
                    PSTypeName = 'IBCLI.ApacheCert'
                    Index = $index
                    Serial = $serial
                    CommonName = $cn
                    IsCurrent = ($serial -eq $curSerial -and $cn -eq $curCN)
                }
            }

        }

        $output = Invoke-IBCLICommand 'q' $ShellStream

    } finally {
        # disconnect if we initiated the connection here
        if ($PSCmdlet.ParameterSetName -eq 'NewStream') {
            Disconnect-IBCLI $ShellStream
        }
    }



    <#
    .SYNOPSIS
        Get the list of apache certificates currently associated with this member.

    .DESCRIPTION
        Runs the 'set apache_https_cert' command on the target appliance without selecting a new certificate and returns the parsed results. The IsCurrent property will indicate whether that certificate is currently active.

        Requires NIOS 8.4+

    .PARAMETER ComputerName
        Hostname or IP Address of the Infoblox appliance.

    .PARAMETER ShellStream
        A Renci.SshNet.ShellStream object that was returned from Connect-IBCLI.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER Force
        Disable SSH host key checking

    .EXAMPLE
        Get-IBCLIApacheCert -ComputerName 'ns1.example.com' -Credential (Get-Credential)

        Get a collection of certificate objects from the target appliance.

    .EXAMPLE
        $ShellStream = Connect-IBCLI -ComputerName 'ns1.example.com' -Credential (Get-Credential)
        PS C:\>Get-IBCLIApacheCert $ShellStream

        Get a collection of certificate objects using an existing ShellStream from the target appliance.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBCLI

    #>
}
