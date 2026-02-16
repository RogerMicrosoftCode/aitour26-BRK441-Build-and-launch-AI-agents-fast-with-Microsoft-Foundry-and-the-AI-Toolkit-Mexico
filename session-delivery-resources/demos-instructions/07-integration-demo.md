# Demo de Integración - AI Tour 26 BRK441 México

## 🎯 Objetivo

Demostrar la integración completa entre el **Frontend** y el **Agente de IA**, con despliegue repetible en Azure:

| Componente | Tecnología | Descripción |
|------------|------------|-------------|
| **Frontend** | HTML/JS + WebSocket | Interfaz de chat interactiva |
| **Backend** | FastAPI + Uvicorn | Servidor web con endpoints REST y WebSocket |
| **Agente IA** | Microsoft Agent Framework | Cora, asistente de IA con herramientas MCP |
| **MCP Server** | FastMCP (stdio) | Acceso a datos de ventas y productos |
| **Base de Datos** | PostgreSQL + pgvector | Datos de retail de Zava |

## 📋 Requisitos Previos

1. **Docker Desktop** instalado y corriendo
2. **Python 3.11+** con dependencias instaladas
3. **Azure CLI** instalado y logueado (`az login`)
4. **Variables de entorno** configuradas en `.env`

## 🚀 Demo Rápida (Un Solo Comando)

### Opción 1: Script Automatizado

```powershell
# Desde la raíz del proyecto - Demo completa
.\scripts\demo-integration.ps1

# Con limpieza de procesos previos
.\scripts\demo-integration.ps1 -Clean

# Saltando inicio de base de datos (si ya está corriendo)
.\scripts\demo-integration.ps1 -SkipDatabase
```

### Opción 2: Pasos Manuales

#### Paso 1: Iniciar la Base de Datos

```powershell
# Desde la raíz del proyecto
docker-compose up -d

# Verificar que está corriendo
docker-compose ps
```

#### Paso 2: Ejecutar Prueba de Conectividad

```powershell
# Navegar al directorio de tests
cd src/python/tests

# Ejecutar demo de conectividad a BD
python demo_database_connectivity.py
```

**Lo que verás:**
- ✅ Conexión exitosa a PostgreSQL
- 📊 Estructura de tablas del schema 'retail'
- 📦 Datos de ejemplo (productos, clientes, órdenes)
- 📈 Estadísticas de la base de datos

#### Paso 3: Ejecutar Pruebas de Integración

```powershell
python test_integration.py
```

**Resultados Esperados:**
```
[Paso 1] Probando conexión a PostgreSQL... ✅
[Paso 2] Ejecutando consultas de prueba... ✅ Productos: 5
[Paso 3] Verificando estado del Web App... ✅ Saludable
[Paso 4] Verificando frontend... ✅ HTML cargado
[Paso 5] Probando búsqueda de productos... ✅ MCP funcionando
```

#### Paso 4: Iniciar la Aplicación Web

```powershell
cd src/python/web_app
python web_app.py
```

🌐 **Abrir en navegador:** http://localhost:8000

#### Paso 5: Interactuar con Cora

Ejemplos de consultas:
- "Busco un taladro para proyectos de bricolaje"
- "¿Qué productos tienen para impermeabilizar un techo?"
- "Necesito herramientas para pintar una habitación"

## 🔧 Arquitectura de Integración

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    Frontend     │────▶│   Web App       │────▶│   Agent (Cora)  │
│   (Browser)     │     │   (FastAPI)     │     │   (Framework)   │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   PostgreSQL    │◀────│   MCP Server    │◀────│   MCP Tools     │
│   (retail DB)   │     │   (FastMCP)     │     │   (stdio/http)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Flujo de Comunicación

1. **Usuario → Frontend**: Envía mensaje en la interfaz de chat
2. **Frontend → WebSocket**: Conexión persistente con el servidor
3. **FastAPI → Agent**: Pasa el mensaje al agente Cora (Microsoft Agent Framework)
4. **Agent → MCP**: Usa herramientas MCP para acceder a datos
5. **MCP → PostgreSQL**: Ejecuta queries contra la base de datos
6. **Respuesta**: Fluye de vuelta al usuario

## ☁️ Despliegue en Azure (Repetible)

