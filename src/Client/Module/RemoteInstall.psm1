## Parameter
param (
    [Parameter()]
    [string] $remote_config = "<yourPath>\Server\config.json",
    [string] $local_config = ".\config.json",
    [string] $remote_installer_config = "<yourPath>\Server\installer.json",
    [string] $local_installer_config = ".\installer.json",
    [string] $local_installed = ".\installed.json",
    [string] $local_install_folder = ".\TMP",
    [string] $local_log_folder = ".\Log"
)

## Logging
# Schreiben in Log
function Write-Log() {
    [Parameter()]
    param(
        [string] $message
    )
    $datum = Get-Date -Format yyyyMMdd
    $log_datum = Get-Date -Format "dd.MM.yyy HH:mm:ss"
    $log_name = $datum + "_Log.log"
    $log_full_path = "$local_log_folder\$log_name"
    if (!(Test-Path -Path $log_full_path)) {
        New-Item -Path $local_log_folder -Name $log_name -ItemType File
    }
    $log_message = "[$log_datum] $message"
    Add-Content -Path $log_full_path -Value $log_message
}


## Basic
# Get für Dateityp der Installationsdatei
function Get-FileExtension() {
    [Parameter()]
    param(
        [string] $FileName
    )
    $start = $FileName.IndexOf(".")
    return $FileName.Substring($start)
}

# Umwandeln von JSON in Powershell-Object
function ConvertJSONToObject($path) {
    return Get-Content -Raw -Encoding utf8 -Path $path | ConvertFrom-Json
}

# Löschen aller Datein im TMP-Ordner
function Clear-InstallFolder() {
    if ((Get-ChildItem -Path $local_install_folder).Length -ne 0) {
        [System.Object] $folder_items = Get-ChildItem -Path $local_install_folder

        foreach ($item in $folder_items) {
            if ($item.Attributes -eq "Directory") {
                Remove-Item -Recurse -Force -Path $item.FullName
                Write-Log -message "Der Ordner: $item wurde gelöscht"
            }
            else {
                Remove-Item -Force -Path $item.FullName
                Write-Log -message "Die Datei: $item wurde gelöscht"
            }
        }    
    }
}


## Validation
# Check ob Dateityp installiert werden darf
function CheckFromValidExtensions() {
    [Parameter()]
    param(
        [string] $FileName
    )
    [System.Array] $ValidTypes = @(".exe", ".msi")
    return (Get-FileExtension -FileName $FileName) -in $ValidTypes
}

# Check ob EXE
function isEXE() {
    [Parameter()]
    param(
        [string] $FileName
    )

    return (Get-FileExtension -FileName $FileName) -eq ".exe"
}

# Check ob MSI
function isMSI() {
    [Parameter()]
    param(
        [string] $FileName
    )

    return (Get-FileExtension -FileName $FileName) -eq ".msi"
}

## Config Check
function CheckConfigs() {
    # config.json
    [System.Object] $config_remote = convertJSONToObject -path $remote_config
    [System.Object] $config_local = convertJSONToObject -path $local_config

    if (($config_remote.version -ne $config_local.version) -or ((Get-FileHash $remote_config).Hash -ne (Get-FileHash $local_config).Hash)) {
        Write-Log -message "Die Lokale-Config: $local_config wurde aktualisiert"
        Copy-Item -Path $remote_config -Destination $local_config -Force
    }


    # installer.json
    [System.Object] $config_local_install = convertJSONToObject -path $local_installer_config
    [System.Object] $config_remote_install = convertJSONToObject -path $remote_installer_config

    if (($config_remote_install.version -ne $config_local_install.version) -or ((Get-FileHash $remote_installer_config).Hash -ne (Get-FileHash $local_installer_config).Hash)) {
        Write-Log -message "Die Lokale-Config: $local_installer_config wurde aktualisiert"
        Copy-Item -Path $remote_installer_config -Destination $local_installer_config -Force
    }
}

## Install

### Handler
# Gather
function SoftwareHandler() {
    [System.Object] $Installs = convertJSONToObject -path $local_installer_config
    [System.Object] $Installed = convertJSONToObject -path $local_installed

    foreach ($Programm in $Installs.Software) {

        # Check ob Programm bereits installiert
        [string] $name = ($Programm | Get-Member -MemberType NoteProperty | Select-Object -Property Name).Name
        if ($name -notin $Installed.Installed) {

            # Check ob der Pfad erreichbar ist
            $install_folder = (convertJSONToObject -path $local_config)."Install_Folder"
            $program_path = $install_folder + "\" + $Programm.$name.Path
            $program_dest = $local_install_folder + "\" + $name
            if (Test-Path -Path $program_path) {

                # Kopieren des Ordners
                Copy-Item -Path $program_path -Recurse -Force -Destination $program_dest
                if (!(Test-Path -Path $program_dest)) {
                    Write-Log -message "Der Ordner unter $program_path konnte nicht nach $program_dest kopiert werden"
                }
                else {
                    Write-Log -message "Der Ordner unter $program_path wurde nach $program_dest kopiert"

                    # Ausführen der Aktion
                    [string] $Action = $Programm.$name.Action
                    [string] $exe_name = $Programm.$name."EXE_Name"
                    InstallHandler -FileName $exe_name -Action $Action -Path $program_dest
                }
            }
            else {
                Write-Log -message "Der Ordner: $program_path ist nicht erreichbar!"
            }
        }
    }
}

