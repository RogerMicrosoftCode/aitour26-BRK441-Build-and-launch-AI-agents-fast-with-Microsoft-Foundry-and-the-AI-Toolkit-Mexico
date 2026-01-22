# 📊 Análisis Técnico Integral - Zava AI Agent Workshop

**Fecha de Análisis:** 22 de Enero de 2026  
**Proyecto:** AI Tour 26 - BRK441 - Build and Launch AI Agents Fast  
**Versión:** 1.0.0

---

## 📑 FASE 1: Análisis Técnico Profundo

### 1.1 Resumen de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ARQUITECTURA DEL SISTEMA                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌─────────────┐     WebSocket      ┌──────────────────────────────┐   │
│   │   Browser   │ ◄──────────────────►│     FastAPI Web App         │   │
│   │  (index.html)│                    │   (web_app.py:8000)         │   │
│   └─────────────┘                    └──────────┬───────────────────┘   │
│                                                  │                       │
│                                                  │ Agent Framework       │
│                                                  ▼                       │
│                                      ┌──────────────────────────────┐   │
│                                      │      Azure AI Foundry        │   │
│                                      │    (gpt-4.1-mini model)      │   │
│                                      └──────────┬───────────────────┘   │
│                                                  │                       │
│                                                  │ MCP Protocol          │
│                                                  ▼                       │
│                                      ┌──────────────────────────────┐   │
│                                      │       MCP Server             │   │
│                                      │  (customer_sales.py)         │   │
│                                      └──────────┬───────────────────┘   │
│                                                  │                       │
│                                                  │ asyncpg               │
│                                                  ▼                       │
│                                      ┌──────────────────────────────┐   │
│                                      │     PostgreSQL + pgvector    │   │
│                                      │    (port 5432 / 15432)       │   │
│                                      └──────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Componentes del Sistema

| Componente | Tecnología | Archivo Principal | Puerto |
|------------|------------|-------------------|--------|
| **Frontend** | HTML/CSS/JS + Jinja2 | `src/shared/static/index.html` | 8000 |
| **Backend API** | FastAPI + Uvicorn | `src/python/web_app/web_app.py` | 8000 |
| **MCP Server** | FastMCP | `src/python/mcp_server/customer_sales/customer_sales.py` | stdio/HTTP |
| **Database** | PostgreSQL 17 + pgvector | Docker container | 15432 → 5432 |
| **AI Service** | Azure AI Foundry | Endpoint externo | HTTPS |

### 1.3 Frameworks y Dependencias

#### Backend (Python 3.11+)
```
┌──────────────────────────────────────────────────────────────┐
│ DEPENDENCIAS PRINCIPALES                                     │
├──────────────────────────────────────────────────────────────┤
│ FastAPI              - Framework web async                   │
│ Uvicorn              - ASGI server                          │
│ azure-ai-agents      - Azure AI Agents SDK (1.1.0b4)        │
│ azure-ai-projects    - Azure AI Projects SDK (1.0.0b12)     │
│ azure-identity       - Azure authentication                 │
│ asyncpg              - PostgreSQL async driver              │
│ mcp                  - Model Context Protocol (1.10.0)      │
│ openai               - OpenAI SDK                           │
│ python-dotenv        - Environment variables                │
│ Jinja2               - Template engine                      │
│ aiohttp              - Async HTTP client                    │
│ httpx                - HTTP client                          │
└──────────────────────────────────────────────────────────────┘
```

### 1.4 Evaluación de Código

#### ✅ Fortalezas Identificadas

| Área | Descripción |
|------|-------------|
| **Arquitectura** | Separación clara entre web app, MCP server y database |
| **Async/Await** | Uso consistente de programación asíncrona |
| **Seguridad BD** | Implementación de Row Level Security (RLS) |
| **Configuración** | Uso de `python-dotenv` y variables de entorno |
| **Logging** | Logging básico implementado con niveles apropiados |
| **Health Checks** | Endpoint `/health` disponible en web app |
| **Infrastructure as Code** | Bicep templates para Azure deployment |

