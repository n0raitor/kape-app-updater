# ============================================
# KAPE Tool Copy Script
# ============================================

# Globale Variablen
$DFIR_Dir = "C:\DFIR\"
$KAPE_Location = "C:\DFIR\KAPE\KAPE"
$ConfigFile = "Kape-App.conf"
$MissingAppsFile = "Missing-apps.txt"

# Array für fehlende Tools
$Missing = @()

# Disclaimer anzeigen
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "Wurde DFIR-installer ausgeführt, um die aktuellsten Tools zu haben?" -ForegroundColor Cyan
Write-Host "Drücke ENTER um fortzufahren..." -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Read-Host

# Prüfen ob Hauptverzeichnisse existieren
if (-not (Test-Path $DFIR_Dir)) {
    Write-Host "FEHLER: DFIR-Verzeichnis existiert nicht: $DFIR_Dir" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $KAPE_Location)) {
    Write-Host "FEHLER: KAPE-Location existiert nicht: $KAPE_Location" -ForegroundColor Red
    exit 1
}

# Prüfen ob Config-Datei existiert
if (-not (Test-Path $ConfigFile)) {
    Write-Host "FEHLER: Config-Datei existiert nicht: $ConfigFile" -ForegroundColor Red
    exit 1
}

# Config-Datei einlesen und verarbeiten
$ConfigLines = Get-Content $ConfigFile | Where-Object { $_.Trim() -ne "" }

foreach ($Line in $ConfigLines) {
    # Zeile parsen (Format: NAME;DFIR-PATH;KAPE-Tool-location)
    $Parts = $Line -split ";"
    
    if ($Parts.Count -ge 3) {
        $ToolName = $Parts[0].Trim()
        $DFIR_Path = $Parts[1].Trim()
        $KAPE_ToolLocation = $Parts[2].Trim()
        
        # Pfade zusammenbauen
        $DFIR_Dir_Tool = Join-Path $DFIR_Dir $DFIR_Path
        $KAPE_Location_Tool = Join-Path $KAPE_Location $KAPE_ToolLocation
        
        Write-Host "`n$ToolName copy started" -ForegroundColor Cyan
        
        # Prüfen ob Quelle existiert (Datei oder Ordner)
        if (-not (Test-Path $DFIR_Dir_Tool)) {
            # Tool zur Missing-Liste hinzufügen
            $Missing += "$ToolName - $DFIR_Dir_Tool"
            Write-Host "  FEHLT: $DFIR_Dir_Tool" -ForegroundColor Red
            continue
        }
        
        # Zielverzeichnis erstellen falls nicht vorhanden
        $DestinationParent = Split-Path $KAPE_Location_Tool -Parent
        if (-not (Test-Path $DestinationParent)) {
            New-Item -ItemType Directory -Path $DestinationParent -Force | Out-Null
        }
        
        try {
            # Kopieren (Datei oder Ordner)
            if (Test-Path $DFIR_Dir_Tool -PathType Leaf) {
                # Es ist eine Datei
                Copy-Item -Path $DFIR_Dir_Tool -Destination $KAPE_Location_Tool -Force
                $TestDestination = Join-Path $KAPE_Location_Tool (Split-Path $DFIR_Dir_Tool -Leaf)
            }
            else {
                # Es ist ein Ordner
                # Zielordner erstellen falls nicht vorhanden
                if (-not (Test-Path $KAPE_Location_Tool)) {
                    New-Item -ItemType Directory -Path $KAPE_Location_Tool -Force | Out-Null
                }
                Copy-Item -Path "$DFIR_Dir_Tool\*" -Destination $KAPE_Location_Tool -Recurse -Force
                $TestDestination = $KAPE_Location_Tool
            }
            
            # Prüfen ob Kopieren erfolgreich war
            if (Test-Path $TestDestination) {
                Write-Host "  Successful: Kopiert nach $TestDestination" -ForegroundColor Green
            }
            else {
                Write-Host "  FEHLER: Kopieren fehlgeschlagen" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  FEHLER beim Kopieren: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Fehlende Tools ausgeben
if ($Missing.Count -gt 0) {
    Write-Host "`n============================================" -ForegroundColor Yellow
    Write-Host "Fehlende Tools:" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Yellow
    
    foreach ($Item in $Missing) {
        Write-Host "• $Item" -ForegroundColor Red
    }
    
    # In Datei schreiben
    $Missing | Out-File -FilePath $MissingAppsFile -Encoding UTF8
    Write-Host "`nMissing Tools wurden in '$MissingAppsFile' gespeichert." -ForegroundColor Yellow
}
else {
    Write-Host "`nAlle Tools wurden erfolgreich kopiert!" -ForegroundColor Green
}

Write-Host "`nFertig." -ForegroundColor Cyan