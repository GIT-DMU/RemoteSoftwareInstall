# Erstellt durch: DMU
# Letze Änderung am: 28.11.2022
# Inhalt der Änderungen:
#   28.11.2022: Erste Erstellung von Config/Powershell
# Parameter
[CmdletBinding()]
param (
    [Parameter()]
    [string] $Path,
    [string] $Action,
    [string] $Name,
    [string] $exe_name,
    [string] $Path_OLD,
    [string] $config_path = ".\installer.json",
    [string] $install_path = ".\Install",
    [System.Object]$json_file
)

function getJSONData() {
    # Importieren der aktuellen JSON-Datei
    return Get-Content -Raw -Encoding utf8 $config_path | ConvertFrom-Json
}

function ReadInputs() {
    $Title = "Aktion"
    $Info = "Bitte Aktion wählen"
    $options = Write-Output "Install", "Update", "Delete"
    $defaultchoice = 0
    $selected = $HOST.UI.PromptForChoice($Title, $Info, $options, $defaultchoice)
    $Action = $options[$selected]
    switch ($Action) {
        Install {
            # Abfragen der Inputs
            $Path = Read-Host "Bezeichnung"
            $exe_name = Read-Host "Pfad der Installationdatei"
        }

        Update {
            # Abfragen der Inputs
            $Path = Read-Host "Bezeichnung"
            $exe_name = Read-Host "Pfad der Installationdatei"
            $Path_OLD = Read-Host "Pfad der aelteren Installationdatei"
        }

        Delete {
            # Abfragen der Inputs
            $Path = Read-Host "Bezeichnung"
            $exe_name = Read-Host "Name der Installationdatei"
        }
    }
    if($Action -eq "Update") {
        return [PSCustomObject]@{
            Path     = $Path;
            Action   = $Action;
            exe_name = $exe_name;
            Path_OLD = $Path_OLD;
        }    
    }
    return [PSCustomObject]@{
        Path     = $Path;
        Action   = $Action;
        exe_name = $exe_name;
    }
}

function updateStructure() {
    param(
        [string] $FolderName,
        [string] $File_path
    )
    [string] $targetDIR = "$install_path\$FolderName"
    [string] $targetFILE = "$targetDIR\" + (Split-Path $File_path -Leaf)


    New-Item -Path $targetDIR -ItemType Directory
    Copy-Item -Path $File_path -Destination $targetFILE
    
}
function updateJSON() {

    # Importieren der aktuellen JSON-Datei
    $json_file = getJSONData
    $inputs = ReadInputs
    # Bau des neuen JSON-Objekts
    if ($inputs.Action -ne "Update") {
        $json_obj = [PSCustomObject]@{
            Path     = $inputs.Path;
            Action   = $inputs.Action;
            EXE_Name = $inputs.exe_name;
        }    
    }
    else {
        $json_obj = [PSCustomObject]@{
            Path     = $inputs.Path;
            Action   = $inputs.Action;
            EXE_Name = $inputs.exe_name;
            Path_OLD = $inputs.Path_OLD;
        }    
    }

    # Hinzufuegen in aktuelle JSON-Datei
    $json_file.Software | Add-Member -Name $inputs.Path -Value $json_obj -MemberType NoteProperty

    # Exportieren in aktuelle JSON-Datei
    ConvertTo-Json -InputObject $json_file | Out-File -FilePath $config_path -Encoding utf8 -Force

    # Anpassen der Ordnerstruktur
    updateStructure -FolderName $inputs.Path -File_path $inputs.exe_name
}

function main() {
    updateJSON
}

main