#!/bin/bash
# ============================================
# Azure Container Apps Deployment Script
# Zava AI Agent Workshop
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 Zava AI Agent - Azure Deployment Script                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# ============================================
# Configuration Variables
# ============================================
RESOURCE_PREFIX="${RESOURCE_PREFIX:-zava-agent}"
LOCATION="${LOCATION:-eastus2}"
UNIQUE_SUFFIX=$(echo $RANDOM | md5sum | head -c 4)

RESOURCE_GROUP="rg-${RESOURCE_PREFIX}-${UNIQUE_SUFFIX}"
ACR_NAME="${RESOURCE_PREFIX//-/}acr${UNIQUE_SUFFIX}"
CAE_NAME="cae-${RESOURCE_PREFIX}-${UNIQUE_SUFFIX}"
IDENTITY_NAME="id-${RESOURCE_PREFIX}-${UNIQUE_SUFFIX}"
KEYVAULT_NAME="kv-${RESOURCE_PREFIX}-${UNIQUE_SUFFIX}"
POSTGRES_SERVER="psql-${RESOURCE_PREFIX}-${UNIQUE_SUFFIX}"

# Container Apps names
CA_WEBAPP="ca-webapp"
CA_MCP="ca-mcp-server"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   ACR Name: $ACR_NAME"
echo "   Container Apps Environment: $CAE_NAME"
echo ""

# ============================================
# Step 1: Create Resource Group
# ============================================
echo -e "${GREEN}🔧 Step 1: Creating Resource Group...${NC}"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags "project=zava-agent-workshop" "environment=production"

# ============================================
# Step 2: Create User-Assigned Managed Identity
# ============================================
echo -e "${GREEN}🔐 Step 2: Creating Managed Identity...${NC}"
az identity create \
  --name "$IDENTITY_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

IDENTITY_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP" --query id -o tsv)
IDENTITY_PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP" --query principalId -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$RESOURCE_GROUP" --query clientId -o tsv)

echo "   Identity ID: $IDENTITY_ID"
echo "   Principal ID: $IDENTITY_PRINCIPAL_ID"

# ============================================
# Step 3: Create Azure Container Registry
# ============================================
echo -e "${GREEN}📦 Step 3: Creating Azure Container Registry...${NC}"
az acr create \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku Basic \
  --admin-enabled false

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_ID=$(az acr show --name "$ACR_NAME" --query id -o tsv)

# Assign AcrPull role to managed identity
echo "   Assigning AcrPull role to managed identity..."
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role AcrPull \
  --scope "$ACR_ID"

# ============================================
# Step 4: Create Azure Key Vault
# ============================================
echo -e "${GREEN}🔑 Step 4: Creating Azure Key Vault...${NC}"
az keyvault create \
  --name "$KEYVAULT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --enable-rbac-authorization true

KEYVAULT_ID=$(az keyvault show --name "$KEYVAULT_NAME" --query id -o tsv)
KEYVAULT_URI=$(az keyvault show --name "$KEYVAULT_NAME" --query properties.vaultUri -o tsv)

# Assign Key Vault Secrets User role to managed identity
echo "   Assigning Key Vault Secrets User role..."
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope "$KEYVAULT_ID"

# Get current user for admin access
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment create \
  --assignee "$CURRENT_USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KEYVAULT_ID"

# Wait for role propagation
echo "   Waiting for role propagation (30s)..."
sleep 30

# ============================================
# Step 5: Create Azure Database for PostgreSQL
# ============================================
echo -e "${GREEN}🗄️  Step 5: Creating Azure Database for PostgreSQL...${NC}"

# Generate secure password
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%' | head -c 24)

az postgres flexible-server create \
  --name "$POSTGRES_SERVER" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --admin-user pgadmin \
  --admin-password "$POSTGRES_PASSWORD" \
  --sku-name Standard_B1ms \
  --storage-size 32 \
  --version 16 \
  --yes

# Store password in Key Vault
az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "PostgresPassword" \
  --value "$POSTGRES_PASSWORD"

# Create database
az postgres flexible-server db create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$POSTGRES_SERVER" \
  --database-name zava

