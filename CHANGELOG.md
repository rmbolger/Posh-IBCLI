## 1.2 (2017-03-04)

* Added GridStatus property on Get-IBCLINetwork output objects. It's one of the only ways to glean the grid name from the CLI. NOTE: It only seems to have a valid value for the LAN1 interface.

## 1.1 (2016-09-21)

* Fixed issue #7 - Added optional `-Force` flag to `Connect-IBCLI` and all other functions that use it. When used, the flag disables SSH host key checking.
* Added quick start to readme

## 1.0 (2016-09-20)

* Initial Release
* Added functions
  * Connect-IBCLI
  * Disconnect-IBCLI
  * Get-IBCLIHardwareID
  * Get-IBCLILicenses
  * Get-IBCLINetwork
  * Get-IBCLIStatus
  * Invoke-IBCLICommand
  * Invoke-IBCLISetMembership
  * Invoke-IBCLISetPromoteMaster