### Script de Despliegue Automatizado

```powershell
# Despliegue completo (primera vez o actualización)
.\scripts\deploy-azure-repetible.ps1 -ResourcePrefix "zava" -Location "eastus2"

# Con endpoint de Azure AI Foundry
.\scripts\deploy-azure-repetible.ps1 `
    -ResourcePrefix "zava" `
    -Location "eastus2" `
    -FoundryEndpoint "https://your-foundry.services.ai.azure.com/"

# Solo construir imágenes (sin desplegar)
.\scripts\deploy-azure-repetible.ps1 -BuildOnly

# Eliminar todos los recursos
.\scripts\deploy-azure-repetible.ps1 -Destroy
```

### Recursos Desplegados en Azure

| Recurso | Propósito |
|---------|-----------|
| **Resource Group** | Contenedor de todos los recursos |
| **Container Registry** | Almacena imágenes Docker |
| **Container Apps Environment** | Orquestación de contenedores |
| **Container App (webapp)** | Aplicación web con agente |
| **PostgreSQL Flexible Server** | Base de datos con pgvector |
| **Key Vault** | Secretos y credenciales |
| **Managed Identity** | Autenticación sin contraseñas |

### Características del Despliegue Repetible

- ✅ **Idempotente**: Ejecutar múltiples veces produce el mismo resultado
- ✅ **Determinístico**: Nombres de recursos basados en suscripción
- ✅ **Seguro**: Managed Identity y Key Vault para credenciales
- ✅ **Escalable**: Container Apps con auto-scaling (1-10 réplicas)
- ✅ **Versionado**: Imágenes etiquetadas con v1 y latest

## 📊 Datos de la Demo

### Schema: `retail`

| Tabla | Descripción |
|-------|-------------|
| `products` | Catálogo de productos de bricolaje |
| `customers` | Información de clientes |
| `orders` | Órdenes de compra |
| `order_items` | Detalles de cada orden |
| `stores` | Tiendas Zava |
| `categories` | Categorías de productos |
| `inventory` | Inventario por tienda |

### Queries de Ejemplo

```sql
-- Buscar productos
SELECT name, price, description 
FROM retail.products 
WHERE LOWER(name) LIKE '%drill%';

-- Estadísticas de ventas
SELECT COUNT(*) as orders, SUM(total_amount) as revenue
FROM retail.orders;

-- Productos más vendidos
SELECT p.name, COUNT(*) as sold
FROM retail.order_items oi
JOIN retail.products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY sold DESC LIMIT 5;
```

## 🔄 Repetibilidad

Estos scripts están diseñados para ser **completamente repetibles**:

1. **`test_integration.py`**: Pruebas automatizadas con resultados JSON
2. **`demo_database_connectivity.py`**: Demo visual para presentaciones
3. Todos los tests son idempotentes y no modifican datos

### Resultados Guardados

Después de ejecutar `test_integration.py`, los resultados se guardan en:
```
src/python/tests/integration_test_results.json
```

## 🛠️ Solución de Problemas

### Error: "No se puede conectar a PostgreSQL"
```powershell
# Verificar que Docker está corriendo
docker-compose ps

# Reiniciar servicios
docker-compose down
docker-compose up -d
```

### Error: "Web App no responde"
```powershell
# Verificar que el puerto 8000 está libre
netstat -ano | findstr :8000

# Iniciar la aplicación
cd src/python/web_app
python web_app.py
```

### Error: "Faltan dependencias"
```powershell
# Instalar dependencias
pip install -r src/python/requirements.txt
pip install asyncpg httpx
```

## 📌 Notas Importantes

1. **Variables de entorno**: Asegúrate de tener un archivo `.env` con:
   ```
   POSTGRES_URL=postgresql://store_manager:StoreManager123!@localhost:15432/zava
   AZURE_AI_FOUNDRY_ENDPOINT=your_endpoint
   MODEL_DEPLOYMENT_NAME=gpt-4.1-mini
   ```

2. **Puertos utilizados**:
   - `15432`: PostgreSQL (Docker)
   - `8000`: Web App (FastAPI)
   - `8001`: MCP Server (opcional)

3. **Para producción**: Usa `docker-compose.prod.yml` con configuraciones de Azure
