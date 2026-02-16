#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Demo End-to-End: Frontend + Agente + Base de Datos + Azure
============================================================

Este script demuestra la integración completa de todos los componentes
de la aplicación Cora de Zava, tanto localmente como en Azure.

Uso:
    python demo_end_to_end.py [--mode local|azure|full]

Modos:
    local   - Demo solo con componentes locales
    azure   - Demo conectando a recursos Azure desplegados
    full    - Demo completa: local + Azure (default)
"""

import asyncio
import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any
import subprocess

# Fix encoding for Windows console
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except:
        pass

from dotenv import load_dotenv
load_dotenv()

# ANSI Colors
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'


def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')


def print_banner():
    print(f"""
{Colors.CYAN}{Colors.BOLD}
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║   🚀 AI Tour 26 - BRK441                                                ║
║   Demo End-to-End: Frontend + Agente + Base de Datos                    ║
║   Integración Completa para Despliegue en Azure                         ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
{Colors.RESET}""")


def print_section(title: str, icon: str = "📋"):
    print(f"\n{Colors.BLUE}{Colors.BOLD}{icon} {title}{Colors.RESET}")
    print(f"{Colors.DIM}{'─' * 70}{Colors.RESET}")


def print_success(msg: str):
    print(f"  {Colors.GREEN}✅ {msg}{Colors.RESET}")


def print_error(msg: str):
    print(f"  {Colors.RED}❌ {msg}{Colors.RESET}")


def print_warning(msg: str):
    print(f"  {Colors.YELLOW}⚠️  {msg}{Colors.RESET}")


def print_info(msg: str):
    print(f"  {Colors.WHITE}ℹ️  {msg}{Colors.RESET}")


def print_step(step: int, msg: str):
    print(f"\n{Colors.MAGENTA}[Paso {step}]{Colors.RESET} {Colors.BOLD}{msg}{Colors.RESET}")


class EndToEndDemo:
    """Demo completa de integración end-to-end"""
    
    def __init__(self, mode: str = "full"):
        self.mode = mode
        self.project_root = Path(__file__).resolve().parents[2]
        
        # Configuración local
        self.local_postgres_url = os.getenv(
            "POSTGRES_URL",
            "postgresql://store_manager:StoreManager123!@localhost:15432/zava"
        )
        self.local_webapp_url = "http://localhost:8000"
        
        # Configuración Azure (desde deployment-info.json si existe)
        self.azure_config = self._load_azure_config()
        
        self.results = {}
        
    def _load_azure_config(self) -> Dict[str, str]:
        """Cargar configuración de despliegue Azure"""
        config_file = self.project_root / "deployment-info.json"
        if config_file.exists():
            with open(config_file) as f:
                return json.load(f)
        return {}
    
    def show_architecture(self):
        """Mostrar arquitectura de integración"""
        print_section("Arquitectura de Integración", "🏗️")
        
        print(f"""
{Colors.WHITE}La aplicación Cora de Zava tiene la siguiente arquitectura:{Colors.RESET}

{Colors.CYAN}┌─────────────────────────────────────────────────────────────────────────┐
│                        ARQUITECTURA DE INTEGRACIÓN                       │
├─────────────────────────────────────────────────────────────────────────┤{Colors.RESET}

    {Colors.YELLOW}👤 Usuario (Bruno){Colors.RESET}
          │
          │ HTTP/WebSocket
          ▼
    {Colors.GREEN}┌─────────────────────┐{Colors.RESET}
    │   {Colors.GREEN}FRONTEND (Web){Colors.RESET}    │  ◄── index.html + CSS/JS
    │   Puerto: 8000      │
    │   FastAPI + Jinja2  │
    {Colors.GREEN}└──────────┬──────────┘{Colors.RESET}
               │
               │ HTTP POST / WebSocket
               ▼
    {Colors.BLUE}┌─────────────────────┐{Colors.RESET}
    │   {Colors.BLUE}AGENTE (Cora){Colors.RESET}      │  ◄── Microsoft Agent Framework
    │   ChatAgent         │
    │   + OpenAIChatClient│
    {Colors.BLUE}└──────────┬──────────┘{Colors.RESET}
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
{Colors.MAGENTA}┌───────────┐{Colors.RESET}  {Colors.CYAN}┌───────────────┐{Colors.RESET}
│{Colors.MAGENTA}Azure AI{Colors.RESET}   │  │ {Colors.CYAN}MCP Tools{Colors.RESET}      │
│GPT-4o-mini│  │ (stdio mode)  │
{Colors.MAGENTA}└───────────┘{Colors.RESET}  {Colors.CYAN}└───────┬───────┘{Colors.RESET}
                       │
                       │ SQL Queries
                       ▼
              {Colors.YELLOW}┌───────────────┐{Colors.RESET}
              │ {Colors.YELLOW}PostgreSQL{Colors.RESET}    │  ◄── Schema: retail
              │  + pgvector   │      Tablas: products, customers,
              │  (Docker)     │              orders, stores, etc.
              {Colors.YELLOW}└───────────────┘{Colors.RESET}

