# Description

This PowerShell module makes it easier to automate Infoblox NIOS CLI commands via SSH. It is not intended to completely wrap every possible command. But it may include some common ones for information retrieval or grid administration.

The module relies heavily on the [Posh-SSH](https://github.com/darkoperator/Posh-SSH) module which itself relies on a custom version of [SSH.NET](https://github.com/sshnet/SSH.NET).

# Install

To install the latest development version from git, use the following command in PowerShell v3 or later:

```
iex (invoke-restmethod https://raw.githubusercontent.com/rmbolger/Posh-IBCLI/master/instdev.ps1)
```

You can also find the [latest release](https://www.powershellgallery.com/packages/Posh-IBCLI) version in the PowerShell Gallery. If you're on PowerShell v5 or later, you can install it with `Install-Module`.

```
Install-Module -Name Posh-IBCLI
```

You must enable the Remote Console on the Infoblox appliance you intend to manage. This can be done via the web UI in the properties of the grid or a specific grid member in the `Security` section.

![Enable Remote Console in Web UI](/Media/Enable-Remote-Console-GUI.png)

It can also be done using the `set remote_console` command from the CLI if you already have serial access.

# Support

* Requires PowerShell v3 or later.
* Requires Posh-SSH 1.7.5 or later.
* Tested against NIOS 7.3.x.