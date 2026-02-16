#!/usr/bin/env python3
"""
Demo de Integración Rápida - AI Tour 26 BRK441
===============================================

Este script proporciona una demostración rápida de la integración
que funciona con o sin base de datos real.

Uso:
    python demo_integration_quick.py [--interactive]

Argumentos:
    --interactive    Pausar entre pasos (para presentaciones en vivo)

Modos:
    - Con PostgreSQL: Muestra datos reales
    - Sin PostgreSQL: Muestra simulación con datos de ejemplo
"""

import asyncio
import sys
import os
import json
import argparse
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any
import random

from dotenv import load_dotenv
load_dotenv()

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Demo de Integración AI Tour 26')
parser.add_argument('--interactive', '-i', action='store_true', 
                    help='Pausar entre pasos para presentaciones en vivo')
args, _ = parser.parse_known_args()
INTERACTIVE_MODE = args.interactive

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
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   🚀 AI Tour 26 - BRK441                                        ║
║   Demo de Integración: Frontend + Agente + Base de Datos        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
{Colors.RESET}""")


def print_section(title: str, icon: str = "📋"):
    print(f"\n{Colors.BLUE}{Colors.BOLD}{icon} {title}{Colors.RESET}")
    print(f"{Colors.DIM}{'─' * 60}{Colors.RESET}")


def print_success(msg: str):
    print(f"  {Colors.GREEN}✅ {msg}{Colors.RESET}")


def print_warning(msg: str):
    print(f"  {Colors.YELLOW}⚠️  {msg}{Colors.RESET}")


def print_info(msg: str):
    print(f"  {Colors.WHITE}ℹ️  {msg}{Colors.RESET}")


def print_step(step: int, msg: str):
    print(f"\n{Colors.MAGENTA}[Paso {step}]{Colors.RESET} {Colors.BOLD}{msg}{Colors.RESET}")


# Sample data for simulation
SAMPLE_PRODUCTS = [
    {"name": "Power Drill Pro 20V", "price": 129.99, "category": "Power Tools"},
    {"name": "Cordless Screwdriver Set", "price": 49.99, "category": "Power Tools"},
    {"name": "Professional Hammer 16oz", "price": 24.99, "category": "Hand Tools"},
    {"name": "Adjustable Wrench Set", "price": 34.99, "category": "Hand Tools"},
    {"name": "LED Work Light 1000lm", "price": 44.99, "category": "Lighting"},
    {"name": "Safety Goggles Pro", "price": 19.99, "category": "Safety"},
    {"name": "Paint Sprayer HVLP", "price": 89.99, "category": "Painting"},
    {"name": "Circular Saw 7.25in", "price": 159.99, "category": "Power Tools"},
]

SAMPLE_STATS = {
    "products": 150,
    "customers": 5000,
    "orders": 12345,
    "stores": 25,
    "categories": 12,
}


async def check_database_connection() -> Optional[Any]:
    """Intenta conectar a PostgreSQL"""
    try:
        import asyncpg
        postgres_url = os.getenv(
            "POSTGRES_URL",
            "postgresql://store_manager:StoreManager123!@localhost:15432/zava"
        )
        conn = await asyncpg.connect(postgres_url, timeout=5)
        return conn
    except:
        return None


async def demo_database_real(conn) -> None:
    """Demo con base de datos real"""
    print_section("Datos Reales de PostgreSQL", "🗄️")
    
    print_success("Conexión a PostgreSQL establecida")
    
    # Get real stats
    stats = {}
    stats['products'] = await conn.fetchval("SELECT COUNT(*) FROM retail.products;")
    stats['customers'] = await conn.fetchval("SELECT COUNT(*) FROM retail.customers;")
    stats['orders'] = await conn.fetchval("SELECT COUNT(*) FROM retail.orders;")
    
    print(f"\n  {Colors.CYAN}📊 Estadísticas:{Colors.RESET}")
    print(f"    Productos: {stats['products']:,}")
    print(f"    Clientes: {stats['customers']:,}")
    print(f"    Órdenes: {stats['orders']:,}")
    
    # Get sample products
    products = await conn.fetch("""
        SELECT name, price, category_name 
        FROM retail.products 
        ORDER BY RANDOM() 
        LIMIT 5;
    """)
    
    print(f"\n  {Colors.CYAN}📦 Productos de muestra:{Colors.RESET}")
    for p in products:
        print(f"    • {p['name'][:40]}: ${p['price']}")


def demo_database_simulated() -> None:
    """Demo con datos simulados"""
    print_section("Datos Simulados (PostgreSQL no disponible)", "🔄")
    
    print_warning("PostgreSQL no está disponible")
    print_info("Mostrando datos de simulación para la demo...")
    
    print(f"\n  {Colors.CYAN}📊 Estadísticas (simuladas):{Colors.RESET}")
    for key, value in SAMPLE_STATS.items():
        print(f"    {key.capitalize()}: {value:,}")
    
    print(f"\n  {Colors.CYAN}📦 Productos de muestra (simulados):{Colors.RESET}")
    for p in random.sample(SAMPLE_PRODUCTS, 5):
        print(f"    • {p['name']}: ${p['price']}")


async def demo_agent_flow() -> None:
    """Demostrar flujo del agente"""
    print_section("Flujo de Integración del Agente", "🤖")
    
    print(f"""
    {Colors.WHITE}El flujo de integración funciona así:{Colors.RESET}
    
    1️⃣  {Colors.CYAN}Usuario{Colors.RESET} envía mensaje al Frontend
           │
           ▼
    2️⃣  {Colors.CYAN}Web App (FastAPI){Colors.RESET} recibe la solicitud via WebSocket
           │
           ▼
    3️⃣  {Colors.CYAN}ChatAgent (Cora){Colors.RESET} procesa el mensaje
           │
           ▼
    4️⃣  {Colors.CYAN}MCP Tools{Colors.RESET} se invocan para buscar productos
           │
           ▼
    5️⃣  {Colors.CYAN}PostgreSQL{Colors.RESET} devuelve datos de retail.products
           │
           ▼
    6️⃣  {Colors.CYAN}Cora{Colors.RESET} genera respuesta personalizada
           │
           ▼
    7️⃣  {Colors.CYAN}Usuario{Colors.RESET} ve la recomendación en el chat
    """)


def demo_mcp_tools() -> None:
    """Demostrar herramientas MCP disponibles"""
    print_section("Herramientas MCP del Agente", "🔧")
    
    tools = [
        ("get_products_by_name", "Buscar productos por nombre"),
        ("get_current_utc_date", "Obtener fecha/hora actual"),
    ]
    
    print(f"\n  {Colors.WHITE}Herramientas disponibles para el agente:{Colors.RESET}\n")
    for name, desc in tools:
        print(f"  {Colors.CYAN}• {name}{Colors.RESET}")
        print(f"    {Colors.DIM}{desc}{Colors.RESET}")
    
    print(f"\n  {Colors.WHITE}Ejemplo de invocación:{Colors.RESET}")
    print(f"""
    {Colors.DIM}# El agente llama a MCP Tool
    result = await get_products_by_name(
        product_name="drill",
        max_rows=5
    )
    
    # Retorna JSON con productos
    [
      {{"name": "Power Drill Pro", "price": 129.99}},
      {{"name": "Cordless Drill", "price": 89.99}}
    ]{Colors.RESET}
    """)


def demo_web_app() -> None:
    """Demostrar la aplicación web"""
    print_section("Aplicación Web (Frontend)", "🌐")
    
    print(f"""
    {Colors.WHITE}Componentes del Frontend:{Colors.RESET}
    
    📁 {Colors.CYAN}src/python/web_app/web_app.py{Colors.RESET}
       • FastAPI application
       • WebSocket para chat en tiempo real
       • Integración con Agent Framework
    
    📁 {Colors.CYAN}src/shared/static/index.html{Colors.RESET}
       • Interfaz de chat moderna
       • Soporte para imágenes
       • Diseño responsivo
    
    {Colors.YELLOW}Endpoints:{Colors.RESET}
       GET  /          → Página principal (chat)
       GET  /health    → Estado del servicio
       WS   /ws        → WebSocket para chat
       POST /upload    → Subir imágenes
    
    {Colors.GREEN}URL: http://localhost:8000{Colors.RESET}
    """)


def pause_if_interactive():
    """Pausar solo si estamos en modo interactivo"""
    if INTERACTIVE_MODE:
        input(f"\n{Colors.DIM}Presiona Enter para continuar...{Colors.RESET}")
    else:
        print()  # Just add a blank line in non-interactive mode


async def run_full_demo() -> None:
    """Ejecutar demo completo"""
    clear_screen()
    print_banner()
    
    print_info(f"Fecha/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    if not INTERACTIVE_MODE:
        print_info("Modo automático (usa --interactive para pausas)")
    
    # Step 1: Architecture explanation
    print_step(1, "Arquitectura de la Aplicación")
    await demo_agent_flow()
    
    pause_if_interactive()
    
    # Step 2: Database connectivity
    print_step(2, "Conectividad a Base de Datos")
    conn = await check_database_connection()
    if conn:
        await demo_database_real(conn)
        await conn.close()
    else:
        demo_database_simulated()
    
    pause_if_interactive()
    
    # Step 3: MCP Tools
    print_step(3, "Herramientas MCP")
    demo_mcp_tools()
    
    pause_if_interactive()
    
    # Step 4: Web App
    print_step(4, "Aplicación Web")
    demo_web_app()
    
    # Summary
    print_section("Resumen de la Demo", "✨")
    
    print(f"""
    {Colors.GREEN}✅ Arquitectura de integración explicada{Colors.RESET}
    {Colors.GREEN}✅ Conectividad a base de datos demostrada{Colors.RESET}
    {Colors.GREEN}✅ Herramientas MCP del agente mostradas{Colors.RESET}
    {Colors.GREEN}✅ Componentes del frontend presentados{Colors.RESET}
    
    {Colors.CYAN}Para ejecutar la aplicación completa:{Colors.RESET}
    
    1. Inicia Docker:     docker-compose up -d
    2. Inicia Web App:    python src/python/web_app/web_app.py
    3. Abre navegador:    http://localhost:8000
    """)


async def main():
    """Main entry point"""
    await run_full_demo()


if __name__ == "__main__":
    asyncio.run(main())
