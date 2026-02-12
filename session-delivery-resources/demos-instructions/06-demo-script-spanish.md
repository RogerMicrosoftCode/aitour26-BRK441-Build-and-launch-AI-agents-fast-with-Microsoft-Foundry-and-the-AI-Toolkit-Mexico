# Guion de Demostración: Construyendo y Desplegando a Cora, el Agente de IA de Zava

## La Historia de Serena y el Agente Cora

Esta es la historia de cómo Serena, una desarrolladora de Zava (una tienda de mejoras para el hogar), construye, evalúa y despliega a **Cora**, un agente de IA que ayudará a clientes como Bruno a encontrar los productos perfectos para sus proyectos.

---

## Parte 1: Conectando el Servidor MCP y Agregando Herramientas

### Escena 1: De vuelta en el Agent Builder

Aquí en el Agent Builder, puedo conectarme al servidor MCP personalizado de Zava y agregar las herramientas que serán relevantes para Cora. El servidor básico de ventas al cliente permite que Cora:

- **Busque productos por nombre** con coincidencia difusa (fuzzy matching)
- **Obtenga disponibilidad de productos específicos por tienda** mediante seguridad a nivel de fila (Row Level Security)
- **Consulte niveles de inventario en tiempo real** e información de stock

Ya tengo el servidor ejecutándose aquí en segundo plano dentro de VS Code, y puedo acceder a él desde el Agent Builder.

### Escena 2: Agregando las Herramientas MCP

Para conectar este servidor y proporcionar sus herramientas a Cora:

1. **Desplazo hacia abajo** hasta la sección de herramientas
2. **Selecciono agregar herramientas** mediante la opción de servidor MCP
3. **Puedo usar herramientas** que ya están agregadas en VS Code

> 💡 **Nota:** Si deseas usar un servidor diferente, también puedes explorar servidores disponibles, agregar servidores manualmente, o incluso crear tus propios servidores con el AI Toolkit.

Como ya tengo uno ejecutándose, selecciono uno de los que están corriendo en VS Code. En este caso, solo necesito `get_products_by_name`, así que selecciono esa herramienta y hago clic en "OK".

Ahora que la herramienta ha sido agregada, vamos a usar el mismo prompt de antes con Cora para ver qué producto puede recomendar.

### Escena 3: Probando la Recomendación con una Imagen

Ahora que Cora tiene acceso a la base de datos de productos:

1. **Inicio un nuevo chat**
2. **Envío el prompt** junto con la imagen de la sala de Bruno
3. **Observo** lo que hace el agente en respuesta

**Resultado:** Tenemos otra recomendación para pintura Eggshell. Cora pregunta si me gustaría que el agente recomiende un producto de acabado de pintura específico.

Respondo: *"Sí, recomiéndame una pintura eggshell de Zava"*

Y veamos si obtenemos una llamada a herramienta. Si hay una llamada a herramienta, se mostrará directamente en la interfaz.

**¡Excelente!** Puedo ver que ocurrió una llamada a herramienta para `get_products_by_name`. Esa es la herramienta que agregamos. Y tenemos la recomendación real del producto: **Interior Eggshell Paint de Zava**. También tenemos el precio y está disponible en stock.

---

## Parte 2: Evaluando al Agente Cora

### Escena 4: La Pregunta de Confianza

Ahora que Cora está funcionando y conectada al catálogo de productos de Zava usando MCP, Serena tiene un prototipo funcional. Pero antes de lanzarlo, necesita responder:

- ¿Cora realmente está haciendo lo que debe hacer?
- ¿Las respuestas son claras?
- ¿Son confiables?
- ¿Son realmente útiles para los clientes de Zava?

En esencia, **Serena quiere saber si puede confiar en que el agente Cora interactúe con clientes reales como Bruno**.

### Escena 5: La Pestaña de Evaluación

De vuelta en el Agent Builder, cambiamos a la **pestaña de evaluación**. Esta pestaña nos permite ejecutar evaluaciones contra el agente Cora.

#### Generación de Datos de Prueba

Lo primero que quiero destacar es nuestra función de **generar datos** (el ícono de estrella). En caso de que quieras evaluar tu agente pero aún no tengas datos, podemos generarlos por ti.

Al seleccionarlo:
1. Decides cuántas filas de datos deseas generar
2. Proporcionamos lógica de generación basada en las instrucciones de tu agente
3. Puedes modificar esto para asegurar el conjunto de datos adecuado

### Escena 6: Ingresando Datos de Evaluación

Ya tengo los datos que Serena usó cuando evaluaba al agente Cora, así que los ingresaré manualmente:

