# Powershell Remote-Install-Software
# Description
This Repo is for silent remote installation of software with Powershell

# Usage
## Serverside
Place the contents of Server inside a network share and place the full path inside the [RemoteInstall.psm1](./src/Client/Module/RemoteInstall.psm1) under "yourPath".

To add software to install run [addSoftware.ps1](./src/Server/addSoftware.ps1) this skript will automatically create an entry inside the installer.json file and copy the contents needed to the Install directory.
## Clientside
For simplicity you can create a .msi package with the msi_converter.ps1 to automatically enroll the Clientside and later simple install update for your .msi package.

The Client will run [client.ps1](./src/Client/client.ps1) on every startup to check for missmatches on the server side and update the config files or Install/Update/Uninstall Software.

