# Import MSI-Module
Install-Module -Name PSMSI -Scope CurrentUser

# Get Variable of User
$outputPath = Read-Host "output-path"
$version = Read-Host "version"
$creator = Read-Host "creator"


# Create MSI
New-Installer -ProductName "InstallRemoteSoftware" -UpgradeCode "1baa9089-e6cf-4a5f-9fa3-39d9d33c8fd1" -Content {
    New-InstallerDirectory -PredefinedDirectoryName ProgramFilesFolder -Content {
        New-InstallerDirectory -DirectoryName "Client" -Content {
            New-InstallerDirectory -DirectoryName "Module" -Content {
                New-InstallerFile -Source .\Client\Module\BoreasInstall.psd1
                New-InstallerFile -Source .\Client\Module\BoreasInstall.psm1
            }
            New-InstallerFile -Source .\Client\client.ps1
            New-InstallerFile -Source .\Client\config.json
            New-InstallerFile -Source .\Client\installed.json
            New-InstallerFile -Source .\Client\installer.json
        }
    }
    New-InstallerDirectory -PredefinedDirectoryName StartupFolder -Content {
        New-InstallerFile -Source .\Client\startup.vbs
    }
} -OutputDirectory $outputPath -RequiresElevation -Platform x64 -Version $version -Manufacturer $creator