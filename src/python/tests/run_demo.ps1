# Demo de Integración - AI Tour 26 BRK441
# Script PowerShell para ejecutar demostraciones

param(
    [Parameter()]
    [ValidateSet("full", "db", "quick", "all")]
    [string]$Mode = "quick",
    
    [Parameter()]
    [switch]$StartDocker,
    
    [Parameter()]
    [switch]$StartWebApp
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$PythonTestsDir = Join-Path $ProjectRoot "src\python\tests"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  AI Tour 26 - BRK441 Demo de Integración                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Function to start Docker services
function Start-DockerServices {
    Write-Host "[Docker] Iniciando servicios..." -ForegroundColor Yellow
    
    $dockerCompose = Join-Path $ProjectRoot "docker-compose.yml"
    
    try {
        docker-compose -f $dockerCompose up -d
        Write-Host "✅ Servicios Docker iniciados" -ForegroundColor Green
        Write-Host "   Esperando a que PostgreSQL esté listo..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
    }
    catch {
        Write-Host "❌ Error iniciando Docker: $_" -ForegroundColor Red
        Write-Host "   Asegúrate de que Docker Desktop esté corriendo" -ForegroundColor Yellow
    }
}

# Function to start Web App
function Start-WebAppService {
    Write-Host "[Web App] Iniciando servicio en segundo plano..." -ForegroundColor Yellow
    
    $webAppPath = Join-Path $ProjectRoot "src\python\web_app\web_app.py"
    
    Start-Process -FilePath "python" -ArgumentList $webAppPath -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    Write-Host "✅ Web App iniciada en http://localhost:8000" -ForegroundColor Green
}

# Function to run quick demo
function Run-QuickDemo {
    Write-Host "`n[Demo] Ejecutando demo rápida..." -ForegroundColor Magenta
    
    Push-Location $PythonTestsDir
    try {
        python demo_integration_quick.py
    }
    finally {
        Pop-Location
    }
}

# Function to run database connectivity demo
function Run-DatabaseDemo {
    Write-Host "`n[Demo] Ejecutando demo de conectividad a BD..." -ForegroundColor Magenta
    
    Push-Location $PythonTestsDir
    try {
        python demo_database_connectivity.py
    }
    finally {
        Pop-Location
    }
}

# Function to run full integration tests
function Run-FullTests {
    Write-Host "`n[Tests] Ejecutando pruebas de integración completas..." -ForegroundColor Magenta
    
    Push-Location $PythonTestsDir
    try {
        python test_integration.py
    }
    finally {
        Pop-Location
    }
}

# Main execution
if ($StartDocker) {
    Start-DockerServices
}

if ($StartWebApp) {
    Start-WebAppService
}

switch ($Mode) {
    "quick" {
        Run-QuickDemo
    }
    "db" {
        Run-DatabaseDemo
    }
    "full" {
        Run-FullTests
    }
    "all" {
        Run-QuickDemo
        Write-Host "`n" -NoNewline
        Run-DatabaseDemo
        Write-Host "`n" -NoNewline
        Run-FullTests
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Demo completada. Para más información:" -ForegroundColor White
Write-Host "  - Documentación: session-delivery-resources/demos-instructions/07-integration-demo.md" -ForegroundColor Gray
Write-Host "  - Web App: http://localhost:8000" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
