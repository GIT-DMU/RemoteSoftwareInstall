# Importieren der Module
Import-Module -Name .\Module\BoreasInstall.psd1

# Hauptfunktion

function main() {
    # Check ob Client-Config und Remote-Config aktuell, falls nein ersetzen der Lokalen durch Remote
    CheckConfigs

    # Call
    SoftwareHandler
    
    # Entfernen der temporären Dateien
    Clear-InstallFolder
}

# aufrufen Hauptfunktion
main