# Install
function InstallHandler() {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $FileName,
        [string] $Action,
        [string] $Path,
        [string] $Path_OLD
    )

    # Check ob Dateityp installiert werden darf
    if (!(CheckFromValidExtensions -FileName "$FileName")) {
        Write-Log -message "Dieser Dateityp darf nicht installiert werden!: $FileName"
        Break Script
    }
    else {
        # Check ob Installationsdatei vorhanden
        if (!(Test-Path -Path "$Path\$FileName")) {
            Write-Log -message "Die gesuchte Datei: $FileName konnte nicht unter: $Path gefunden werden"
        }
        switch ($Action.ToLower()) {
            install {
                install -FileName $FileName -Path "$Path\$FileName"
            }

            update {
                Update -FileName $FileName -Path "$Path\$FileName" -Path_OLD $Path_OLD
            }

            delete {
                Delete -FileName $FileName -Path "$Path\$FileName"
            }

            Default {
                Write-Log -message "Es wurde eine nicht gültige Aktion hinterlegt: $Action"
            }
        }
    }
}

### Update
function Update {
    [Parameter()]
    param (
        [string] $FileName,
        [string] $Path,
        [string] $Path_OLD
    )
    
    # Check ob MSI
    if (isMSI -FileName $FileName) {
        # Deinstallieren
        $msi_args_old = "/uninstall  $Path_OLD /QN"
        $return_old = Start-Process msiexec.exe -ArgumentList $msi_args_old
        If (@(0, 3010) -contains $return_old.exitcode) { 
            Write-Log "Das Programm: $FileName wurde erfolgreich deinstalliert" 
        }
        else {
            Write-Log "Das Programm: $FileName enthielt einen Fehler bei der Deinstallation" 
        }

        # Installieren
        $msi_args_new = "/i  $Path /QN"
        $return_new = Start-Process msiexec.exe -ArgumentList $msi_args_new 
        If (@(0, 3010) -contains $return_new.exitcode) { 
            Write-Log "Das Programm: $FileName wurde erfolgreich installiert" 
        }
        else {
            Write-Log "Das Programm: $FileName enthielt einen Fehler bei der Installation" 
        }

    }
    # Check ob EXE
    elseif (isEXE -FileName $FileName) {
    
    }
    else {
        Write-Log -message "Dieser Dateityp kann nicht installiert/deinstalliert werden: $FileName"
    }
}

### Install
function Install {
    [Parameter()]
    param (
        [string] $FileName,
        [string] $Path
    )
    
    # Check ob MSI
    if (isMSI -FileName $FileName) {
        $msi_args = @(
            "/i"
            $Path
            "/QN"
            "/norestart"
        )
        $return = Start-Process msiexec.exe -ArgumentList $msi_args
        If (@(0, 3010) -contains $return.exitcode) { 
            Write-Log "Das Programm: $FileName wurde erfolgreich installiert" 
        }
        else {
            Write-Log "Das Programm: $FileName enthielt einen Fehler bei der Installation" 
        }
    }
    # Check ob EXE
    elseif (isEXE -FileName $FileName) {

    }
    else {
        Write-Log -message "Dieser Dateityp kann nicht installiert werden: $FileName"
    }
}

### Delete
function Delete {
    [Parameter()]
    param (
        [string] $FileName,
        [string] $Path
    )
    
    # Check ob MSI
    if (isMSI -FileName $FileName) {
        $msi_args = "/uninstall  $Path /QN"
        $return = Start-Process msiexec.exe -ArgumentList $msi_args
        If (@(0, 3010) -contains $return.exitcode) { 
            Write-Log "Das Programm: $FileName wurde erfolgreich deinstalliert" 
        }
        else {
            Write-Log "Das Programm: $FileName enthielt einen Fehler bei der Deinstallation" 
        }
    }
    # Check ob EXE
    elseif (isEXE -FileName $FileName) {
    
    }
    else {
        Write-Log -message "Dieser Dateityp kann nicht deinstalliert werden: $FileName"
    }
}


Export-ModuleMember -Function *