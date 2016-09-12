# Description

PowerShell module that makes it easier to automate Infoblox NIOS CLI commands via SSH. It is not intended to completely wrap every possible command. But it may include some common ones for information retrieval or grid administration.

The module relies heavily on the [Posh-SSH](https://github.com/darkoperator/Posh-SSH) module which itself relies on a custom version of [SSH.NET](https://github.com/sshnet/SSH.NET).

# Install

*TBD: direct install and PowerShell Gallery*

You must enable the Remote Console on the Infoblox appliance you intend to manage. This can be done via the web UI in the properties of the grid or a specific grid member in the `Security` section.

![Enable Remote Console in Web UI](/Media/Enable-Remote-Console-GUI.png)

It can also be done using the `set remote_console` command from the CLI if you already have serial access.

# Support

* Requires PowerShell v3 or later.
* Requires Posh-SSH 1.7.5 or later.
* Tested against NIOS 7.3.