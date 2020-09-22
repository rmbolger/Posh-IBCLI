@{

RootModule = 'Posh-IBCLI.psm1'
ModuleVersion = '1.3.0'
GUID = '2585edfb-b7d2-4857-9b13-a73633b56a86'
Author = 'Ryan Bolger'
Copyright = '(c) 2019 Ryan Bolger. All rights reserved.'
Description = 'PowerShell module that makes it easier to automate Infoblox NIOS CLI commands via SSH.'
PowerShellVersion = '3.0'

RequiredModules = @('Posh-SSH')

FormatsToProcess = 'Posh-IBCLI.Format.ps1xml'

FunctionsToExport = @(
    'Connect-IBCLI'
    'Disconnect-IBCLI'
    'Get-IBCLIApacheCert'
    'Get-IBCLIHardwareID'
    'Get-IBCLILicenses'
    'Get-IBCLINetwork'
    'Get-IBCLIStatus'
    'Invoke-IBCLICommand'
    'Invoke-IBCLISetMembership'
    'Invoke-IBCLISetPromoteMaster'
    'Set-IBCLIApacheCert'
)

CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()

PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Infoblox','IPAM'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-IBCLI/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-IBCLI'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
* Added `Get-IBCLIApacheCert` and `Set-IBCLIApacheCert` to allow manipulation of the web UI certificate on a grid member. These require a CLI command that exists in NIOS 8.4+ and will throw an error on earlier versions.
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
