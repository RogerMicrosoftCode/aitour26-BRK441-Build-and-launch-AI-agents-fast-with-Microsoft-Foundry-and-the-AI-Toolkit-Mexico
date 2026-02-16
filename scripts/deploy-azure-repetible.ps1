# ============================================
# Script de Despliegue Repetible - Azure
# AI Tour 26 BRK441 - Mexico
# ============================================
# 
# Este script despliega toda la infraestructura de manera
# idempotente y repetible usando Azure Container Apps.
#
# USO:
#   .\deploy-azure-repetible.ps1 -ResourcePrefix "zava" -Location "eastus2"
#   .\deploy-azure-repetible.ps1 -Destroy  # Para eliminar recursos
#
# ============================================

[CmdletBinding()]
param(
    [string]$ResourcePrefix = "zava-agent",
    [string]$Location = "eastus2",
    [string]$FoundryEndpoint = "",
    [string]$ModelDeploymentName = "gpt-4.1-mini",
    [switch]$Destroy,
    [switch]$SkipInfra,
    [switch]$BuildOnly
)

$ErrorActionPreference = "Stop"

# Formatting functions
function Write-Header { param($msg) Write-Host "`n$("═" * 60)" -ForegroundColor Blue; Write-Host "  $msg" -ForegroundColor Blue; Write-Host "$("═" * 60)" -ForegroundColor Blue }
function Write-Step { param($step, $msg) Write-Host "`n[Paso $step] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "     $msg" -ForegroundColor Gray }
function Write-Warn { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }

# Banner
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   🚀 Despliegue Repetible - Azure Container Apps             ║" -ForegroundColor Blue
Write-Host "║   AI Tour 26 BRK441 - Zava Agent Workshop                    ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# ============================================
# Generate unique suffix based on subscription
# ============================================
$SubscriptionId = az account show --query id -o tsv 2>$null
if (-not $SubscriptionId) {
    Write-Fail "No hay sesión de Azure activa. Ejecuta: az login"
    exit 1
}

# Use consistent suffix based on subscription for repeatability
$UniqueSuffix = $SubscriptionId.Substring(0, 4).ToLower()
Write-Info "Usando sufijo único: $UniqueSuffix (basado en suscripción)"

# Resource names (deterministic for repeatability)
$ResourceGroup = "rg-$ResourcePrefix-$UniqueSuffix"
$AcrName = ($ResourcePrefix -replace '-','') + "acr" + $UniqueSuffix
$CaeName = "cae-$ResourcePrefix-$UniqueSuffix"
$IdentityName = "id-$ResourcePrefix-$UniqueSuffix"
$KeyVaultName = "kv-$ResourcePrefix-$UniqueSuffix"
$PostgresServer = "psql-$ResourcePrefix-$UniqueSuffix"
$CaWebapp = "ca-webapp"
$CaMcpServer = "ca-mcp-server"

# Deployment info file path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$DeploymentInfoFile = Join-Path $ProjectRoot "deployment-info.json"

Write-Host "📋 Configuración del Despliegue:" -ForegroundColor Yellow
Write-Info "Resource Group:     $ResourceGroup"
Write-Info "Location:           $Location"
Write-Info "ACR:                $AcrName"
Write-Info "Container Env:      $CaeName"
Write-Info "PostgreSQL:         $PostgresServer"
Write-Host ""

# ============================================
# Destroy mode
# ============================================
if ($Destroy) {
    Write-Header "ELIMINANDO RECURSOS"
    
    Write-Step "1" "Eliminando Resource Group: $ResourceGroup"
    
    $confirmation = Read-Host "¿Estás seguro de eliminar todos los recursos? (escribe 'SI' para confirmar)"
    if ($confirmation -ne "SI") {
        Write-Warn "Operación cancelada"
        exit 0
    }
    
    az group delete --name $ResourceGroup --yes --no-wait
    Write-Success "Eliminación iniciada (proceso asíncrono)"
    
    # Remove deployment info file
    if (Test-Path $DeploymentInfoFile) {
        Remove-Item $DeploymentInfoFile -Force
        Write-Info "Archivo deployment-info.json eliminado"
    }
    
    Write-Host "`n✅ Limpieza completada" -ForegroundColor Green
    exit 0
}

# ============================================
# Check for existing deployment
# ============================================
$existingRg = az group exists --name $ResourceGroup 2>$null
if ($existingRg -eq "true") {
    Write-Warn "El Resource Group '$ResourceGroup' ya existe"
    Write-Info "El script actualizará los recursos existentes (idempotente)"
    Start-Sleep -Seconds 2
}

# ============================================
# INFRASTRUCTURE DEPLOYMENT
# ============================================
if (-not $SkipInfra) {
    Write-Header "DESPLEGANDO INFRAESTRUCTURA"
    
    # Step 1: Resource Group
    Write-Step "1" "Creando Resource Group..."
    az group create `
        --name $ResourceGroup `
        --location $Location `
        --tags "project=zava-agent-workshop" "environment=production" "owner=ai-tour-26" `
        --output none
    Write-Success "Resource Group: $ResourceGroup"
    
    # Step 2: Managed Identity
    Write-Step "2" "Configurando Managed Identity..."
    $existingIdentity = az identity show --name $IdentityName --resource-group $ResourceGroup 2>$null
    if (-not $existingIdentity) {
        az identity create `
            --name $IdentityName `
            --resource-group $ResourceGroup `
            --location $Location `
            --output none
    }
    
    $IdentityId = az identity show --name $IdentityName --resource-group $ResourceGroup --query id -o tsv
    $IdentityPrincipalId = az identity show --name $IdentityName --resource-group $ResourceGroup --query principalId -o tsv
    $IdentityClientId = az identity show --name $IdentityName --resource-group $ResourceGroup --query clientId -o tsv
    Write-Success "Managed Identity configurada"
    
    # Step 3: Azure Container Registry
    Write-Step "3" "Configurando Azure Container Registry..."
    $existingAcr = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
    if (-not $existingAcr) {
        az acr create `
            --name $AcrName `
            --resource-group $ResourceGroup `
            --sku Basic `
            --admin-enabled false `
            --output none
    }
    
    $AcrLoginServer = az acr show --name $AcrName --query loginServer -o tsv
    $AcrId = az acr show --name $AcrName --query id -o tsv
    
    # Assign AcrPull role (idempotent)
    az role assignment create `
        --assignee $IdentityPrincipalId `
        --role AcrPull `
        --scope $AcrId `
        --output none 2>$null
    Write-Success "ACR: $AcrLoginServer"
    
    # Step 4: Key Vault
    Write-Step "4" "Configurando Azure Key Vault..."
    $existingKv = az keyvault show --name $KeyVaultName --resource-group $ResourceGroup 2>$null
    if (-not $existingKv) {
        az keyvault create `
            --name $KeyVaultName `
            --resource-group $ResourceGroup `
            --location $Location `
            --enable-rbac-authorization true `
            --output none
    }
    
    $KeyVaultId = az keyvault show --name $KeyVaultName --query id -o tsv
    $KeyVaultUri = az keyvault show --name $KeyVaultName --query properties.vaultUri -o tsv
    
    # Assign Key Vault roles (idempotent)
    az role assignment create `
        --assignee $IdentityPrincipalId `
        --role "Key Vault Secrets User" `
        --scope $KeyVaultId `
        --output none 2>$null
    
    $CurrentUserId = az ad signed-in-user show --query id -o tsv
    az role assignment create `
        --assignee $CurrentUserId `
        --role "Key Vault Secrets Officer" `
        --scope $KeyVaultId `
        --output none 2>$null
    Write-Success "Key Vault: $KeyVaultName"
    
    # Step 5: PostgreSQL Flexible Server
    Write-Step "5" "Configurando Azure PostgreSQL..."
    $existingPg = az postgres flexible-server show --name $PostgresServer --resource-group $ResourceGroup 2>$null
    
    if (-not $existingPg) {
        # Generate secure password
        $PostgresPassword = -join ((65..90) + (97..122) + (48..57) + (33,35,36,37,38,64) | Get-Random -Count 24 | ForEach-Object {[char]$_})
        
        az postgres flexible-server create `
            --name $PostgresServer `
            --resource-group $ResourceGroup `
            --location $Location `
            --admin-user pgadmin `
            --admin-password $PostgresPassword `
            --sku-name Standard_B1ms `
            --storage-size 32 `
            --version 16 `
            --yes `
            --output none
        
        # Store password in Key Vault
        az keyvault secret set `
            --vault-name $KeyVaultName `
            --name "PostgresPassword" `
            --value $PostgresPassword `
            --output none
        
        # Create database
        az postgres flexible-server db create `
            --resource-group $ResourceGroup `
            --server-name $PostgresServer `
            --database-name zava `
            --output none
        
        # Enable pgvector
        az postgres flexible-server parameter set `
            --resource-group $ResourceGroup `
            --server-name $PostgresServer `
            --name azure.extensions `
            --value vector `
            --output none
        
        # Allow Azure services
        az postgres flexible-server firewall-rule create `
            --resource-group $ResourceGroup `
            --name $PostgresServer `
            --rule-name AllowAzureServices `
            --start-ip-address 0.0.0.0 `
            --end-ip-address 0.0.0.0 `
            --output none
    } else {
        Write-Info "PostgreSQL ya existe, reutilizando..."
        $PostgresPassword = az keyvault secret show --vault-name $KeyVaultName --name "PostgresPassword" --query value -o tsv 2>$null
    }
    
    $PostgresFqdn = az postgres flexible-server show --name $PostgresServer --resource-group $ResourceGroup --query fullyQualifiedDomainName -o tsv
    Write-Success "PostgreSQL: $PostgresFqdn"
    
    # Store connection string in Key Vault
    $PostgresConnString = "postgresql://pgadmin:${PostgresPassword}@${PostgresFqdn}:5432/zava?sslmode=require"
    az keyvault secret set `
        --vault-name $KeyVaultName `
        --name "PostgresConnectionString" `
        --value $PostgresConnString `
        --output none 2>$null
    
    # Step 6: Container Apps Environment
    Write-Step "6" "Configurando Container Apps Environment..."
    $existingCae = az containerapp env show --name $CaeName --resource-group $ResourceGroup 2>$null
    if (-not $existingCae) {
        az containerapp env create `
            --name $CaeName `
            --resource-group $ResourceGroup `
            --location $Location `
            --output none
    }
    Write-Success "Container Apps Environment: $CaeName"
}

# ============================================
# BUILD AND PUSH IMAGES
# ============================================
Write-Header "CONSTRUYENDO IMÁGENES"

Write-Step "7" "Construyendo imagen de Web App..."
Set-Location $ProjectRoot

az acr build `
    --registry $AcrName `
    --image zava-webapp:v1 `
    --image zava-webapp:latest `
    --file Dockerfile.webapp `
    . `
    --output none

Write-Success "Imagen webapp construida: $AcrLoginServer/zava-webapp:v1"

Write-Step "8" "Construyendo imagen de MCP Server..."
az acr build `
    --registry $AcrName `
    --image zava-mcp:v1 `
    --image zava-mcp:latest `
    --file Dockerfile.mcp `
    . `
    --output none

Write-Success "Imagen MCP construida: $AcrLoginServer/zava-mcp:v1"

if ($BuildOnly) {
    Write-Host "`n✅ Build completado (modo -BuildOnly)" -ForegroundColor Green
    exit 0
}

# ============================================
# DEPLOY CONTAINER APPS
# ============================================
Write-Header "DESPLEGANDO APLICACIONES"

# Get Foundry endpoint if not provided
if (-not $FoundryEndpoint) {
    Write-Warn "AZURE_AI_FOUNDRY_ENDPOINT no proporcionado"
    $FoundryEndpoint = Read-Host "Ingresa el endpoint de Azure AI Foundry (o presiona Enter para omitir)"
}

Write-Step "9" "Desplegando Web Application..."

# Check if webapp exists
$existingWebapp = az containerapp show --name $CaWebapp --resource-group $ResourceGroup 2>$null

if ($existingWebapp) {
    # Update existing app
    az containerapp update `
        --name $CaWebapp `
        --resource-group $ResourceGroup `
        --image "${AcrLoginServer}/zava-webapp:v1" `
        --output none
} else {
    # Create new app
    az containerapp create `
        --name $CaWebapp `
        --resource-group $ResourceGroup `
        --environment $CaeName `
        --image "${AcrLoginServer}/zava-webapp:v1" `
        --target-port 8000 `
        --ingress external `
        --min-replicas 1 `
        --max-replicas 10 `
        --cpu 0.5 `
        --memory 1.0Gi `
        --user-assigned $IdentityId `
        --registry-server $AcrLoginServer `
        --registry-identity $IdentityId `
        --env-vars "ENVIRONMENT=production" "MODEL_DEPLOYMENT_NAME=$ModelDeploymentName" "AZURE_CLIENT_ID=$IdentityClientId" `
        --output none
}

$WebappFqdn = az containerapp show --name $CaWebapp --resource-group $ResourceGroup --query properties.configuration.ingress.fqdn -o tsv
Write-Success "Web App desplegada: https://$WebappFqdn"

# Configure secrets and environment variables
Write-Step "10" "Configurando secretos y variables de entorno..."

if ($FoundryEndpoint) {
    az containerapp secret set `
        --name $CaWebapp `
        --resource-group $ResourceGroup `
        --secrets "foundry-endpoint=$FoundryEndpoint" `
        --output none 2>$null
    
    az containerapp update `
        --name $CaWebapp `
        --resource-group $ResourceGroup `
        --set-env-vars "AZURE_AI_FOUNDRY_ENDPOINT=secretref:foundry-endpoint" `
        --output none 2>$null
}

Write-Success "Configuración completada"

# ============================================
# DEPLOYMENT SUMMARY
# ============================================
Write-Header "DESPLIEGUE COMPLETADO"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         ✅ DESPLIEGUE EXITOSO - INFORMACIÓN                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "🔗 URLs de Acceso:" -ForegroundColor Cyan
Write-Host "   Web Application:  " -NoNewline; Write-Host "https://$WebappFqdn" -ForegroundColor Yellow
Write-Host ""

Write-Host "📦 Recursos Azure:" -ForegroundColor Cyan
Write-Host "   Resource Group:   $ResourceGroup"
Write-Host "   Location:         $Location"
Write-Host "   ACR:              $AcrLoginServer"
Write-Host "   Key Vault:        $KeyVaultName"
Write-Host "   PostgreSQL:       $PostgresFqdn"
Write-Host "   Managed Identity: $IdentityName"
Write-Host ""

Write-Host "🔄 Próximos Pasos:" -ForegroundColor Yellow
Write-Host "   1. Configurar AZURE_AI_FOUNDRY_ENDPOINT si no se proporcionó"
Write-Host "   2. Restaurar backup de base de datos en PostgreSQL"
Write-Host "   3. Asignar rol 'Cognitive Services User' a la identidad"
Write-Host "   4. Probar la aplicación en https://$WebappFqdn"
Write-Host ""

# Save deployment info
$DeploymentInfo = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    resourceGroup = $ResourceGroup
    location = $Location
    webapp = @{
        name = $CaWebapp
        url = "https://$WebappFqdn"
        image = "$AcrLoginServer/zava-webapp:v1"
    }
    database = @{
        server = $PostgresFqdn
        database = "zava"
        username = "pgadmin"
    }
    security = @{
        keyVault = $KeyVaultName
        keyVaultUri = $KeyVaultUri
        managedIdentity = $IdentityName
        managedIdentityClientId = $IdentityClientId
        acr = $AcrLoginServer
    }
    containerApps = @{
        environment = $CaeName
        webapp = $CaWebapp
    }
}

$DeploymentInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath $DeploymentInfoFile -Encoding utf8

Write-Host "📄 Información guardada en: " -NoNewline
Write-Host "deployment-info.json" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔁 Para re-desplegar, ejecuta el mismo comando." -ForegroundColor Gray
Write-Host "🗑️  Para eliminar, usa: .\deploy-azure-repetible.ps1 -Destroy" -ForegroundColor Gray
Write-Host ""
