$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

$pythonCandidates = @(
    "$PSScriptRoot\venv\Scripts\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "python"
)

$pythonExe = $pythonCandidates | Where-Object { Test-Path $_ -or $_ -eq "python" } | Select-Object -First 1

if (-not (Test-Path "venv\Scripts\python.exe")) {
    Write-Host "Creando entorno virtual..."
    & $pythonExe -m venv venv
}

Write-Host "Instalando dependencias..."
& ".\venv\Scripts\python.exe" -m pip install -r requirements.txt -q

if (-not (Test-Path "uploads")) {
    New-Item -ItemType Directory -Path "uploads" | Out-Null
}

Write-Host "Iniciando API en http://0.0.0.0:8003"
& ".\venv\Scripts\uvicorn.exe" app.main:app --reload --host 0.0.0.0 --port 8003
