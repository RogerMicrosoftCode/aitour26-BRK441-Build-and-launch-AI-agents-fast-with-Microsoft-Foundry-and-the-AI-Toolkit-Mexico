#!/usr/bin/env python3
"""
Prueba de Integración - AI Tour 26 BRK441
==========================================

Este script proporciona pruebas de integración repetibles para demostrar
la conectividad entre:
1. Frontend (Web App)
2. Agente (MCP Server)  
3. Base de datos PostgreSQL

Uso:
    python test_integration.py

Requisitos:
    - Docker container con PostgreSQL corriendo
    - Variables de entorno configuradas (.env)
"""

import asyncio
import os
import sys
import json
import httpx
from datetime import datetime
from typing import Optional, Dict, Any
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dotenv import load_dotenv
load_dotenv()

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(text: str):
    print(f"\n{Colors.CYAN}{Colors.BOLD}{'='*60}{Colors.RESET}")
    print(f"{Colors.CYAN}{Colors.BOLD}  {text}{Colors.RESET}")
    print(f"{Colors.CYAN}{Colors.BOLD}{'='*60}{Colors.RESET}\n")

def print_success(text: str):
    print(f"{Colors.GREEN}✅ {text}{Colors.RESET}")

def print_error(text: str):
    print(f"{Colors.RED}❌ {text}{Colors.RESET}")

def print_info(text: str):
    print(f"{Colors.BLUE}ℹ️  {text}{Colors.RESET}")

def print_warning(text: str):
    print(f"{Colors.YELLOW}⚠️  {text}{Colors.RESET}")

def print_step(step: int, text: str):
    print(f"\n{Colors.MAGENTA}[Paso {step}]{Colors.RESET} {Colors.BOLD}{text}{Colors.RESET}")