| # | Pregunta de Prueba |
|---|-------------------|
| 1 | *"¿Qué tipo de composta orgánica tiene Zava?"* |
| 2 | *"¿Zava tiene una cubeta de pintura? Si es así, ¿cuánto cuesta?"* |
| 3 | *"¿De qué color es la brillantina (glitter) que vende Zava?"* |
| 4 | *"¿Cuántas cintas métricas hay actualmente en stock?"* |

> 💡 **Nota:** Tenemos variedad aquí con respecto al tipo de entrada que podríamos esperar recibir de los clientes de Zava.

### Escena 7: Ejecutando las Respuestas del Agente

Ahora necesitamos ejecutar el agente para obtener sus respuestas y luego hacer nuestras evaluaciones.

Selecciono **"Run Response"** para ejecutar todas a la vez.

**Lo que esperamos ver:** Algunas llamadas a herramientas porque el agente Cora tiene acceso a las herramientas del servidor MCP de Zava con los productos.

**Resultados:**
- ✅ Primera fila: llamada a herramienta iniciada
- ✅ Segunda fila: otra llamada a herramienta
- ✅ Tercera y cuarta fila: completadas

### Escena 8: Evaluación Manual (Humana)

Revisemos los resultados:

| # | Resultado | Evaluación | Razón |
|---|-----------|------------|-------|
| 1 | Composta orgánica 40 libras en categoría jardín y exteriores | 👍 **Bien** | Información específica del producto correcta |
| 2 | Paint Bucket Grid (bandeja de pintura) | 👎 **Mal** | No es una cubeta de pintura, es una bandeja |
| 3 | Zava no vende brillantina, alternativas disponibles | 👍 **Bien** | Pregunta capciosa manejada correctamente |
| 4 | 7,162 unidades en stock | 👍 **Bien** | Respuesta precisa de inventario |

### Escena 9: Evaluación Asistida por IA

También podemos hacer que la IA evalúe la salida del agente.

**¿No sabes qué evaluadores usar?** Podemos usar GitHub Copilot para recomendar evaluadores:

*"¿Qué evaluadores recomiendas que use para hacer evaluaciones de mi agente?"*

GitHub Copilot invocará la herramienta **evaluation_planner** del AI Toolkit.

**Evaluadores Recomendados:**
1. **Relevance (Relevancia)** - ¿La respuesta es relevante a la pregunta?
2. **Coherence (Coherencia)** - ¿La respuesta es coherente y lógica?

> 💡 **Nota:** Nuestras evaluaciones usan el **Azure AI Evaluation SDK** y sus evaluadores integrados. Alternativamente, también puedes crear evaluadores personalizados.

### Escena 10: Configurando Evaluadores de IA

1. Agrego evaluadores: **Relevance** y **Coherence**
2. Selecciono el modelo de lenguaje: **GPT-4.1 mini**
3. Ejecuto la evaluación para la primera fila

**Resultados de Evaluación (Escala 1-5, donde 5 es el más alto):**
- **Relevancia:** 4/5
- **Coherencia:** 4/5

Además recibimos:
- Razón de relevancia
- Razón de coherencia
- Respuesta del modelo
- Respuesta de herramientas
- Respuesta final al usuario

---

## Parte 3: Exportando el Código del Agente

### Escena 11: Del Prototipo a Producción

Ahora enfoquémonos en llevar al agente a un producto real. Un colega de Serena creó la interfaz de usuario para la app de Cora y le pasó los archivos del proyecto. Por lo tanto:

- ✅ El front-end está completo
- ❌ Falta el cerebro: la lógica del agente, la llamada al servidor MCP, y las respuestas del modelo

### Escena 12: Exportando el Código

Dentro del AI Toolkit, Serena puede exportar el código del agente mediante su SDK preferido.

Al desplazarnos hacia abajo, encontramos la opción **"View Code"** con tres opciones disponibles:

| SDK | Descripción |
|-----|-------------|
| **Azure AI Inference SDK** | Para inferencia directa de Azure AI |
| **Semantic Kernel SDK** | Para orquestación con Semantic Kernel |
| **Microsoft Agent Framework** | Para el nuevo framework de agentes |

**Serena elige:** Microsoft Agent Framework con Python

Ahora tenemos el archivo de código para el agente creado dentro del Agent Builder.

### Escena 13: Integrando con GitHub Copilot

Después de obtener el código del agente, Serena aún necesita fusionar su código de agente con el código de la aplicación existente.

En lugar de pasar tiempo revisando el proyecto de su colega, puede usar **GitHub Copilot** para:
- Fusionar la lógica del agente con la lógica del front-end
- Tener una aplicación completamente funcional

---

## Parte 4: El Despliegue en Azure

### Escena 14: La Arquitectura de Despliegue

Para llevar a Cora a producción, Serena despliega la aplicación en Azure con la siguiente arquitectura:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                          │
│                      (AITourMexFeb)                              │
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
```

### Escena 15: Pasos del Despliegue

El proceso de despliegue sigue estos pasos:

#### Paso 1: Crear Recursos Base
```powershell
# Grupo de Recursos
az group create --name AITourMexFeb --location eastus2