# Enable pgvector extension
az postgres flexible-server parameter set \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$POSTGRES_SERVER" \
  --name azure.extensions \
  --value vector

# Allow Azure services
az postgres flexible-server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_SERVER" \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

POSTGRES_FQDN=$(az postgres flexible-server show --name "$POSTGRES_SERVER" --resource-group "$RESOURCE_GROUP" --query fullyQualifiedDomainName -o tsv)

# Store connection string in Key Vault
POSTGRES_CONN_STRING="postgresql://pgadmin:${POSTGRES_PASSWORD}@${POSTGRES_FQDN}:5432/zava?sslmode=require"
az keyvault secret set \
  --vault-name "$KEYVAULT_NAME" \
  --name "PostgresConnectionString" \
  --value "$POSTGRES_CONN_STRING"

# ============================================
# Step 6: Build and Push Container Images
# ============================================
echo -e "${GREEN}🐳 Step 6: Building and pushing container images...${NC}"

# Build and push webapp image
echo "   Building webapp image..."
az acr build \
  --registry "$ACR_NAME" \
  --image zava-webapp:v1 \
  --file Dockerfile.webapp \
  .

# Build and push MCP server image
echo "   Building MCP server image..."
az acr build \
  --registry "$ACR_NAME" \
  --image zava-mcp:v1 \
  --file Dockerfile.mcp \
  .

# ============================================
# Step 7: Create Container Apps Environment
# ============================================
echo -e "${GREEN}🌐 Step 7: Creating Container Apps Environment...${NC}"
az containerapp env create \
  --name "$CAE_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"

# ============================================
# Step 8: Deploy Web Application
# ============================================
echo -e "${GREEN}🚀 Step 8: Deploying Web Application...${NC}"

az containerapp create \
  --name "$CA_WEBAPP" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CAE_NAME" \
  --image "${ACR_LOGIN_SERVER}/zava-webapp:v1" \
  --target-port 8000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 10 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --user-assigned "$IDENTITY_ID" \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-identity "$IDENTITY_ID" \
  --env-vars \
    "ENVIRONMENT=production" \
    "MODEL_DEPLOYMENT_NAME=gpt-4.1-mini"

WEBAPP_FQDN=$(az containerapp show --name "$CA_WEBAPP" --resource-group "$RESOURCE_GROUP" --query properties.configuration.ingress.fqdn -o tsv)

# ============================================
# Step 9: Output Deployment Information
# ============================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ✅ Deployment Completed Successfully!                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📋 Deployment Summary:${NC}"
echo "   Resource Group:     $RESOURCE_GROUP"
echo "   Location:           $LOCATION"
echo ""
echo -e "${GREEN}🔗 Access URLs:${NC}"
echo "   Web Application:    https://$WEBAPP_FQDN"
echo ""
echo -e "${GREEN}🔐 Security Resources:${NC}"
echo "   Key Vault:          $KEYVAULT_NAME"
echo "   Managed Identity:   $IDENTITY_NAME"
echo "   ACR:                $ACR_LOGIN_SERVER"
echo ""
echo -e "${GREEN}🗄️  Database:${NC}"
echo "   PostgreSQL Server:  $POSTGRES_FQDN"
echo "   Database:           zava"
echo ""
echo -e "${YELLOW}⚠️  Next Steps:${NC}"
echo "   1. Configure AZURE_AI_FOUNDRY_ENDPOINT in Container App settings"
echo "   2. Restore database backup to Azure PostgreSQL"
echo "   3. Test the application at https://$WEBAPP_FQDN"
echo ""

# Save deployment info to file
cat > deployment-info.json <<EOF
{
  "resourceGroup": "$RESOURCE_GROUP",
  "location": "$LOCATION",
  "webapp": {
    "name": "$CA_WEBAPP",
    "url": "https://$WEBAPP_FQDN"
  },
  "database": {
    "server": "$POSTGRES_FQDN",
    "database": "zava"
  },
  "security": {
    "keyVault": "$KEYVAULT_NAME",
    "managedIdentity": "$IDENTITY_NAME",
    "acr": "$ACR_LOGIN_SERVER"
  }
}
EOF

echo -e "${GREEN}📄 Deployment info saved to: deployment-info.json${NC}"