class IntegrationTester:
    """Clase para ejecutar pruebas de integración"""
    
    def __init__(self):
        self.postgres_url = os.getenv(
            "POSTGRES_URL", 
            "postgresql://store_manager:StoreManager123!@localhost:15432/zava"
        )
        self.webapp_url = os.getenv("WEBAPP_URL", "http://localhost:8000")
        self.mcp_server_url = os.getenv("MCP_SERVER_URL", "http://localhost:8001")
        self.results: Dict[str, Dict[str, Any]] = {}

    async def test_database_connection(self) -> bool:
        """Prueba 1: Verificar conectividad a PostgreSQL"""
        print_step(1, "Probando conexión a PostgreSQL...")
        
        try:
            import asyncpg
            
            # Parse connection string and extract components
            conn_str = self.postgres_url
            print_info(f"Conectando a: {conn_str.split('@')[1] if '@' in conn_str else conn_str}")
            
            # Create connection
            conn = await asyncpg.connect(conn_str, timeout=10)
            
            # Test basic query
            version = await conn.fetchval("SELECT version();")
            print_success(f"PostgreSQL conectado: {version[:50]}...")
            
            # Test schema access
            tables = await conn.fetch("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'retail'
                ORDER BY table_name;
            """)
            
            print_success(f"Tablas en schema 'retail': {len(tables)}")
            for table in tables:
                print_info(f"  - {table['table_name']}")
            
            await conn.close()
            
            self.results["database"] = {
                "status": "success",
                "tables_count": len(tables),
                "timestamp": datetime.now().isoformat()
            }
            return True
            
        except Exception as e:
            print_error(f"Error conectando a PostgreSQL: {e}")
            self.results["database"] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            return False

    async def test_database_queries(self) -> bool:
        """Prueba 2: Ejecutar consultas de ejemplo en la base de datos"""
        print_step(2, "Ejecutando consultas de prueba en PostgreSQL...")
        
        try:
            import asyncpg
            
            conn = await asyncpg.connect(self.postgres_url, timeout=10)
            
            # Test products query
            products = await conn.fetch("""
                SELECT product_id, name, price 
                FROM retail.products 
                LIMIT 5;
            """)
            print_success(f"Productos encontrados: {len(products)}")
            for p in products:
                print_info(f"  - {p['name']}: ${p['price']}")
            
            # Test customers count
            customer_count = await conn.fetchval("""
                SELECT COUNT(*) FROM retail.customers;
            """)
            print_success(f"Total de clientes: {customer_count}")
            
            # Test orders count
            order_count = await conn.fetchval("""
                SELECT COUNT(*) FROM retail.orders;
            """)
            print_success(f"Total de órdenes: {order_count}")
            
            # Test stores
            stores = await conn.fetch("""
                SELECT store_id, name, city 
                FROM retail.stores 
                LIMIT 3;
            """)
            print_success(f"Tiendas encontradas: {len(stores)}")
            for s in stores:
                print_info(f"  - {s['name']} ({s['city']})")
            
            await conn.close()
            
            self.results["queries"] = {
                "status": "success",
                "products_count": len(products),
                "customer_count": customer_count,
                "order_count": order_count,
                "timestamp": datetime.now().isoformat()
            }
            return True
            
        except Exception as e:
            print_error(f"Error ejecutando consultas: {e}")
            self.results["queries"] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            return False

    async def test_webapp_health(self) -> bool:
        """Prueba 3: Verificar que el Web App está corriendo"""
        print_step(3, "Verificando estado del Web App...")
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(f"{self.webapp_url}/health")
                
                if response.status_code == 200:
                    data = response.json()
                    print_success(f"Web App saludable: {data}")
                    
                    self.results["webapp"] = {
                        "status": "success",
                        "health_response": data,
                        "timestamp": datetime.now().isoformat()
                    }
                    return True
                else:
                    print_error(f"Web App respondió con código: {response.status_code}")
                    self.results["webapp"] = {
                        "status": "failed",
                        "status_code": response.status_code,
                        "timestamp": datetime.now().isoformat()
                    }
                    return False
                    
        except httpx.ConnectError:
            print_warning(f"Web App no está corriendo en {self.webapp_url}")
            print_info("Ejecuta: python src/python/web_app/web_app.py")
            self.results["webapp"] = {
                "status": "not_running",
                "url": self.webapp_url,
                "timestamp": datetime.now().isoformat()
            }
            return False
        except Exception as e:
            print_error(f"Error verificando Web App: {e}")
            self.results["webapp"] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            return False

    async def test_webapp_frontend(self) -> bool:
        """Prueba 4: Verificar que el frontend está sirviendo correctamente"""
        print_step(4, "Verificando frontend del Web App...")
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(f"{self.webapp_url}/")
                
                if response.status_code == 200:
                    content = response.text
                    if "<!DOCTYPE html>" in content.lower() or "<html" in content.lower():
                        print_success("Frontend HTML cargado correctamente")
                        print_info(f"Tamaño del HTML: {len(content)} bytes")
                        
                        self.results["frontend"] = {
                            "status": "success",
                            "size_bytes": len(content),
                            "timestamp": datetime.now().isoformat()
                        }
                        return True
                    else:
                        print_warning("Respuesta recibida pero no parece ser HTML")
                        return False
                else:
                    print_error(f"Frontend respondió con código: {response.status_code}")
                    return False
                    
        except httpx.ConnectError:
            print_warning(f"No se puede conectar al frontend en {self.webapp_url}")
            self.results["frontend"] = {
                "status": "not_running",
                "timestamp": datetime.now().isoformat()
            }
            return False
        except Exception as e:
            print_error(f"Error verificando frontend: {e}")
            self.results["frontend"] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            return False

    async def test_mcp_server_product_search(self) -> bool:
        """Prueba 5: Probar búsqueda de productos via MCP Server (directo a DB)"""
        print_step(5, "Probando búsqueda de productos (integración MCP → PostgreSQL)...")
        
        try:
            # Import the customer sales module directly
            sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "mcp_server" / "customer_sales"))
            from customer_sales_postgres import PostgreSQLCustomerSales
            
            # Create database connection
            provider = PostgreSQLCustomerSales(self.postgres_url)
            await provider.create_pool()
            
            # Test product search
            test_product = "hammer"
            print_info(f"Buscando productos con nombre: '{test_product}'")
            
            result = await provider.get_products_by_name(
                product_name=test_product,
                max_rows=5,
                rls_user_id="00000000-0000-0000-0000-000000000000"
            )
            
            if result:
                print_success(f"Resultados encontrados para '{test_product}':")
                # Parse and display results
                try:
                    products = json.loads(result) if isinstance(result, str) else result
                    if isinstance(products, list):
                        for p in products[:3]:
                            name = p.get('name', 'N/A')
                            price = p.get('price', 'N/A')
                            print_info(f"  - {name}: ${price}")
                except:
                    print_info(f"  Resultado: {result[:200]}...")
            else:
                print_warning("No se encontraron productos")
            
            await provider.close_pool()
            
            self.results["mcp_product_search"] = {
                "status": "success",
                "search_term": test_product,
                "timestamp": datetime.now().isoformat()
            }
            return True
            
        except Exception as e:
            print_error(f"Error en búsqueda de productos: {e}")
            self.results["mcp_product_search"] = {
                "status": "failed",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
            return False

    async def run_all_tests(self) -> Dict[str, Any]:
        """Ejecutar todas las pruebas de integración"""
        print_header("Pruebas de Integración - AI Tour 26 BRK441")
        print_info(f"Fecha/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print_info(f"PostgreSQL: {self.postgres_url.split('@')[1] if '@' in self.postgres_url else 'configured'}")
        print_info(f"Web App: {self.webapp_url}")
        
        # Run tests
        test_results = {
            "database_connection": await self.test_database_connection(),
            "database_queries": await self.test_database_queries(),
            "webapp_health": await self.test_webapp_health(),
            "webapp_frontend": await self.test_webapp_frontend(),
            "mcp_product_search": await self.test_mcp_server_product_search(),
        }
        
        # Summary
        print_header("Resumen de Pruebas")
        
        passed = sum(1 for v in test_results.values() if v)
        failed = len(test_results) - passed
        
        for test_name, result in test_results.items():
            status = f"{Colors.GREEN}PASÓ{Colors.RESET}" if result else f"{Colors.RED}FALLÓ{Colors.RESET}"
            print(f"  {test_name}: {status}")
        
        print(f"\n{Colors.BOLD}Total: {passed}/{len(test_results)} pruebas pasadas{Colors.RESET}")
        
        if failed > 0:
            print_warning(f"{failed} prueba(s) fallaron. Revisa los mensajes de error arriba.")
        else:
            print_success("¡Todas las pruebas pasaron! La integración está funcionando correctamente.")
        
        # Save results to file
        results_file = Path(__file__).parent / "integration_test_results.json"
        with open(results_file, "w") as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "summary": {
                    "passed": passed,
                    "failed": failed,
                    "total": len(test_results)
                },
                "tests": test_results,
                "details": self.results
            }, f, indent=2, default=str)
        
        print_info(f"\nResultados guardados en: {results_file}")
        
        return test_results


async def main():
    """Función principal"""
    tester = IntegrationTester()
    results = await tester.run_all_tests()
    
    # Exit with error code if any test failed
    if not all(results.values()):
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