#### ⚠️ Áreas de Mejora Identificadas

| Prioridad | Área | Problema | Recomendación |
|-----------|------|----------|---------------|
| 🔴 Alta | Secretos | Credenciales de DB en docker-compose | Usar Azure Key Vault |
| 🔴 Alta | Autenticación | No hay auth en WebSocket | Implementar JWT/OAuth2 |
| 🟡 Media | CORS | No configurado explícitamente | Añadir middleware CORS |
| 🟡 Media | Validación | Input validation limitada | Usar Pydantic validators |
| 🟡 Media | Rate Limiting | No implementado | Añadir slowapi/rate limiter |
| 🟢 Baja | Tests | Sin tests unitarios | Añadir pytest suite |
| 🟢 Baja | Documentación | API sin OpenAPI completo | Documentar endpoints |

### 1.5 Flujos de Datos

```
┌─────────────────────────────────────────────────────────────────┐
│ FLUJO: Usuario envía mensaje de chat                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Browser ──WebSocket──► FastAPI /ws endpoint                 │
│  2. FastAPI ──► initialize_agent() (si es necesario)            │
│  3. Agent Framework ──► Azure AI Foundry (gpt-4.1-mini)         │
│  4. Agent ──MCP──► customer_sales.py tools                      │
│  5. MCP Server ──asyncpg──► PostgreSQL (con RLS)                │
│  6. Respuesta fluye de regreso por el mismo camino              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ FLUJO: Upload de imagen                                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Browser ──POST /upload-image──► FastAPI                     │
│  2. FastAPI ──► Guarda en /uploads/{uuid}.{ext}                 │
│  3. Retorna URL de imagen                                       │
│  4. Siguiente mensaje incluye image_url                         │
│  5. Imagen se codifica en DataContent para el agente            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📑 FASE 2: Inventario de Variables de Entorno

### 2.1 Variables Requeridas

#### Archivo `.env` (Desarrollo Local)

```env
# ============================================
# AZURE AI FOUNDRY (REQUERIDO)
# ============================================
AZURE_AI_FOUNDRY_ENDPOINT="https://<your-project>.services.ai.azure.com/api/projects/<project-name>"

# ============================================
# MODEL DEPLOYMENT (OPCIONAL - tiene default)
# ============================================
MODEL_DEPLOYMENT_NAME="gpt-4.1-mini"

# ============================================
# ROW LEVEL SECURITY (REQUERIDO para MCP)
# ============================================
# ID del usuario/tienda para filtrar datos
RLS_USER_ID="00000000-0000-0000-0000-000000000000"

# IDs disponibles por tienda:
# - Zava Retail Seattle:   f47ac10b-58cc-4372-a567-0e02b2c3d479
# - Zava Retail Bellevue:  6ba7b810-9dad-11d1-80b4-00c04fd430c8
# - Zava Retail Tacoma:    a1b2c3d4-e5f6-7890-abcd-ef1234567890
# - Zava Retail Spokane:   d8e9f0a1-b2c3-4567-8901-234567890abc
# - Zava Retail Everett:   3b9ac9fa-cd5e-4b92-a7f2-b8c1d0e9f2a3
# - Zava Retail Redmond:   e7f8a9b0-c1d2-3e4f-5678-90abcdef1234
# - Zava Retail Kirkland:  9c8b7a65-4321-fed0-9876-543210fedcba
# - Zava Retail Online:    2f4e6d8c-1a3b-5c7e-9f0a-b2d4f6e8c0a2

# ============================================
# POSTGRESQL (USADO POR MCP SERVER)
# ============================================
POSTGRES_URL="postgresql://store_manager:StoreManager123!@localhost:15432/zava"

