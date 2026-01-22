# ============================================
# Azure Container Apps Deployment Script
# Zava AI Agent Workshop
# ============================================

[CmdletBinding()]
param(
    [string]$ResourcePrefix = "zava-agent",
    [string]$Location = "eastus2"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Header { param($msg) Write-Host "`n$msg" -ForegroundColor Blue }
function Write-Step { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "   $msg" -ForegroundColor Gray }
function Write-Warn { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   🚀 Zava AI Agent - Azure Deployment Script (PowerShell)    ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# ============================================
# Configuration Variables
# ============================================
$UniqueSuffix = -join ((65..90) + (97..122) | Get-Random -Count 4 | ForEach-Object {[char]$_})
$UniqueSuffix = $UniqueSuffix.ToLower()

$ResourceGroup = "rg-$ResourcePrefix-$UniqueSuffix"
$AcrName = ($ResourcePrefix -replace '-','') + "acr" + $UniqueSuffix
$CaeName = "cae-$ResourcePrefix-$UniqueSuffix"
$IdentityName = "id-$ResourcePrefix-$UniqueSuffix"
$KeyVaultName = "kv-$ResourcePrefix-$UniqueSuffix"
$PostgresServer = "psql-$ResourcePrefix-$UniqueSuffix"

$CaWebapp = "ca-webapp"
$CaMcp = "ca-mcp-server"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Info "Resource Group: $ResourceGroup"
Write-Info "Location: $Location"
Write-Info "ACR Name: $AcrName"
Write-Info "Container Apps Environment: $CaeName"
Write-Host ""

# ============================================
# Step 1: Create Resource Group
# ============================================
Write-Step "🔧 Step 1: Creating Resource Group..."
az group create `
  --name $ResourceGroup `
  --location $Location `
  --tags "project=zava-agent-workshop" "environment=production" | Out-Null

Write-Info "Resource Group created: $ResourceGroup"

# ============================================
# Step 2: Create User-Assigned Managed Identity
# ============================================
Write-Step "🔐 Step 2: Creating Managed Identity..."
az identity create `
  --name $IdentityName `
  --resource-group $ResourceGroup `
  --location $Location | Out-Null

$IdentityId = az identity show --name $IdentityName --resource-group $ResourceGroup --query id -o tsv
$IdentityPrincipalId = az identity show --name $IdentityName --resource-group $ResourceGroup --query principalId -o tsv
$IdentityClientId = az identity show --name $IdentityName --resource-group $ResourceGroup --query clientId -o tsv

Write-Info "Identity ID: $IdentityId"
Write-Info "Principal ID: $IdentityPrincipalId"

# ============================================
# Step 3: Create Azure Container Registry
# ============================================
Write-Step "📦 Step 3: Creating Azure Container Registry..."
az acr create `
  --name $AcrName `
  --resource-group $ResourceGroup `
  --sku Basic `
  --admin-enabled false | Out-Null

$AcrLoginServer = az acr show --name $AcrName --query loginServer -o tsv
$AcrId = az acr show --name $AcrName --query id -o tsv

Write-Info "ACR Login Server: $AcrLoginServer"

# Assign AcrPull role
Write-Info "Assigning AcrPull role to managed identity..."
az role assignment create `
  --assignee $IdentityPrincipalId `
  --role AcrPull `
  --scope $AcrId | Out-Null

# ============================================
# Step 4: Create Azure Key Vault
# ============================================
Write-Step "🔑 Step 4: Creating Azure Key Vault..."
az keyvault create `
  --name $KeyVaultName `
  --resource-group $ResourceGroup `
  --location $Location `
  --enable-rbac-authorization true | Out-Null

$KeyVaultId = az keyvault show --name $KeyVaultName --query id -o tsv
$KeyVaultUri = az keyvault show --name $KeyVaultName --query properties.vaultUri -o tsv

Write-Info "Key Vault URI: $KeyVaultUri"

# Assign Key Vault roles
Write-Info "Assigning Key Vault Secrets User role..."
az role assignment create `
  --assignee $IdentityPrincipalId `
  --role "Key Vault Secrets User" `
  --scope $KeyVaultId | Out-Null

$CurrentUserId = az ad signed-in-user show --query id -o tsv
az role assignment create `
  --assignee $CurrentUserId `
  --role "Key Vault Secrets Officer" `
  --scope $KeyVaultId | Out-Null

Write-Info "Waiting for role propagation (30s)..."
Start-Sleep -Seconds 30

# ============================================
# Step 5: Create Azure Database for PostgreSQL
# ============================================
Write-Step "🗄️  Step 5: Creating Azure Database for PostgreSQL..."

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
  --yes | Out-Null

Write-Info "PostgreSQL server created: $PostgresServer"

# Store password in Key Vault
az keyvault secret set `
  --vault-name $KeyVaultName `
  --name "PostgresPassword" `
  --value $PostgresPassword | Out-Null

# Create database
az postgres flexible-server db create `
  --resource-group $ResourceGroup `
  --server-name $PostgresServer `
  --database-name zava | Out-Null

# Enable pgvector extension
az postgres flexible-server parameter set `
  --resource-group $ResourceGroup `
  --server-name $PostgresServer `
  --name azure.extensions `
  --value vector | Out-Null

# Allow Azure services
az postgres flexible-server firewall-rule create `
  --resource-group $ResourceGroup `
  --name $PostgresServer `
  --rule-name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0 | Out-Null

$PostgresFqdn = az postgres flexible-server show --name $PostgresServer --resource-group $ResourceGroup --query fullyQualifiedDomainName -o tsv

# Store connection string in Key Vault
$PostgresConnString = "postgresql://pgadmin:${PostgresPassword}@${PostgresFqdn}:5432/zava?sslmode=require"
az keyvault secret set `
  --vault-name $KeyVaultName `
  --name "PostgresConnectionString" `
  --value $PostgresConnString | Out-Null

Write-Info "PostgreSQL FQDN: $PostgresFqdn"

# ============================================
# Step 6: Build and Push Container Images
# ============================================
Write-Step "🐳 Step 6: Building and pushing container images..."

Write-Info "Building webapp image..."
az acr build `
  --registry $AcrName `
  --image zava-webapp:v1 `
  --file Dockerfile.webapp `
  . | Out-Null

Write-Info "Building MCP server image..."
az acr build `
  --registry $AcrName `
  --image zava-mcp:v1 `
  --file Dockerfile.mcp `
  . | Out-Null

Write-Info "Images built and pushed successfully"

# ============================================
# Step 7: Create Container Apps Environment
# ============================================
Write-Step "🌐 Step 7: Creating Container Apps Environment..."
az containerapp env create `
  --name $CaeName `
  --resource-group $ResourceGroup `
  --location $Location | Out-Null

Write-Info "Container Apps Environment created: $CaeName"

# ============================================
# Step 8: Deploy Web Application
# ============================================
Write-Step "🚀 Step 8: Deploying Web Application..."

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
  --env-vars "ENVIRONMENT=production" "MODEL_DEPLOYMENT_NAME=gpt-4.1-mini" | Out-Null

$WebappFqdn = az containerapp show --name $CaWebapp --resource-group $ResourceGroup --query properties.configuration.ingress.fqdn -o tsv

# ============================================
# Output Deployment Information
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║   ✅ Deployment Completed Successfully!                      ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

Write-Host "📋 Deployment Summary:" -ForegroundColor Green
Write-Info "Resource Group:     $ResourceGroup"
Write-Info "Location:           $Location"
Write-Host ""

Write-Host "🔗 Access URLs:" -ForegroundColor Green
Write-Info "Web Application:    https://$WebappFqdn"
Write-Host ""

Write-Host "🔐 Security Resources:" -ForegroundColor Green
Write-Info "Key Vault:          $KeyVaultName"
Write-Info "Managed Identity:   $IdentityName"
Write-Info "ACR:                $AcrLoginServer"
Write-Host ""

Write-Host "🗄️  Database:" -ForegroundColor Green
Write-Info "PostgreSQL Server:  $PostgresFqdn"
Write-Info "Database:           zava"
Write-Host ""

Write-Warn "Next Steps:"
Write-Host "   1. Configure AZURE_AI_FOUNDRY_ENDPOINT in Container App settings" -ForegroundColor Yellow
Write-Host "   2. Restore database backup to Azure PostgreSQL" -ForegroundColor Yellow
Write-Host "   3. Test the application at https://$WebappFqdn" -ForegroundColor Yellow
Write-Host ""

# Save deployment info to file
$DeploymentInfo = @{
    resourceGroup = $ResourceGroup
    location = $Location
    webapp = @{
        name = $CaWebapp
        url = "https://$WebappFqdn"
    }
    database = @{
        server = $PostgresFqdn
        database = "zava"
    }
    security = @{
        keyVault = $KeyVaultName
        managedIdentity = $IdentityName
        acr = $AcrLoginServer
    }
}

$DeploymentInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath "deployment-info.json" -Encoding utf8

Write-Host "📄 Deployment info saved to: deployment-info.json" -ForegroundColor Green
