# 🚀 Guía de Despliegue en Azure - Zava AI Agent (Cora)

## 📋 Índice

1. [Descripción del Proyecto](#descripción-del-proyecto)
2. [Arquitectura](#arquitectura)
3. [Requisitos Previos](#requisitos-previos)
4. [Recursos de Azure Necesarios](#recursos-de-azure-necesarios)
5. [Guía de Despliegue Paso a Paso](#guía-de-despliegue-paso-a-paso)
6. [Variables de Entorno](#variables-de-entorno)
7. [Cambios Realizados al Código Original](#cambios-realizados-al-código-original)
8. [Troubleshooting](#troubleshooting)
9. [Retos y Soluciones](#retos-y-soluciones)

---

## 📖 Descripción del Proyecto

### ¿Qué es este repositorio?

Este repositorio es parte del **AI Tour 2026 - BRK441** y demuestra cómo construir y desplegar agentes de IA rápidamente usando **Microsoft Foundry** y el **AI Toolkit**.

### ¿Qué es la aplicación Cora?

**Cora** es un asistente de IA inteligente para **Zava**, una marca de mejoras para el hogar (DIY - Do It Yourself). Cora ayuda a los clientes con sus proyectos de bricolaje:

- 🛠️ Entiende las necesidades del cliente a través de conversación natural
- 📦 Recomienda productos del catálogo de Zava
- 🖼️ Analiza imágenes de proyectos para sugerir materiales
- 📊 Consulta datos de ventas y clientes mediante herramientas MCP

### Tecnologías Principales

| Componente | Tecnología |
|------------|------------|
| **Framework de Agentes** | Agent Framework (agent-framework-core, agent-framework-azure-ai) |
| **Backend** | FastAPI + Uvicorn |
| **Frontend** | HTML/CSS/JavaScript (WebSocket) |
| **Base de Datos** | PostgreSQL 16 con pgvector |
| **IA/LLM** | Azure OpenAI (gpt-4o-mini) |
| **Contenedores** | Azure Container Apps |
| **Autenticación** | Azure Managed Identity |
| **Herramientas** | MCP (Model Context Protocol) Servers |

---

## 🏗️ Arquitectura

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AZURE RESOURCE GROUP                                │
│                                  (AITourMx)                                      │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                     CONTAINER APPS ENVIRONMENT                           │    │
│  │                      (cae-zava-agent-mx)                                │    │
│  │                                                                          │    │
│  │   ┌─────────────────────────────────────────────────────────────────┐   │    │
│  │   │                   CONTAINER APP (ca-webapp)                      │   │    │
│  │   │                                                                  │   │    │
│  │   │  ┌──────────────────┐     ┌──────────────────────────────────┐  │   │    │
│  │   │  │   FastAPI App    │────▶│      Agent Framework             │  │   │    │
│  │   │  │   (web_app.py)   │     │  ┌────────────────────────────┐  │  │   │    │
│  │   │  │                  │     │  │  OpenAIChatClient          │  │  │   │    │
│  │   │  │  • WebSocket     │     │  │  (Azure OpenAI)            │  │  │   │    │
│  │   │  │  • REST API      │     │  └────────────────────────────┘  │  │   │    │
│  │   │  │  • Static Files  │     │  ┌────────────────────────────┐  │  │   │    │
│  │   │  └──────────────────┘     │  │  MCPStdioTool              │  │  │   │    │
│  │   │                           │  │  (customer_sales.py)       │──┼──┼───┼────┼──┐
│  │   │                           │  └────────────────────────────┘  │  │   │    │  │
│  │   │                           └──────────────────────────────────┘  │   │    │  │
│  │   └─────────────────────────────────────────────────────────────────┘   │    │  │
│  │                                      │                                   │    │  │
│  │                                      │ Managed Identity                  │    │  │
│  │                                      ▼                                   │    │  │
│  │   ┌─────────────────────────────────────────────────────────────────┐   │    │  │
│  │   │              USER-ASSIGNED MANAGED IDENTITY                      │   │    │  │
│  │   │                    (id-zava-agent)                              │   │    │  │
│  │   │                                                                  │   │    │  │
│  │   │   Client ID: 432005aa-4a63-48de-be1c-fb65b8fdfae0              │   │    │  │
│  │   └─────────────────────────────────────────────────────────────────┘   │    │  │
│  │                                                                          │    │  │
│  └──────────────────────────────────────────────────────────────────────────┘    │  │
│                                                                                   │  │
│  ┌────────────────────────────────┐     ┌────────────────────────────────┐      │  │
│  │      AZURE AI SERVICES         │     │    AZURE CONTAINER REGISTRY    │      │  │
│  │      (foundry-zava-mx)         │     │      (zavaagentacrmx)          │      │  │
│  │                                │     │                                │      │  │
│  │  • Endpoint: foundry-zava-mx   │     │  • Images: zava-webapp:v11    │      │  │
│  │    .services.ai.azure.com      │     │  • Private registry           │      │  │
│  │  • Model: gpt-4o-mini          │     │  • Managed Identity auth      │      │  │
│  │  • 30K TPM capacity            │     │                                │      │  │
│  └────────────────────────────────┘     └────────────────────────────────┘      │  │
│                                                                                   │  │
│  ┌────────────────────────────────┐     ┌────────────────────────────────┐      │  │
│  │   POSTGRESQL FLEXIBLE SERVER   │◀────│       KEY VAULT                │      │  │
│  │      (psql-zava-mx)            │     │    (kv-zava-agent-mx)         │      │  │
│  │                                │     │                                │      │  │
│  │  • PostgreSQL 16               │     │  • Secrets storage            │      │  │
│  │  • pgvector extension          │     │  • POSTGRES_URL               │      │  │
│  │  • Database: zava              │     │  • AI endpoints               │      │  │
│  │  • Schema: retail              │     │                                │◀─────┼──┘
│  └────────────────────────────────┘     └────────────────────────────────┘      │
│                                                                                   │
└───────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   USUARIOS                                       │
│                                                                                  │
│   ┌─────────────┐                                                               │
│   │   Browser   │───────────────▶ https://ca-webapp.agreeablemushroom-3ff8ea5f  │
│   │  (WebSocket)│                 .eastus2.azurecontainerapps.io                │
│   └─────────────┘                                                               │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Flujo de Datos

```
┌──────────┐    WebSocket     ┌──────────────┐    Agent Framework    ┌─────────────┐
│  Usuario │ ───────────────▶ │   FastAPI    │ ─────────────────────▶│  ChatAgent  │
│ (Browser)│ ◀─────────────── │  (web_app)   │ ◀─────────────────────│             │
└──────────┘    Streaming     └──────────────┘                       └──────┬──────┘
                                                                            │
                              ┌─────────────────────────────────────────────┼──────────┐
                              │                                             │          │
                              ▼                                             ▼          │
                    ┌──────────────────┐                        ┌──────────────────┐   │
                    │  Azure OpenAI    │                        │    MCP Server    │   │
                    │  (gpt-4o-mini)   │                        │ (customer_sales) │   │
                    │                  │                        │                  │   │
                    │ • Chat completion│                        │ • get_products   │   │
                    │ • Tool calling   │                        │ • get_sales      │   │
                    │ • Streaming      │                        │ • search_catalog │   │
                    └──────────────────┘                        └────────┬─────────┘   │
                                                                         │             │
                                                                         ▼             │
                                                                ┌──────────────────┐   │
                                                                │    PostgreSQL    │   │
                                                                │    (Database)    │   │
                                                                │                  │   │
                                                                │ • Products       │   │
                                                                │ • Customers      │   │
                                                                │ • Sales          │   │
                                                                │ • Embeddings     │   │
                                                                └──────────────────┘   │
                                                                                       │
                              ◀────────────────────────────────────────────────────────┘
                                            Tool Results
```

---

## ✅ Requisitos Previos

### Herramientas Locales

```bash
# Azure CLI (versión 2.50+)
az --version

# Docker Desktop
docker --version

# Python 3.11+
python --version

# Git
git --version
```

### Permisos de Azure

- **Contributor** en el Resource Group
- **Cognitive Services OpenAI User** para el modelo
- **AcrPush** en el Container Registry

---

## 🏢 Recursos de Azure Necesarios

| Recurso | Nombre | Propósito |
|---------|--------|-----------|
| Resource Group | `AITourMx` | Contenedor de todos los recursos |
| Container Apps Environment | `cae-zava-agent-mx` | Entorno para contenedores |
| Container App | `ca-webapp` | Aplicación principal |
| Container Registry | `zavaagentacrmx` | Registro de imágenes Docker |
| PostgreSQL Flexible Server | `psql-zava-mx` | Base de datos |
| Azure AI Services | `foundry-zava-mx` | Servicio de IA (gpt-4o-mini) |
| User-Assigned Managed Identity | `id-zava-agent` | Autenticación sin credenciales |
| Key Vault | `kv-zava-agent-mx` | Almacenamiento de secretos |

---

## 📝 Guía de Despliegue Paso a Paso

### Paso 1: Configurar Variables de Entorno

```bash
# Variables base
export RESOURCE_GROUP="AITourMx"
export LOCATION="eastus2"
export ACR_NAME="zavaagentacrmx"
export CONTAINER_APP_NAME="ca-webapp"
export CONTAINER_ENV_NAME="cae-zava-agent-mx"
export POSTGRES_SERVER="psql-zava-mx"
export AI_SERVICES_NAME="foundry-zava-mx"
export MANAGED_IDENTITY_NAME="id-zava-agent"
export KEY_VAULT_NAME="kv-zava-agent-mx"
```

### Paso 2: Crear Resource Group

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Paso 3: Crear Managed Identity

```bash
az identity create \
    --name $MANAGED_IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP

# Obtener el client_id y principal_id
MANAGED_IDENTITY_CLIENT_ID=$(az identity show \
    --name $MANAGED_IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP \
    --query clientId -o tsv)

MANAGED_IDENTITY_PRINCIPAL_ID=$(az identity show \
    --name $MANAGED_IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP \
    --query principalId -o tsv)

echo "Client ID: $MANAGED_IDENTITY_CLIENT_ID"
echo "Principal ID: $MANAGED_IDENTITY_PRINCIPAL_ID"
```

### Paso 4: Crear Container Registry

```bash
az acr create \
    --name $ACR_NAME \
    --resource-group $RESOURCE_GROUP \
    --sku Basic \
    --admin-enabled false

# Asignar rol AcrPull a la Managed Identity
ACR_ID=$(az acr show --name $ACR_NAME --query id -o tsv)
az role assignment create \
    --assignee $MANAGED_IDENTITY_PRINCIPAL_ID \
    --role AcrPull \
    --scope $ACR_ID
```

### Paso 5: Crear PostgreSQL

```bash
az postgres flexible-server create \
    --name $POSTGRES_SERVER \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --admin-user pgadmin \
    --admin-password "YourSecurePassword123#" \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --version 16 \
    --storage-size 32 \
    --public-access 0.0.0.0

# Crear regla de firewall para Azure Services
az postgres flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $POSTGRES_SERVER \
    --rule-name AllowAllAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# Crear base de datos
az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $POSTGRES_SERVER \
    --database-name zava
```

### Paso 6: Crear Azure AI Services

```bash
az cognitiveservices account create \
    --name $AI_SERVICES_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --kind AIServices \
    --sku S0 \
    --custom-domain $AI_SERVICES_NAME

# Desplegar modelo gpt-4o-mini
az cognitiveservices account deployment create \
    --name $AI_SERVICES_NAME \
    --resource-group $RESOURCE_GROUP \
    --deployment-name gpt-4o-mini \
    --model-name gpt-4o-mini \
    --model-version "2024-07-18" \
    --model-format OpenAI \
    --sku-capacity 30 \
    --sku-name GlobalStandard

# Asignar rol a la Managed Identity
AI_SERVICES_ID=$(az cognitiveservices account show \
    --name $AI_SERVICES_NAME \
    --resource-group $RESOURCE_GROUP \
    --query id -o tsv)

az role assignment create \
    --assignee $MANAGED_IDENTITY_PRINCIPAL_ID \
    --role "Cognitive Services OpenAI User" \
    --scope $AI_SERVICES_ID
```

### Paso 7: Construir y Subir Imagen Docker

```bash
# Login al ACR
az acr login --name $ACR_NAME

# Construir imagen
docker build -f Dockerfile.webapp -t $ACR_NAME.azurecr.io/zava-webapp:v1 .

# Subir imagen
docker push $ACR_NAME.azurecr.io/zava-webapp:v1
```

### Paso 8: Crear Container Apps Environment

```bash
az containerapp env create \
    --name $CONTAINER_ENV_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION
```

### Paso 9: Crear Container App

```bash
# Obtener la URL de PostgreSQL
POSTGRES_URL="postgresql://pgadmin:YourSecurePassword123%23@${POSTGRES_SERVER}.postgres.database.azure.com:5432/zava?sslmode=require"

# Obtener el endpoint de AI Services
AI_ENDPOINT="https://${AI_SERVICES_NAME}.services.ai.azure.com/"

# Obtener el ID del Managed Identity
MANAGED_IDENTITY_RESOURCE_ID=$(az identity show \
    --name $MANAGED_IDENTITY_NAME \
    --resource-group $RESOURCE_GROUP \
    --query id -o tsv)

# Crear Container App
az containerapp create \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_ENV_NAME \
    --image $ACR_NAME.azurecr.io/zava-webapp:v1 \
    --target-port 8000 \
    --ingress external \
    --min-replicas 1 \
    --max-replicas 10 \
    --cpu 0.5 \
    --memory 1Gi \
    --user-assigned $MANAGED_IDENTITY_RESOURCE_ID \
    --registry-server $ACR_NAME.azurecr.io \
    --registry-identity $MANAGED_IDENTITY_RESOURCE_ID \
    --env-vars \
        "ENVIRONMENT=production" \
        "POSTGRES_URL=$POSTGRES_URL" \
        "AZURE_AI_FOUNDRY_ENDPOINT=$AI_ENDPOINT" \
        "MODEL_DEPLOYMENT_NAME=gpt-4o-mini" \
        "AZURE_CLIENT_ID=$MANAGED_IDENTITY_CLIENT_ID"
```

### Paso 10: Verificar Despliegue

```bash
# Obtener URL de la aplicación
az containerapp show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "properties.configuration.ingress.fqdn" -o tsv

# Ver logs
az containerapp logs show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --tail 50
```

---

## 🔧 Variables de Entorno

### Variables Requeridas en Container App

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `ENVIRONMENT` | Entorno de ejecución | `production` |
| `POSTGRES_URL` | URL de conexión PostgreSQL | `postgresql://user:pass@host:5432/db?sslmode=require` |
| `AZURE_AI_FOUNDRY_ENDPOINT` | Endpoint de Azure AI Services | `https://foundry-zava-mx.services.ai.azure.com/` |
| `MODEL_DEPLOYMENT_NAME` | Nombre del deployment del modelo | `gpt-4o-mini` |
| `AZURE_CLIENT_ID` | Client ID del Managed Identity | `432005aa-4a63-48de-be1c-fb65b8fdfae0` |

---

## 🔄 Cambios Realizados al Código Original

### 1. Dockerfile.webapp (Línea 16)

**Problema:** Los paquetes `agent-framework-*` son versiones preview.

**Cambio:**
```dockerfile
# Antes
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Después
RUN pip wheel --no-cache-dir --wheel-dir /wheels --pre -r requirements.txt
```

### 2. src/python/requirements.txt

**Problema:** Conflictos de versiones y paquetes faltantes.

**Cambios:**
```txt
# Agregados
agent-framework-core==1.0.0b260123
agent-framework-azure-ai==1.0.0b260123

# Modificados (sin restricción de versión superior)
# openai (sin restricción, manejado por agent-framework)
# httpx>=0.28.1 (sin límite superior)
```

### 3. src/python/web_app/web_app.py

#### 3.1 Imports (Líneas 27-30)

**Antes:**
```python
from agent_framework import ChatAgent, MCPStdioTool, ToolProtocol, ChatMessage, Content, Role
from agent_framework_azure_ai import AzureAIClient
from azure.identity.aio import DefaultAzureCredential
```

**Después:**
```python
from agent_framework import ChatAgent, MCPStdioTool, ToolProtocol, ChatMessage, Content, Role
from agent_framework.openai import OpenAIChatClient
from openai import AsyncAzureOpenAI
from azure.identity.aio import DefaultAzureCredential, get_bearer_token_provider
```

#### 3.2 Ruta Base para Archivos Estáticos (Línea 18-21)

**Problema:** La ruta era incorrecta en el contenedor.

**Antes:**
```python
BASE_SRC_DIR = Path(__file__).resolve().parents[2]  # -> /workspace/src
```

**Después:**
```python
# In container: /app/web_app/web_app.py -> parents[1] = /app
BASE_APP_DIR = Path(__file__).resolve().parents[1]  # -> /app or /workspace/src/python
SHARED_STATIC_DIR = BASE_APP_DIR / "shared" / "static"
```

#### 3.3 Función create_mcp_tools() (Líneas 69-91)

**Problema:** Ruta del MCP server incorrecta y variables de entorno no pasadas.

**Después:**
```python
def create_mcp_tools() -> list[ToolProtocol]:
    """Create MCP tools for the agent"""
    # Determine the correct path for MCP server based on environment
    mcp_script_path = Path("/app/mcp_server/customer_sales/customer_sales.py")
    if not mcp_script_path.exists():
        mcp_script_path = Path("src/python/mcp_server/customer_sales/customer_sales.py")
    
    # Pass required environment variables to the MCP server subprocess
    mcp_env = {
        "POSTGRES_URL": os.environ.get("POSTGRES_URL", ""),
        "PYTHONPATH": "/app/mcp_server/customer_sales",
    }
    
    return [
        MCPStdioTool(
            name="zava_customer_sales_stdio",
            description="MCP server for Zava customer sales analysis",
            command="python",
            args=[
                str(mcp_script_path),
                "--stdio",
                "--RLS_USER_ID=00000000-0000-0000-0000-000000000000",
            ],
            env=mcp_env,
        ),
    ]
```

#### 3.4 Función initialize_agent() (Líneas 136-182)

**Problema:** `AzureAIClient` requería un Azure AI Foundry Hub/Project real, no solo AI Services.

**Después:**
```python
async def initialize_agent():
    """Initialize the Agent Framework agent using OpenAIChatClient with Azure OpenAI"""
    global agent_instance, credential_instance
    if agent_instance is None:
        try:
            # Use ManagedIdentityCredential with client_id for user-assigned identity
            if AZURE_CLIENT_ID:
                from azure.identity.aio import ManagedIdentityCredential
                credential_instance = ManagedIdentityCredential(client_id=AZURE_CLIENT_ID)
                logger.info(f"Using User-Assigned Managed Identity with client_id: {AZURE_CLIENT_ID}")
            else:
                credential_instance = DefaultAzureCredential()
                logger.info("Using DefaultAzureCredential")
            
            # Create bearer token provider for Azure OpenAI authentication
            token_provider = get_bearer_token_provider(
                credential_instance,
                "https://cognitiveservices.azure.com/.default"
            )
            
            # Create AsyncAzureOpenAI client
            azure_client = AsyncAzureOpenAI(
                azure_endpoint=ENDPOINT,
                azure_ad_token_provider=token_provider,
                api_version="2024-10-21",
            )
            
            # Create OpenAIChatClient with the Azure client
            chat_client = OpenAIChatClient(
                model_id=MODEL_DEPLOYMENT_NAME,
                async_client=azure_client,
            )
            
            # Create agent with the chat client
            agent_instance = ChatAgent(
                name=AGENT_NAME,
                instructions=AGENT_INSTRUCTIONS,
                chat_client=chat_client,
                tools=[*create_mcp_tools()],
            )
            logger.info("Agent Framework initialized successfully with OpenAIChatClient for Azure OpenAI")
        except Exception as e:
            logger.error(f"Failed to initialize Agent Framework: {e}")
            import traceback
            traceback.print_exc()
            agent_instance = None
```

#### 3.5 Content.from_bytes → Content.from_data (Línea 297)

**Problema:** El método `from_bytes` no existe en la versión actual.

**Antes:**
```python
Content.from_bytes(data=image_bytes, media_type=mime_type)
```

**Después:**
```python
Content.from_data(data=image_bytes, media_type=mime_type)
```

---

## 🔧 Troubleshooting

### Error: ModuleNotFoundError: agent_framework

**Causa:** Los paquetes `agent-framework-*` son preview y requieren el flag `--pre`.

**Solución:**
```bash
pip install --pre agent-framework-core agent-framework-azure-ai
```

### Error: Connection closed (MCP Server)

**Causa:** El MCP server no puede conectarse a PostgreSQL.

**Soluciones:**
1. Verificar que PostgreSQL esté **iniciado** (no detenido):
   ```bash
   az postgres flexible-server show --resource-group AITourMx --name psql-zava-mx --query "state"
   ```
2. Si está detenido, iniciarlo:
   ```bash
   az postgres flexible-server start --resource-group AITourMx --name psql-zava-mx
   ```
3. Verificar reglas de firewall:
   ```bash
   az postgres flexible-server firewall-rule list --resource-group AITourMx --name psql-zava-mx
   ```

### Error: DefaultAzureCredential failed

**Causa:** El Container App tiene User-Assigned Managed Identity pero `DefaultAzureCredential` no lo detecta.

**Solución:** Agregar la variable `AZURE_CLIENT_ID` con el client_id del Managed Identity:
```bash
az containerapp update --name ca-webapp --resource-group AITourMx \
    --set-env-vars "AZURE_CLIENT_ID=<client-id>"
```

### Error: DeploymentNotFound (404)

**Causa:** El nombre del deployment del modelo no coincide.

**Solución:**
1. Verificar el nombre correcto:
   ```bash
   az cognitiveservices account deployment list --name foundry-zava-mx --resource-group AITourMx
   ```
2. Actualizar la variable de entorno:
   ```bash
   az containerapp update --name ca-webapp --resource-group AITourMx \
       --set-env-vars "MODEL_DEPLOYMENT_NAME=gpt-4o-mini"
   ```

### Error: 429 Too Many Requests

**Causa:** Se excedió el límite de TPM (Tokens Per Minute) del modelo.

**Solución:** Aumentar la capacidad del deployment:
```bash
az cognitiveservices account deployment create \
    --name foundry-zava-mx \
    --resource-group AITourMx \
    --deployment-name gpt-4o-mini \
    --sku-capacity 60 \
    --sku-name GlobalStandard
```

### Error: Static directory not found

**Causa:** La ruta de archivos estáticos es diferente en el contenedor.

**Solución:** Usar `parents[1]` en lugar de `parents[2]` para la ruta base:
```python
BASE_APP_DIR = Path(__file__).resolve().parents[1]  # /app
```

---

## 🎯 Retos y Soluciones

### Reto 1: Compatibilidad de Agent Framework

**Descripción:** El repositorio original usaba `AzureAIClient` que requiere un Azure AI Foundry Hub/Project completo (no solo AI Services).

**Solución:** Cambiar a `OpenAIChatClient` con `AsyncAzureOpenAI` que funciona con Azure AI Services (Azure OpenAI).

### Reto 2: User-Assigned Managed Identity

**Descripción:** `DefaultAzureCredential` no detecta automáticamente las User-Assigned Managed Identities en Container Apps.

**Solución:** Usar `ManagedIdentityCredential` explícitamente con el `client_id`:
```python
ManagedIdentityCredential(client_id=AZURE_CLIENT_ID)
```

### Reto 3: MCP Server como Subproceso

**Descripción:** El MCP server se ejecuta como un subproceso pero no hereda las variables de entorno del proceso padre.

**Solución:** Pasar las variables explícitamente usando el parámetro `env` de `MCPStdioTool`:
```python
MCPStdioTool(
    ...,
    env={"POSTGRES_URL": os.environ.get("POSTGRES_URL", "")}
)
```

### Reto 4: Rutas Diferentes en Contenedor

**Descripción:** Las rutas de archivos son diferentes entre desarrollo local (`src/python/...`) y el contenedor (`/app/...`).

**Solución:** Detectar el entorno dinámicamente:
```python
mcp_script_path = Path("/app/mcp_server/customer_sales/customer_sales.py")
if not mcp_script_path.exists():
    mcp_script_path = Path("src/python/mcp_server/customer_sales/customer_sales.py")
```

### Reto 5: PostgreSQL Auto-Pause

**Descripción:** Azure PostgreSQL Flexible Server puede detenerse automáticamente para ahorrar costos.

**Solución:** Verificar el estado y reiniciar si es necesario:
```bash
az postgres flexible-server start --resource-group AITourMx --name psql-zava-mx
```

### Reto 6: Versiones Preview de Paquetes

**Descripción:** Los paquetes `agent-framework-*` son versiones beta/preview y requieren el flag `--pre` para instalarse.

**Solución:** Modificar el Dockerfile:
```dockerfile
RUN pip wheel --no-cache-dir --wheel-dir /wheels --pre -r requirements.txt
```

---

## 📊 Resumen de Recursos Desplegados

| Recurso | Endpoint/URL |
|---------|--------------|
| **Container App** | https://ca-webapp.agreeablemushroom-3ff8ea5f.eastus2.azurecontainerapps.io |
| **Azure AI Services** | https://foundry-zava-mx.services.ai.azure.com/ |
| **PostgreSQL** | psql-zava-mx.postgres.database.azure.com |
| **Container Registry** | zavaagentacrmx.azurecr.io |
| **Key Vault** | kv-zava-agent-mx.vault.azure.net |

---

## 📁 Estructura de Archivos Modificados

```
aitour26-BRK441-Build-and-launch-AI-agents-fast-with-Microsoft-Foundry-and-the-AI-Toolkit-Mexico/
├── Dockerfile.webapp                    # ✏️ Agregado --pre flag
├── src/
│   └── python/
│       ├── requirements.txt             # ✏️ Versiones de paquetes actualizadas
│       ├── web_app/
│       │   └── web_app.py               # ✏️ Múltiples correcciones
│       └── mcp_server/
│           └── customer_sales/
│               └── customer_sales.py    # (sin cambios)
└── AZURE_DEPLOYMENT_GUIDE.md            # ✨ NUEVO - Esta documentación
```

---

## 🔄 Script de Despliegue Automatizado

Para despliegues repetibles, puedes crear un script:

```bash
#!/bin/bash
# deploy.sh - Script de despliegue automatizado

set -e

# Configuración
RESOURCE_GROUP="${1:-AITourMx}"
LOCATION="${2:-eastus2}"
IMAGE_TAG="${3:-latest}"

echo "🚀 Desplegando en Resource Group: $RESOURCE_GROUP"

# 1. Verificar que PostgreSQL esté iniciado
echo "📊 Verificando PostgreSQL..."
PG_STATE=$(az postgres flexible-server show --resource-group $RESOURCE_GROUP --name psql-zava-mx --query "state" -o tsv 2>/dev/null || echo "NotFound")
if [ "$PG_STATE" == "Stopped" ]; then
    echo "⏳ Iniciando PostgreSQL..."
    az postgres flexible-server start --resource-group $RESOURCE_GROUP --name psql-zava-mx
fi

# 2. Construir y subir imagen
echo "🐳 Construyendo imagen Docker..."
docker build -f Dockerfile.webapp -t zavaagentacrmx.azurecr.io/zava-webapp:$IMAGE_TAG .

echo "📤 Subiendo imagen..."
az acr login --name zavaagentacrmx
docker push zavaagentacrmx.azurecr.io/zava-webapp:$IMAGE_TAG

# 3. Actualizar Container App
echo "🔄 Actualizando Container App..."
az containerapp update \
    --name ca-webapp \
    --resource-group $RESOURCE_GROUP \
    --image zavaagentacrmx.azurecr.io/zava-webapp:$IMAGE_TAG

# 4. Verificar despliegue
echo "✅ Verificando despliegue..."
sleep 30
az containerapp logs show --name ca-webapp --resource-group $RESOURCE_GROUP --tail 20

echo "🎉 Despliegue completado!"
echo "🌐 URL: https://$(az containerapp show --name ca-webapp --resource-group $RESOURCE_GROUP --query 'properties.configuration.ingress.fqdn' -o tsv)"
```

---

## 📝 Notas Finales

1. **Costos:** El despliegue incluye PostgreSQL Burstable, Container Apps (consumo), y Azure AI Services - estima ~$50-100 USD/mes para uso de desarrollo.

2. **Seguridad:** Usa Managed Identity para autenticación - no hay credenciales hardcodeadas.

3. **Escalabilidad:** Container Apps escala automáticamente de 1 a 10 réplicas según demanda.

4. **Monitoreo:** Usa Azure Monitor y Application Insights para observabilidad.

---

*Documentación generada: Enero 26, 2026*
*Versión de imagen: v11*
*Agent Framework: 1.0.0b260123*
