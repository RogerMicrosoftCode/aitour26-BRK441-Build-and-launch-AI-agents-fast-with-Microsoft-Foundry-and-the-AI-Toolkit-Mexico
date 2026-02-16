#!/usr/bin/env python3
"""
Demo de Conectividad a Base de Datos - AI Tour 26 BRK441
=========================================================

Este script demuestra la conectividad entre los componentes de la aplicación
y la base de datos PostgreSQL.

Uso:
    python demo_database_connectivity.py

Para la demo:
    1. Asegúrate de que Docker esté corriendo con PostgreSQL
    2. Ejecuta este script para mostrar la conectividad
"""

import asyncio
import os
import sys
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dotenv import load_dotenv
load_dotenv()

# ANSI Colors for beautiful terminal output
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
    BG_GREEN = '\033[42m'
    BG_BLUE = '\033[44m'


def clear_screen():
    """Clear terminal screen"""
    os.system('cls' if os.name == 'nt' else 'clear')


def print_banner():
    """Print demo banner"""
    banner = f"""
{Colors.CYAN}{Colors.BOLD}
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   🚀 AI Tour 26 - BRK441 Demo de Conectividad                   ║
║   📦 Zava Retail - Sistema de Agentes IA                        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
{Colors.RESET}
"""
    print(banner)


