# ============================================
# Script de Demo: Integración Frontend + Agente
# AI Tour 26 BRK441 - Mexico
# ============================================

[CmdletBinding()]
param(
    [switch]$SkipDatabase,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# Colors and formatting
function Write-Header { param($msg) Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Blue; Write-Host "  $msg" -ForegroundColor Blue; Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue }
function Write-Step { param($step, $msg) Write-Host "`n▶ [Paso $step] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  ℹ️  $msg" -ForegroundColor Gray }
function Write-Warn { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }

# Banner
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║       🚀 AI Tour 26 BRK441 - Demo de Integración            ║" -ForegroundColor Magenta
Write-Host "║       Frontend + Agente Cora + MCP + PostgreSQL             ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Info "Directorio del proyecto: $ProjectRoot"

# ============================================
# Step 0: Clean previous processes (optional)
# ============================================
if ($Clean) {
    Write-Step "0" "Limpiando procesos anteriores..."
    
    # Stop Python processes using port 8000
    $processes = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        Stop-Process -Id $proc.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    
    Write-Success "Procesos limpiados"
}

# ============================================
# Step 1: Verify Environment
# ============================================
Write-Header "VERIFICACIÓN DEL ENTORNO"

Write-Step "1" "Verificando requisitos..."

# Check Python
try {
    $pythonVersion = & python --version 2>&1
    Write-Success "Python instalado: $pythonVersion"
} catch {
    Write-Fail "Python no encontrado. Instalar Python 3.11+"
    exit 1
}

# Check Docker
try {
    $dockerVersion = & docker --version 2>&1
    Write-Success "Docker instalado: $dockerVersion"
} catch {
    Write-Fail "Docker no encontrado. Instalar Docker Desktop"
    exit 1
}

# Check .env file
$envFile = Join-Path $ProjectRoot ".env"
if (Test-Path $envFile) {
    Write-Success "Archivo .env encontrado"
} else {
    Write-Warn "Archivo .env no encontrado - creando uno de ejemplo..."
    @"
# Azure AI Foundry Configuration
AZURE_AI_FOUNDRY_ENDPOINT=https://your-foundry-endpoint.services.ai.azure.com/
MODEL_DEPLOYMENT_NAME=gpt-4.1-mini

# PostgreSQL Configuration (Docker)
POSTGRES_URL=postgresql://store_manager:StoreManager123!@localhost:15432/zava

# Row Level Security User ID
RLS_USER_ID=00000000-0000-0000-0000-000000000000
"@ | Out-File -FilePath $envFile -Encoding utf8
    Write-Warn "Edita el archivo .env con tu configuración de Azure AI Foundry"
}

# ============================================
# Step 2: Start Database
# ============================================
Write-Header "BASE DE DATOS"

if (-not $SkipDatabase) {
    Write-Step "2" "Iniciando PostgreSQL con Docker..."
    
    Set-Location $ProjectRoot
    
    # Check if container is already running
    $dbContainer = docker ps --filter "name=ai-tour-26-BRK441" --format "{{.Names}}" 2>$null
    
    if ($dbContainer) {
        Write-Success "Contenedor de BD ya está corriendo: $dbContainer"
    } else {
        Write-Info "Iniciando docker-compose..."
        docker-compose up -d 2>$null
        
        Write-Info "Esperando a que PostgreSQL esté listo (esto puede tomar 30-60 segundos)..."
        $maxAttempts = 30
        $attempt = 0
        
        do {
            Start-Sleep -Seconds 2
            $attempt++
            $healthCheck = docker-compose exec -T db pg_isready -U postgres 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "PostgreSQL está listo"
                break
            }
            Write-Host "." -NoNewline
        } while ($attempt -lt $maxAttempts)
        
        if ($attempt -ge $maxAttempts) {
            Write-Warn "PostgreSQL puede no estar listo. Continuando..."
        }
    }
} else {
    Write-Info "Saltando inicio de base de datos (-SkipDatabase)"
}

# ============================================
# Step 3: Test Database Connectivity
# ============================================
Write-Header "PRUEBA DE CONECTIVIDAD"

Write-Step "3" "Probando conexión a la base de datos..."

Set-Location "$ProjectRoot\src\python\tests"

try {
    $output = & python demo_database_connectivity.py 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Conectividad a PostgreSQL verificada"
        # Show summary
        $output | Select-String -Pattern "productos|customers|orders|Total" | ForEach-Object { Write-Info $_.Line }
    } else {
        Write-Warn "Prueba de conectividad con advertencias"
        Write-Info $output
    }
} catch {
    Write-Warn "No se pudo ejecutar la prueba de conectividad: $_"
}

# ============================================
# Step 4: Architecture Visualization
# ============================================
Write-Header "ARQUITECTURA DE INTEGRACIÓN"

Write-Host @"

  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║                        ARQUITECTURA DE LA DEMO                             ║
  ╟───────────────────────────────────────────────────────────────────────────╢
  ║                                                                            ║
  ║   ┌─────────────┐    WebSocket    ┌─────────────────┐                     ║
  ║   │   Browser   │ ◀──────────────▶│    FastAPI      │                     ║
  ║   │  (index.html│                 │   (web_app.py)  │                     ║
  ║   │   :8000)    │                 │                │                      ║
  ║   └─────────────┘                 └────────┬───────┘                      ║
  ║                                            │                               ║
  ║                                            │ Agent Framework               ║
  ║                                            ▼                               ║
  ║                                   ┌─────────────────┐                     ║
  ║                                   │   Cora Agent    │                     ║
  ║                                   │ (ChatAgent MAF) │                     ║
  ║                                   │                │                       ║
  ║                                   └────────┬───────┘                      ║
  ║                                            │                               ║
  ║                                            │ MCP Tools (stdio)             ║
  ║                                            ▼                               ║
  ║                                   ┌─────────────────┐                     ║
  ║                                   │   MCP Server    │                     ║
  ║                                   │ (customer_sales)│                     ║
  ║                                   │                │                       ║
  ║                                   └────────┬───────┘                      ║
  ║                                            │                               ║
  ║                                            │ asyncpg                       ║
  ║                                            ▼                               ║
  ║   ┌─────────────────────────────────────────────────────────────────┐    ║
  ║   │                    PostgreSQL + pgvector                         │    ║
  ║   │   ┌────────┐  ┌──────────┐  ┌────────┐  ┌──────────────────┐   │    ║
  ║   │   │products│  │customers │  │ orders │  │order_items, etc. │   │    ║
  ║   │   └────────┘  └──────────┘  └────────┘  └──────────────────┘   │    ║
  ║   └─────────────────────────────────────────────────────────────────┘    ║
  ║                                                                            ║
  ╚═══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ============================================
# Step 5: Start Web Application
# ============================================
Write-Header "INICIAR APLICACIÓN WEB"

Write-Step "5" "Iniciando Web Application con Agente Cora..."

Set-Location "$ProjectRoot\src\python\web_app"

# Check if port 8000 is already in use
$portInUse = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Warn "Puerto 8000 ya está en uso"
    Write-Info "¿Deseas terminar el proceso existente? (S/N)"
    $response = Read-Host
    if ($response -eq "S" -or $response -eq "s") {
        Stop-Process -Id $portInUse[0].OwningProcess -Force
        Start-Sleep -Seconds 2
    }
}

Write-Info "Iniciando servidor FastAPI + Agente..."
Write-Info ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  🌐 Abre en tu navegador: " -NoNewline -ForegroundColor Green
Write-Host "http://localhost:8000" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Info "Presiona Ctrl+C para detener el servidor"
Write-Host ""

# Run the web app
& python web_app.py
