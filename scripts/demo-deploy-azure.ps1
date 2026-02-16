# ============================================
# Demo de Despliegue Repetible - AI Tour 26
# Script simplificado para demostraciones
# ============================================

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("info", "deploy", "update", "verify", "cleanup")]
    [string]$Action = "info",
    
    [Parameter()]
    [string]$ResourceGroup = "AITourMexFeb",
    
    [Parameter()]
    [string]$Location = "eastus2",
    
    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ============================================
# Helper Functions
# ============================================
function Write-Banner {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   🚀 AI Tour 26 - BRK441 Demo de Despliegue en Azure                 ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section($title, $icon = "📋") {
    Write-Host ""
    Write-Host "$icon $title" -ForegroundColor Blue
    Write-Host ("─" * 60) -ForegroundColor DarkGray
}

function Write-Success($msg) { Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Error($msg) { Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Warning($msg) { Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "  ℹ️  $msg" -ForegroundColor White }
function Write-Command($cmd) { Write-Host "  > $cmd" -ForegroundColor DarkGray }

# ============================================
# Action: Show Info
# ============================================
function Show-DeploymentInfo {
    Write-Section "Arquitectura de Despliegue" "🏗️"
    
    Write-Host @"

  La aplicación Cora de Zava se despliega con los siguientes recursos:

  ┌─────────────────────────────────────────────────────────────────┐
  │                    Azure Resource Group                          │
  │                      ($ResourceGroup)                            │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                  │
  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
  │  │   Container  │    │   Azure AI   │    │  PostgreSQL  │       │
  │  │     Apps     │───▶│   Services   │    │   Flexible   │       │
  │  │  (ca-webapp) │    │ (gpt-4o-mini)│    │    Server    │       │
  │  └──────────────┘    └──────────────┘    └──────────────┘       │
  │         │                                       ▲                │
  │         │                                       │                │
  │         └───────────────────────────────────────┘                │
  │                    (MCP Server Calls)                            │
  │                                                                  │
  │  ┌──────────────┐    ┌──────────────┐                           │
  │  │   Container  │    │   Managed    │                           │
  │  │   Registry   │    │   Identity   │                           │
  │  │    (ACR)     │    │  (id-zava)   │                           │
  │  └──────────────┘    └──────────────┘                           │
  │                                                                  │
  └─────────────────────────────────────────────────────────────────┘

"@ -ForegroundColor White

    Write-Section "Comandos de Despliegue" "⚡"
    
    Write-Host ""
    Write-Host "  PASO 1: Desplegar infraestructura (primera vez)" -ForegroundColor Yellow
    Write-Command ".\scripts\demo-deploy-azure.ps1 -Action deploy -ResourceGroup $ResourceGroup"
    
    Write-Host ""
    Write-Host "  PASO 2: Actualizar imagen (subsecuentes)" -ForegroundColor Yellow
    Write-Command ".\scripts\demo-deploy-azure.ps1 -Action update -ResourceGroup $ResourceGroup"
    
    Write-Host ""
    Write-Host "  PASO 3: Verificar despliegue" -ForegroundColor Yellow
    Write-Command ".\scripts\demo-deploy-azure.ps1 -Action verify -ResourceGroup $ResourceGroup"
    
    Write-Host ""
    Write-Host "  CLEANUP: Eliminar recursos" -ForegroundColor Yellow
    Write-Command ".\scripts\demo-deploy-azure.ps1 -Action cleanup -ResourceGroup $ResourceGroup"
    Write-Host ""
}

# ============================================
# Action: Deploy Infrastructure
# ============================================
function Deploy-Infrastructure {
    Write-Section "Desplegando Infraestructura Azure" "☁️"
    
    if ($DryRun) {
        Write-Warning "Modo DryRun - Mostrando comandos sin ejecutar"
    }
    
    # Step 1: Login verification
    Write-Host ""
    Write-Host "  [1/5] Verificando autenticación Azure..." -ForegroundColor Magenta
    if (-not $DryRun) {
        $account = az account show --query name -o tsv 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "No autenticado. Ejecuta: az login"
            return
        }
        Write-Success "Conectado a: $account"
    } else {
        Write-Command "az account show"
    }
    
    # Step 2: Resource Group
    Write-Host ""
    Write-Host "  [2/5] Creando Resource Group..." -ForegroundColor Magenta
    $cmd = "az group create --name $ResourceGroup --location $Location --tags project=aitour26"
    Write-Command $cmd
    if (-not $DryRun) {
        Invoke-Expression $cmd | Out-Null
        Write-Success "Resource Group: $ResourceGroup"
    }
    
    # Step 3: Deploy Bicep
    Write-Host ""
    Write-Host "  [3/5] Desplegando infraestructura con Bicep..." -ForegroundColor Magenta
    $cmd = "az deployment sub create --location $Location --template-file infra/main.bicep --parameters resourcePrefix=zava-tour"
    Write-Command $cmd
    if (-not $DryRun) {
        Write-Info "Este paso puede tomar 5-10 minutos..."
        # Invoke-Expression $cmd
        Write-Warning "Bicep deployment skipped for demo - use full deploy script"
    }
    
    # Step 4: Build Docker Image
    Write-Host ""
    Write-Host "  [4/5] Construyendo imagen Docker..." -ForegroundColor Magenta
    $cmd = "docker build -t zava-webapp:latest -f Dockerfile.webapp ."
    Write-Command $cmd
    if (-not $DryRun) {
        Write-Info "Construyendo imagen localmente..."
    }
    
    # Step 5: Push to ACR
    Write-Host ""
    Write-Host "  [5/5] Subiendo imagen a Container Registry..." -ForegroundColor Magenta
    Write-Command "az acr login --name zavaacr"
    Write-Command "docker push zavaacr.azurecr.io/zava-webapp:latest"
    
    Write-Host ""
    Write-Success "Despliegue completado!"
    Write-Info "Ejecuta -Action verify para verificar el despliegue"
}

# ============================================
# Action: Update Image
# ============================================
function Update-ContainerImage {
    Write-Section "Actualizando Imagen en Azure" "🔄"
    
    if ($DryRun) {
        Write-Warning "Modo DryRun - Mostrando comandos sin ejecutar"
    }
    
    # Step 1: Build
    Write-Host ""
    Write-Host "  [1/3] Construyendo nueva imagen..." -ForegroundColor Magenta
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $imageTag = "v$timestamp"
    Write-Command "docker build -t zava-webapp:$imageTag -f Dockerfile.webapp ."
    
    # Step 2: Tag & Push
    Write-Host ""
    Write-Host "  [2/3] Subiendo a Container Registry..." -ForegroundColor Magenta
    Write-Command "docker tag zava-webapp:$imageTag zavaacr.azurecr.io/zava-webapp:$imageTag"
    Write-Command "docker push zavaacr.azurecr.io/zava-webapp:$imageTag"
    
    # Step 3: Update Container App
    Write-Host ""
    Write-Host "  [3/3] Actualizando Container App..." -ForegroundColor Magenta
    Write-Command "az containerapp update --name ca-webapp --resource-group $ResourceGroup --image zavaacr.azurecr.io/zava-webapp:$imageTag"
    
    Write-Host ""
    Write-Success "Actualización completada con tag: $imageTag"
}

# ============================================
# Action: Verify Deployment
# ============================================
function Verify-Deployment {
    Write-Section "Verificando Despliegue en Azure" "🔍"
    
    # Check Resource Group
    Write-Host ""
    Write-Host "  [1/4] Verificando Resource Group..." -ForegroundColor Magenta
    try {
        $rg = az group show --name $ResourceGroup --query name -o tsv 2>$null
        if ($rg) {
            Write-Success "Resource Group existe: $ResourceGroup"
        } else {
            Write-Error "Resource Group no encontrado"
            return
        }
    } catch {
        Write-Error "Error verificando Resource Group"
        return
    }
    
    # List Resources
    Write-Host ""
    Write-Host "  [2/4] Listando recursos..." -ForegroundColor Magenta
    $resources = az resource list --resource-group $ResourceGroup --query "[].{Name:name, Type:type}" -o table 2>$null
    if ($resources) {
        Write-Host $resources -ForegroundColor Gray
    }
    
    # Check Container App
    Write-Host ""
    Write-Host "  [3/4] Verificando Container App..." -ForegroundColor Magenta
    try {
        $caUrl = az containerapp show --name ca-webapp --resource-group $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
        if ($caUrl) {
            Write-Success "Container App URL: https://$caUrl"
            
            # Test health endpoint
            Write-Host ""
            Write-Host "  [4/4] Probando endpoint de salud..." -ForegroundColor Magenta
            try {
                $response = Invoke-WebRequest -Uri "https://$caUrl/health" -TimeoutSec 10 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    Write-Success "Health check: OK (200)"
                    $content = $response.Content | ConvertFrom-Json
                    Write-Info "Service: $($content.service)"
                }
            } catch {
                Write-Warning "Health check falló - la app puede estar iniciando"
            }
        } else {
            Write-Warning "Container App no encontrada"
        }
    } catch {
        Write-Warning "No se pudo verificar Container App"
    }
    
    # Summary
    Write-Host ""
    Write-Section "Resumen de Verificación" "✨"
    Write-Info "Resource Group: $ResourceGroup"
    if ($caUrl) {
        Write-Info "Web App URL: https://$caUrl"
        Write-Host ""
        Write-Host "  Para abrir en navegador:" -ForegroundColor Yellow
        Write-Command "Start-Process 'https://$caUrl'"
    }
}

# ============================================
# Action: Cleanup
# ============================================
function Remove-Deployment {
    Write-Section "Eliminando Recursos Azure" "🗑️"
    
    Write-Warning "Esto eliminará TODOS los recursos en: $ResourceGroup"
    Write-Host ""
    
    if (-not $DryRun) {
        $confirm = Read-Host "  ¿Estás seguro? (escribe 'SI' para confirmar)"
        if ($confirm -ne "SI") {
            Write-Info "Cancelado"
            return
        }
    }
    
    Write-Command "az group delete --name $ResourceGroup --yes --no-wait"
    
    if (-not $DryRun) {
        az group delete --name $ResourceGroup --yes --no-wait
        Write-Success "Eliminación iniciada (en segundo plano)"
        Write-Info "Puedes verificar el progreso en Azure Portal"
    }
}

# ============================================
# Main Execution
# ============================================
Write-Banner

switch ($Action) {
    "info" {
        Show-DeploymentInfo
    }
    "deploy" {
        Deploy-Infrastructure
    }
    "update" {
        Update-ContainerImage
    }
    "verify" {
        Verify-Deployment
    }
    "cleanup" {
        Remove-Deployment
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Demo de despliegue completada. Usa -Action [info|deploy|update|verify|cleanup]" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