def print_section(title: str, icon: str = "📋"):
    """Print section header"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{icon} {title}{Colors.RESET}")
    print(f"{Colors.DIM}{'─' * 60}{Colors.RESET}")


def print_success(message: str):
    print(f"{Colors.GREEN}  ✅ {message}{Colors.RESET}")


def print_error(message: str):
    print(f"{Colors.RED}  ❌ {message}{Colors.RESET}")


def print_info(message: str):
    print(f"{Colors.WHITE}  ℹ️  {message}{Colors.RESET}")


def print_data(label: str, value: str):
    print(f"{Colors.YELLOW}  {label}:{Colors.RESET} {Colors.WHITE}{value}{Colors.RESET}")


def print_table_row(col1: str, col2: str, col3: str = ""):
    """Print formatted table row"""
    if col3:
        print(f"  {Colors.WHITE}│{Colors.RESET} {col1:<30} {Colors.WHITE}│{Colors.RESET} {col2:<20} {Colors.WHITE}│{Colors.RESET} {col3:<15} {Colors.WHITE}│{Colors.RESET}")
    else:
        print(f"  {Colors.WHITE}│{Colors.RESET} {col1:<30} {Colors.WHITE}│{Colors.RESET} {col2:<35} {Colors.WHITE}│{Colors.RESET}")


class DatabaseDemo:
    """Demo de conectividad a base de datos"""
    
    def __init__(self):
        self.postgres_url = os.getenv(
            "POSTGRES_URL", 
            "postgresql://store_manager:StoreManager123!@localhost:15432/zava"
        )
        
    async def connect_and_show_info(self) -> bool:
        """Conectar a PostgreSQL y mostrar información"""
        import asyncpg
        
        print_section("Conexión a PostgreSQL", "🗄️")
        
        try:
            # Extract host info for display
            host_info = self.postgres_url.split('@')[1].split('/')[0] if '@' in self.postgres_url else "configured"
            print_info(f"Conectando a: {host_info}")
            
            conn = await asyncpg.connect(self.postgres_url, timeout=10)
            print_success("Conexión establecida exitosamente")
            
            # Get PostgreSQL version
            version = await conn.fetchval("SELECT version();")
            version_short = version.split(',')[0] if version else "Unknown"
            print_data("Versión de PostgreSQL", version_short)
            
            # Get database name
            db_name = await conn.fetchval("SELECT current_database();")
            print_data("Base de datos", db_name)
            
            # Get current user
            user = await conn.fetchval("SELECT current_user;")
            print_data("Usuario", user)
            
            return conn
            
        except Exception as e:
            print_error(f"Error de conexión: {e}")
            return None

    async def show_schema_tables(self, conn) -> None:
        """Mostrar tablas del schema retail"""
        print_section("Estructura del Schema 'retail'", "📊")
        
        tables = await conn.fetch("""
            SELECT 
                table_name,
                (SELECT COUNT(*) FROM information_schema.columns 
                 WHERE table_schema = 'retail' AND table_name = t.table_name) as column_count
            FROM information_schema.tables t
            WHERE table_schema = 'retail'
            ORDER BY table_name;
        """)
        
        print(f"\n  {Colors.WHITE}┌{'─'*32}┬{'─'*22}┐{Colors.RESET}")
        print(f"  {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Tabla':<30}{Colors.RESET} {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Columnas':<20}{Colors.RESET} {Colors.WHITE}│{Colors.RESET}")
        print(f"  {Colors.WHITE}├{'─'*32}┼{'─'*22}┤{Colors.RESET}")
        
        for table in tables:
            print_table_row(table['table_name'], str(table['column_count']))
        
        print(f"  {Colors.WHITE}└{'─'*32}┴{'─'*22}┘{Colors.RESET}")
        print_info(f"Total de tablas: {len(tables)}")

    async def show_sample_data(self, conn) -> None:
        """Mostrar datos de ejemplo"""
        print_section("Datos de Ejemplo", "📦")
        
        # Products
        print(f"\n  {Colors.MAGENTA}🛒 Productos (muestra):{Colors.RESET}")
        products = await conn.fetch("""
            SELECT name, price, category_name 
            FROM retail.products 
            ORDER BY RANDOM() 
            LIMIT 5;
        """)
        
        print(f"  {Colors.WHITE}┌{'─'*32}┬{'─'*22}┬{'─'*17}┐{Colors.RESET}")
        print(f"  {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Producto':<30}{Colors.RESET} {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Precio':<20}{Colors.RESET} {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Categoría':<15}{Colors.RESET} {Colors.WHITE}│{Colors.RESET}")
        print(f"  {Colors.WHITE}├{'─'*32}┼{'─'*22}┼{'─'*17}┤{Colors.RESET}")
        
        for p in products:
            name = (p['name'][:27] + '...') if len(p['name']) > 30 else p['name']
            price = f"${p['price']}"
            category = (p['category_name'][:12] + '...') if p['category_name'] and len(p['category_name']) > 15 else (p['category_name'] or 'N/A')
            print_table_row(name, price, category)
        
        print(f"  {Colors.WHITE}└{'─'*32}┴{'─'*22}┴{'─'*17}┘{Colors.RESET}")

    async def show_statistics(self, conn) -> None:
        """Mostrar estadísticas de la base de datos"""
        print_section("Estadísticas de la Base de Datos", "📈")
        
        # Get counts
        stats = {}
        stats['products'] = await conn.fetchval("SELECT COUNT(*) FROM retail.products;")
        stats['customers'] = await conn.fetchval("SELECT COUNT(*) FROM retail.customers;")
        stats['orders'] = await conn.fetchval("SELECT COUNT(*) FROM retail.orders;")
        stats['stores'] = await conn.fetchval("SELECT COUNT(*) FROM retail.stores;")
        stats['categories'] = await conn.fetchval("SELECT COUNT(*) FROM retail.categories;")
        
        print(f"\n  {Colors.WHITE}┌{'─'*32}┬{'─'*22}┐{Colors.RESET}")
        print(f"  {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Entidad':<30}{Colors.RESET} {Colors.WHITE}│{Colors.RESET} {Colors.BOLD}{'Cantidad':<20}{Colors.RESET} {Colors.WHITE}│{Colors.RESET}")
        print(f"  {Colors.WHITE}├{'─'*32}┼{'─'*22}┤{Colors.RESET}")
        
        for entity, count in stats.items():
            print_table_row(entity.capitalize(), f"{count:,}")
        
        print(f"  {Colors.WHITE}└{'─'*32}┴{'─'*22}┘{Colors.RESET}")
        
        # Revenue stats
        revenue = await conn.fetchrow("""
            SELECT 
                COUNT(*) as order_count,
                COALESCE(SUM(total_amount), 0) as total_revenue,
                COALESCE(AVG(total_amount), 0) as avg_order
            FROM retail.orders;
        """)
        
        print(f"\n  {Colors.MAGENTA}💰 Métricas de Ventas:{Colors.RESET}")
        print_data("Total de Órdenes", f"{revenue['order_count']:,}")
        print_data("Ingresos Totales", f"${revenue['total_revenue']:,.2f}")
        print_data("Promedio por Orden", f"${revenue['avg_order']:,.2f}")

    async def test_product_search(self, conn) -> None:
        """Demostrar búsqueda de productos (como lo haría el agente)"""
        print_section("Simulación de Búsqueda del Agente", "🤖")
        
        search_term = "drill"
        print_info(f"El agente busca productos con: '{search_term}'")
        
        products = await conn.fetch(f"""
            SELECT product_id, name, price, category_name, description
            FROM retail.products
            WHERE LOWER(name) LIKE $1 OR LOWER(description) LIKE $1
            LIMIT 5;
        """, f'%{search_term}%')
        
        if products:
            print_success(f"Encontrados {len(products)} productos:")
            for p in products:
                print(f"\n  {Colors.CYAN}📦 {p['name']}{Colors.RESET}")
                print(f"     Precio: ${p['price']}")
                print(f"     Categoría: {p['category_name'] or 'N/A'}")
                desc = (p['description'][:60] + '...') if p['description'] and len(p['description']) > 60 else (p['description'] or 'Sin descripción')
                print(f"     {Colors.DIM}{desc}{Colors.RESET}")
        else:
            print_info(f"No se encontraron productos con '{search_term}'")

    async def run_demo(self) -> None:
        """Ejecutar demo completo"""
        clear_screen()
        print_banner()
        
        print_info(f"Fecha/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        conn = await self.connect_and_show_info()
        if not conn:
            print_error("No se pudo conectar a la base de datos")
            print_info("Asegúrate de que Docker esté corriendo:")
            print_info("  docker-compose up -d")
            return
        
        try:
            await self.show_schema_tables(conn)
            await self.show_sample_data(conn)
            await self.show_statistics(conn)
            await self.test_product_search(conn)
            
            print_section("Demo Completado", "✨")
            print_success("Todos los componentes están funcionando correctamente")
            print_info("La base de datos está lista para el agente IA")
            
        finally:
            await conn.close()
            print_info("Conexión cerrada")


async def main():
    """Main entry point"""
    demo = DatabaseDemo()
    await demo.run_demo()


if __name__ == "__main__":
    asyncio.run(main())