# Identidad Administrada
az identity create --name id-zava-feb --resource-group AITourMexFeb

# Container Registry
az acr create --name zavaacrmexfeb --resource-group AITourMexFeb --sku Basic
```

#### Paso 2: Configurar Base de Datos
```powershell
# PostgreSQL Flexible Server con pgvector
az postgres flexible-server create --name psql-zava-feb ...

# Restaurar base de datos con productos y clientes
pg_restore --host psql-zava-feb.postgres.database.azure.com ...
```

#### Paso 3: Configurar Azure AI Services
```powershell
# Crear Azure AI Services
az cognitiveservices account create --name foundry-zava-feb ...

# Desplegar modelo gpt-4o-mini
az cognitiveservices account deployment create --deployment-name gpt-4o-mini ...
```

#### Paso 4: Construir y Desplegar la Aplicación
```powershell
# Construir imagen Docker
docker build -t zavaacrmexfeb.azurecr.io/zava-webapp:v1 .

# Subir a Container Registry
docker push zavaacrmexfeb.azurecr.io/zava-webapp:v1

# Crear Container App
az containerapp create --name ca-webapp-feb ...
```

---

## Parte 5: La Demostración Final

### Escena 16: Siendo Bruno

Tengo la aplicación lista aquí. Pongámonos en los zapatos de Bruno por un segundo.

**Bruno necesita:** Una recomendación para pintar su sala de estar.

### Escena 17: El Prompt de Bruno

Ingreso el prompt:

> *"Aquí hay una foto de mi sala de estar. No estoy seguro si debería elegir eggshell o semi-gloss. ¿Puedes decirme cuál funcionaría mejor basándote en la iluminación y el diseño?"*

Y adjunto la imagen de la sala de Bruno.

### Escena 18: La Respuesta de Cora

Cora está trabajando en ello...

**Respuesta de Cora:**

Cora ha tomado en cuenta la imagen. Basándose en la luz natural suave con una estética limpia y acogedora:

| Opción | Consideraciones |
|--------|-----------------|
| **Eggshell** | Mejor para ocultar imperfecciones, acabado suave |
| **Semi-gloss** | Más duradero, más fácil de limpiar |

**Recomendación final:** Pintura Eggshell

### Escena 19: Pidiendo un Producto Específico

Pregunto: *"Recomiéndame una pintura eggshell de Zava"*

Cora trabaja de nuevo... En algún lugar detrás de escenas, Cora está haciendo una **llamada a herramienta**.

**Resultado:** Cora encuentra la **Interior Eggshell Paint de Zava** y pregunta si me gustaría más detalles sobre el producto o asistencia con la compra.

### Escena 20: El Precio Final

Pregunto: *"¿Cuánto cuesta el producto?"*

**Respuesta de Cora:** *"La pintura eggshell de Zava tiene un precio de $65.67"*

---

## Conclusión: De Prototipo a Producción

### Lo que acabamos de ver:

✅ El agente Cora ha realizado **dos llamadas a herramientas exitosamente** y muy rápidamente

✅ Hemos pasado de **prototipar el agente Cora** a agregar esa lógica en una aplicación existente

✅ Zava puede ahora **colocar su agente Cora en producción** para sus clientes

---

## Recursos Desplegados en Azure

| Recurso | Nombre | URL/Endpoint |
|---------|--------|--------------|
| Container App | ca-webapp-feb | https://ca-webapp-feb.reddesert-7e2def45.eastus2.azurecontainerapps.io |
| AI Services | foundry-zava-feb | https://foundry-zava-feb.services.ai.azure.com/ |
| PostgreSQL | psql-zava-feb | psql-zava-feb.postgres.database.azure.com |
| Container Registry | zavaacrmexfeb | zavaacrmexfeb.azurecr.io |
| Managed Identity | id-zava-feb | Client ID: 3f1946a0-e9b1-42d9-bb59-b0edda0895e2 |

---

## Arquitectura Técnica Final

```
Usuario (Bruno)
      │
      ▼
┌─────────────────┐
│   Web App UI    │  ◄── Frontend HTML/CSS/JS
│  (Container App)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Agent Logic    │  ◄── Microsoft Agent Framework (Python)
│  (Cora Agent)   │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────────┐
│ Azure │ │    MCP    │
│  AI   │ │  Server   │
│(GPT-4)│ │(Productos)│
└───────┘ └─────┬─────┘
                │
                ▼
         ┌───────────┐
         │PostgreSQL │
         │ (pgvector)│
         └───────────┘
```

---

*Guion adaptado para AI Tour México - Febrero 2026*
*Demostración: Construye y lanza agentes de IA rápidamente con Microsoft Foundry y el AI Toolkit*
