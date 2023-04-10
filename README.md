# Powershell Remote-Install-Software
# Description
This repository is intended for silent remote installation of software with Powershell.

# Usage
## Serverside
Place the contents of the "Server" folder inside a network share and insert the full path into the [RemoteInstall.psm1](./src/Client/Module/RemoteInstall.psm1) file under the "yourPath" variable.

To add software to install, run the [addSoftware.ps1](./src/Server/addSoftware.ps1) script. This will automatically create an entry in the installer.json file and copy the necessary contents to the Install directory.
## Clientside
For simplicity, you can create an .msi package with the msi_converter.ps1 script to automatically enroll the client side and later install/update your .msi package.

The client will execute the[client.ps1](./src/Client/client.ps1) script on every startup to check for mismatches on the server side and update the configuration files or install/update/uninstall software.