# ============================================
# ENVIRONMENT FLAG
# ============================================
ENVIRONMENT="development"
```

### 2.2 Variables en Docker Compose

| Servicio | Variable | Valor | Uso |
|----------|----------|-------|-----|
| db | POSTGRES_DB | postgres | Base de datos inicial |
| db | POSTGRES_USER | postgres | Usuario administrador |
| db | POSTGRES_PASSWORD | P@ssw0rd! | ⚠️ Migrar a Key Vault |
| devcontainer | ENVIRONMENT | container | Flag de entorno |
| devcontainer | POSTGRES_URL | postgresql://... | Conexión a BD |

### 2.3 Variables para Azure Production

```env
# ============================================
# AZURE CONTAINER APPS - PRODUCCIÓN
# ============================================

# Conexión a Azure AI Foundry
AZURE_AI_FOUNDRY_ENDPOINT="https://<foundry-name>.services.ai.azure.com/api/projects/<project>"

# Modelo deployment
MODEL_DEPLOYMENT_NAME="gpt-4.1-mini"

# PostgreSQL (Azure Database for PostgreSQL Flexible Server)
POSTGRES_URL="postgresql://<user>@<server>:<password>@<server>.postgres.database.azure.com:5432/zava?sslmode=require"

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=...;IngestionEndpoint=..."

# RLS User ID (desde header HTTP o claim JWT)
RLS_USER_ID="<from-request-context>"

# CORS Origins
CORS_ORIGINS="https://<frontend-app>.azurecontainerapps.io"
```

### 2.4 Secretos a Migrar a Azure Key Vault

| Secreto | Valor Actual | Nombre en Key Vault |
|---------|--------------|---------------------|
| DB Password | P@ssw0rd! | PostgresAdminPassword |
| DB User Password | StoreManager123! | PostgresUserPassword |
| Connection String | postgresql://... | PostgresConnectionString |

---

## 📑 FASE 3: Contenerización

### 3.1 Estructura de Contenedores Actual

```
┌─────────────────────────────────────────────────────────────┐
│ CONTENEDORES EXISTENTES                                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────┐                                    │
│  │  devcontainer       │ ◄── Development container          │
│  │  Python 3.13        │     con todas las dependencias     │
│  │  + Azure CLI        │                                    │
│  └──────────┬──────────┘                                    │
│             │                                                │
│             │ depends_on                                     │
│             ▼                                                │
│  ┌─────────────────────┐                                    │
│  │  db                 │ ◄── PostgreSQL 17 + pgvector       │
│  │  pgvector/pgvector  │     Incluye backup restaurado      │
│  │  :pg17              │     con RLS configurado            │
│  └─────────────────────┘                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Dockerfiles Optimizados para Producción

Los Dockerfiles optimizados se crearán en la siguiente sección.

---

## 📑 Análisis de Seguridad

### Hallazgos Críticos

| ID | Severidad | Hallazgo | Archivo | Línea |
|----|-----------|----------|---------|-------|
| SEC-001 | 🔴 ALTA | Password hardcodeado en compose | docker-compose.yml | 12-13 |
| SEC-002 | 🔴 ALTA | Connection string con credenciales | docker-compose.devcontainer.yml | 17 |
| SEC-003 | 🟡 MEDIA | WebSocket sin autenticación | web_app.py | 205-235 |
| SEC-004 | 🟡 MEDIA | CORS no configurado | web_app.py | - |
| SEC-005 | 🟢 BAJA | Logging sin sanitización | customer_sales_postgres.py | 28 |

### Recomendaciones Inmediatas

1. **Migrar secretos a Azure Key Vault**
2. **Implementar autenticación JWT en WebSocket**
3. **Configurar CORS restrictivo**
4. **Añadir rate limiting**
5. **Implementar validación de inputs**

---

## 📑 Próximos Pasos

1. ✅ Análisis técnico completo
2. ✅ Inventario de variables
3. ⏳ Crear Dockerfiles de producción
4. ⏳ Ejecutar pruebas locales
5. ⏳ Configurar despliegue Azure
6. ⏳ Documentar resultados finales
