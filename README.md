# Description

This PowerShell module makes it easier to automate Infoblox NIOS CLI commands via SSH. It is not intended to completely wrap every possible command. But it may include some common ones for information retrieval or grid administration.

The module relies heavily on the [Posh-SSH](https://github.com/darkoperator/Posh-SSH) module which itself relies on a custom version of [SSH.NET](https://github.com/sshnet/SSH.NET).

# Install

To install the latest development version from git, use the following command in PowerShell v3 or later:

```powershell
iex (invoke-restmethod https://raw.githubusercontent.com/rmbolger/Posh-IBCLI/main/instdev.ps1)
```

You can also find the [latest release](https://www.powershellgallery.com/packages/Posh-IBCLI/) version in the PowerShell Gallery. If you're on PowerShell v5 or later, you can install it with `Install-Module`.

```powershell
Install-Module -Name Posh-IBCLI
```

You must enable the Remote Console on the Infoblox appliance you intend to manage. This can be done via the web UI in the properties of the grid or a specific grid member in the `Security` section.

![Enable Remote Console in Web UI](/Media/Enable-Remote-Console-GUI.png)

It can also be done using the `set remote_console` command from the CLI if you already have serial access.

# Quick Start

Almost all of the functions available require an IP/hostname and a [PSCredential](https://msdn.microsoft.com/en-us/library/system.management.automation.pscredential(v=vs.85).aspx) to establish a connection to a NIOS appliance. *It is wise to make sure your IP/credentials work from a normal SSH client before trying them with the module.*

```powershell
$myhost = '10.10.10.10'
$cred = Get-Credential
```

In the simplest case, you can just run one of the `Get-*` commands directly with your connection variables.

```powershell
Get-IBCLIStatus $myhost $cred
```

For automation or scripting scenarios, you're likely to run multiple commands against the same appliance or might need to run commands that haven't already been wrapped by functions.  In these cases, you'll use `Connect-IBCLI` to get a `ShellStream` object that you can pass to subsequent commands. This helps with speed and efficiency because the functions won't need to establish multiple SSH connections to the appliance.

```powershell
$stream = Connect-IBCLI $myhost $cred
```

Once you have your `ShellStream` object, you can use it with the various wrapped commands or arbitrary commands using `Invoke-IBCLICommand`.

```powershell
Get-IBCLIStatus $stream
Invoke-IBCLICommand 'show capacity' $stream
```

For CLI commands that aren't already wrapped by functions and have interactive prompts, you can just use multiple `Invoke-IBCLICommand` calls in succession.

```powershell
PS > Invoke-IBCLICommand 'set delete_tasks_interval 13' $stream
Current delete tasks interval is 14 days
The delete tasks interval has been changed to 13 days
Is this correct? (y or n):
PS > Invoke-IBCLICommand 'y' $stream
The delete tasks interval has been changed.
Infoblox >
```

Don't forget to disconnect when you're done.

```powershell
Disconnect-IBCLI $stream
```

# Requirements and Platform Support

* Requires PowerShell v3 or later.
* Requires Posh-SSH 1.7.5 or later.
* Tested against NIOS 7.3.x.

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)