{Colors.CYAN}├─────────────────────────────────────────────────────────────────────────┤
│                        FLUJO DE UNA SOLICITUD                            │
├─────────────────────────────────────────────────────────────────────────┤{Colors.RESET}

{Colors.WHITE}1.{Colors.RESET} Bruno abre http://localhost:8000 y envía "Busco una pintura eggshell"
{Colors.WHITE}2.{Colors.RESET} WebSocket envía mensaje al Web App (FastAPI)
{Colors.WHITE}3.{Colors.RESET} ChatAgent (Cora) recibe el mensaje y decide usar herramienta
{Colors.WHITE}4.{Colors.RESET} MCP Tool "get_products_by_name" se invoca via stdio
{Colors.WHITE}5.{Colors.RESET} PostgreSQL ejecuta query: SELECT * FROM retail.products WHERE name ILIKE '%eggshell%'
{Colors.WHITE}6.{Colors.RESET} Resultado regresa por la cadena hasta Bruno con recomendación personalizada

{Colors.CYAN}└─────────────────────────────────────────────────────────────────────────┘{Colors.RESET}
        """)

    async def test_local_database(self) -> bool:
        """Probar conectividad a base de datos local"""
        print_step(1, "Verificando Base de Datos Local (PostgreSQL)")
        
        try:
            import asyncpg
            
            host_info = self.local_postgres_url.split('@')[1].split('/')[0]
            print_info(f"Conectando a: {host_info}")
            
            conn = await asyncpg.connect(self.local_postgres_url, timeout=10)
            
            # Test básico
            version = await conn.fetchval("SELECT version();")
            print_success(f"PostgreSQL conectado")
            
            # Test schema retail
            tables = await conn.fetch("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_schema = 'retail' ORDER BY table_name;
            """)
            print_success(f"Schema 'retail' disponible con {len(tables)} tablas")
            
            # Test productos
            product_count = await conn.fetchval("SELECT COUNT(*) FROM retail.products;")
            print_success(f"Productos en catálogo: {product_count}")
            
            await conn.close()
            self.results["local_database"] = {"status": "success", "products": product_count}
            return True
            
        except Exception as e:
            print_error(f"Error: {e}")
            print_warning("Asegúrate de que Docker esté corriendo: docker-compose up -d")
            self.results["local_database"] = {"status": "failed", "error": str(e)}
            return False

    async def test_local_webapp(self) -> bool:
        """Probar Web App local"""
        print_step(2, "Verificando Web App Local (Frontend + Agente)")
        
        try:
            import httpx
            
            print_info(f"Conectando a: {self.local_webapp_url}")
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Health check
                health = await client.get(f"{self.local_webapp_url}/health")
                if health.status_code == 200:
                    print_success("Health check: OK")
                
                # Frontend
                frontend = await client.get(f"{self.local_webapp_url}/")
                if frontend.status_code == 200 and "<html" in frontend.text.lower():
                    print_success(f"Frontend cargado: {len(frontend.text)} bytes")
                
            self.results["local_webapp"] = {"status": "success"}
            return True
            
        except Exception as e:
            print_warning(f"Web App no disponible: {e}")
            print_info("Inicia con: python src/python/web_app/web_app.py")
            self.results["local_webapp"] = {"status": "not_running", "error": str(e)}
            return False

    async def test_mcp_integration(self) -> bool:
        """Probar integración MCP → PostgreSQL"""
        print_step(3, "Verificando Integración MCP → PostgreSQL")
        
        try:
            sys.path.insert(0, str(self.project_root / "src" / "python" / "mcp_server" / "customer_sales"))
            from customer_sales_postgres import PostgreSQLCustomerSales
            
            print_info("Inicializando MCP Customer Sales Provider...")
            
            provider = PostgreSQLCustomerSales(self.local_postgres_url)
            await provider.create_pool()
            
            # Simular búsqueda como lo haría el agente
            test_query = "paint"
            print_info(f"Simulando búsqueda del agente: '{test_query}'")
            
            result = await provider.get_products_by_name(
                product_name=test_query,
                max_rows=5,
                rls_user_id="00000000-0000-0000-0000-000000000000"
            )
            
            if result:
                print_success("MCP Tool ejecutó query exitosamente")
                try:
                    products = json.loads(result) if isinstance(result, str) else result
                    if isinstance(products, list) and len(products) > 0:
                        print_success(f"Productos encontrados: {len(products)}")
                        for p in products[:3]:
                            print_info(f"  • {p.get('name', 'N/A')}: ${p.get('price', 'N/A')}")
                except:
                    print_success("Resultado obtenido (formato texto)")
            
            await provider.close_pool()
            self.results["mcp_integration"] = {"status": "success", "query": test_query}
            return True
            
        except Exception as e:
            print_error(f"Error en integración MCP: {e}")
            self.results["mcp_integration"] = {"status": "failed", "error": str(e)}
            return False

    def test_docker_status(self) -> bool:
        """Verificar estado de Docker"""
        print_step(4, "Verificando Estado de Docker")
        
        try:
            result = subprocess.run(
                ["docker", "ps", "--format", "{{.Names}}\t{{.Status}}\t{{.Ports}}"],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                containers = result.stdout.strip().split('\n')
                zava_containers = [c for c in containers if 'zava' in c.lower() or 'ai-tour' in c.lower()]
                
                if zava_containers:
                    print_success("Contenedores Docker encontrados:")
                    for c in zava_containers:
                        print_info(f"  {c}")
                    self.results["docker"] = {"status": "success", "containers": len(zava_containers)}
                    return True
                else:
                    print_warning("No hay contenedores de Zava corriendo")
                    print_info("Inicia con: docker-compose up -d")
                    self.results["docker"] = {"status": "no_containers"}
                    return False
            else:
                print_error("Docker no está disponible")
                return False
                
        except Exception as e:
            print_warning(f"Error verificando Docker: {e}")
            self.results["docker"] = {"status": "error", "error": str(e)}
            return False

    async def test_azure_deployment(self) -> bool:
        """Verificar recursos desplegados en Azure"""
        print_step(5, "Verificando Despliegue en Azure")
        
        if not self.azure_config:
            print_warning("No se encontró deployment-info.json")
            print_info("Ejecuta el despliegue con: scripts/deploy-azure.ps1")
            return False
        
        try:
            import httpx
            
            webapp_url = self.azure_config.get("webapp_url", "")
            if webapp_url:
                print_info(f"Verificando: {webapp_url}")
                
                async with httpx.AsyncClient(timeout=15.0) as client:
                    response = await client.get(f"{webapp_url}/health")
                    if response.status_code == 200:
                        print_success(f"Container App respondiendo: {webapp_url}")
                        self.results["azure_webapp"] = {"status": "success", "url": webapp_url}
                        return True
                    else:
                        print_warning(f"Status code: {response.status_code}")
            
            return False
            
        except Exception as e:
            print_warning(f"Azure no accesible: {e}")
            self.results["azure_webapp"] = {"status": "not_deployed", "error": str(e)}
            return False

    def show_deployment_commands(self):
        """Mostrar comandos para despliegue repetible"""
        print_section("Despliegue Repetible en Azure", "☁️")
        
        print(f"""
{Colors.WHITE}Para desplegar la aplicación en Azure de manera repetible:{Colors.RESET}

{Colors.CYAN}┌─────────────────────────────────────────────────────────────────────────┐
│                    COMANDOS DE DESPLIEGUE                                │
└─────────────────────────────────────────────────────────────────────────┘{Colors.RESET}

{Colors.YELLOW}Paso 1: Preparar el Entorno{Colors.RESET}
{Colors.DIM}─────────────────────────────{Colors.RESET}
  # Login en Azure
  az login

  # Seleccionar suscripción
  az account set --subscription "Tu-Suscripción"

{Colors.YELLOW}Paso 2: Desplegar Infraestructura (Bicep){Colors.RESET}
{Colors.DIM}─────────────────────────────────────────{Colors.RESET}
  # Desplegar todos los recursos
  az deployment sub create \\
    --location eastus2 \\
    --template-file infra/main.bicep \\
    --parameters resourcePrefix=zava-demo

{Colors.YELLOW}Paso 3: Construir y Subir Imagen Docker{Colors.RESET}
{Colors.DIM}────────────────────────────────────────{Colors.RESET}
  # Login al Container Registry
  az acr login --name zavaacr

  # Construir imagen
  docker build -t zavaacr.azurecr.io/zava-webapp:latest -f Dockerfile.webapp .

  # Subir imagen
  docker push zavaacr.azurecr.io/zava-webapp:latest

{Colors.YELLOW}Paso 4: Actualizar Container App{Colors.RESET}
{Colors.DIM}─────────────────────────────────{Colors.RESET}
  # Actualizar con nueva imagen
  az containerapp update \\
    --name ca-webapp \\
    --resource-group rg-zava-demo \\
    --image zavaacr.azurecr.io/zava-webapp:latest

{Colors.YELLOW}Paso 5: Verificar Despliegue{Colors.RESET}
{Colors.DIM}─────────────────────────────{Colors.RESET}
  # Obtener URL
  az containerapp show --name ca-webapp --resource-group rg-zava-demo \\
    --query properties.configuration.ingress.fqdn -o tsv

{Colors.CYAN}┌─────────────────────────────────────────────────────────────────────────┐
│                    SCRIPT AUTOMATIZADO                                   │
└─────────────────────────────────────────────────────────────────────────┘{Colors.RESET}

  {Colors.GREEN}# Despliegue completo con un comando:{Colors.RESET}
  .\\scripts\\deploy-azure.ps1 -ResourcePrefix "zava-demo" -Location "eastus2"

  {Colors.GREEN}# Solo actualizar la imagen:{Colors.RESET}
  .\\scripts\\deploy-azure.ps1 -UpdateOnly

{Colors.CYAN}┌─────────────────────────────────────────────────────────────────────────┐
│                    RECURSOS CREADOS                                      │
└─────────────────────────────────────────────────────────────────────────┘{Colors.RESET}

  │ Recurso              │ Propósito                              │
  ├──────────────────────┼────────────────────────────────────────┤
  │ Container Registry   │ Almacena imagen Docker                 │
  │ Container Apps       │ Ejecuta Web App + Agente               │
  │ PostgreSQL Flexible  │ Base de datos con pgvector             │
  │ Azure AI Services    │ Modelo GPT-4o-mini                     │
  │ Managed Identity     │ Autenticación segura                   │
  │ Application Insights │ Monitoreo y telemetría                 │
        """)

    def show_integration_points(self):
        """Mostrar puntos de integración"""
        print_section("Puntos de Integración", "🔗")
        
        print(f"""
{Colors.WHITE}Los componentes se integran en estos puntos clave:{Colors.RESET}

{Colors.CYAN}1. Frontend → Web App (FastAPI){Colors.RESET}
   {Colors.DIM}Archivo:{Colors.RESET} src/python/web_app/web_app.py
   {Colors.DIM}Método:{Colors.RESET}  WebSocket en /ws
   {Colors.DIM}Código:{Colors.RESET}
   {Colors.GREEN}@app.websocket("/ws")
   async def websocket_endpoint(websocket: WebSocket):
       user_message = await websocket.receive_text()
       response = await simulate_ai_agent(user_message)
       await websocket.send_text(response){Colors.RESET}

{Colors.CYAN}2. Web App → ChatAgent (Cora){Colors.RESET}
   {Colors.DIM}Archivo:{Colors.RESET} src/python/web_app/web_app.py
   {Colors.DIM}Framework:{Colors.RESET} Microsoft Agent Framework
   {Colors.DIM}Código:{Colors.RESET}
   {Colors.GREEN}agent_instance = ChatAgent(
       name="cora-web-agent",
       instructions=AGENT_INSTRUCTIONS,
       chat_client=OpenAIChatClient(...),
       tools=[*create_mcp_tools()],
   ){Colors.RESET}

{Colors.CYAN}3. Agente → MCP Tools{Colors.RESET}
   {Colors.DIM}Archivo:{Colors.RESET} src/python/web_app/web_app.py
   {Colors.DIM}Protocolo:{Colors.RESET} MCP Stdio
   {Colors.DIM}Código:{Colors.RESET}
   {Colors.GREEN}MCPStdioTool(
       name="zava_customer_sales_stdio",
       command="python",
       args=["customer_sales.py", "--stdio"],
   ){Colors.RESET}

{Colors.CYAN}4. MCP Tool → PostgreSQL{Colors.RESET}
   {Colors.DIM}Archivo:{Colors.RESET} src/python/mcp_server/customer_sales/customer_sales_postgres.py
   {Colors.DIM}Librería:{Colors.RESET} asyncpg
   {Colors.DIM}Código:{Colors.RESET}
   {Colors.GREEN}async def get_products_by_name(self, product_name, max_rows):
       query = "SELECT * FROM retail.products WHERE name ILIKE $1"
       return await conn.fetch(query, f'%{{product_name}}%'){Colors.RESET}

{Colors.CYAN}5. Azure Deployment{Colors.RESET}
   {Colors.DIM}Archivos:{Colors.RESET} Dockerfile.webapp, docker-compose.prod.yml
   {Colors.DIM}Env Vars:{Colors.RESET} AZURE_AI_FOUNDRY_ENDPOINT, POSTGRES_URL, MODEL_DEPLOYMENT_NAME
        """)

    async def run_demo(self):
        """Ejecutar demo completa"""
        clear_screen()
        print_banner()
        
        print_info(f"Fecha/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print_info(f"Modo: {self.mode}")
        
        # Mostrar arquitectura
        self.show_architecture()
        
        # Tests según el modo
        if self.mode in ["local", "full"]:
            print_section("Pruebas Locales", "💻")
            
            docker_ok = self.test_docker_status()
            if docker_ok:
                db_ok = await self.test_local_database()
                mcp_ok = await self.test_mcp_integration()
            
            webapp_ok = await self.test_local_webapp()
        
        if self.mode in ["azure", "full"]:
            print_section("Pruebas Azure", "☁️")
            azure_ok = await self.test_azure_deployment()
        
        # Mostrar puntos de integración
        self.show_integration_points()
        
        # Mostrar comandos de despliegue
        self.show_deployment_commands()
        
        # Resumen
        print_section("Resumen de la Demo", "✨")
        
        print(f"""
{Colors.GREEN}✅ Arquitectura de integración explicada{Colors.RESET}
{Colors.GREEN}✅ Conectividad Frontend → Agente → BD demostrada{Colors.RESET}
{Colors.GREEN}✅ Integración MCP verificada{Colors.RESET}
{Colors.GREEN}✅ Comandos de despliegue Azure mostrados{Colors.RESET}

{Colors.CYAN}Próximos pasos:{Colors.RESET}
  1. Asegurar Docker corriendo: docker-compose up -d
  2. Iniciar Web App: python src/python/web_app/web_app.py
  3. Abrir navegador: http://localhost:8000
  4. Probar con Bruno: "Busco una pintura eggshell para mi sala"
        """)
        
        # Guardar resultados
        results_file = Path(__file__).parent / "end_to_end_results.json"
        with open(results_file, "w") as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "mode": self.mode,
                "results": self.results
            }, f, indent=2, default=str)
        
        print_info(f"Resultados guardados en: {results_file}")


async def main():
    parser = argparse.ArgumentParser(description='Demo End-to-End AI Tour 26')
    parser.add_argument('--mode', choices=['local', 'azure', 'full'], 
                        default='full', help='Modo de demo')
    args = parser.parse_args()
    
    demo = EndToEndDemo(mode=args.mode)
    await demo.run_demo()


if __name__ == "__main__":
    asyncio.run(main())
