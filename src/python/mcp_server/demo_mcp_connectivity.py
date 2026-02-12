#!/usr/bin/env python3
"""
=================================================================
🎯 DEMO: Prueba de Conectividad MCP para Zava Retail
=================================================================

Este script demuestra que el servidor MCP está funcionando 
correctamente y puede ser usado en sesiones de demostración.

Uso:
    python demo_mcp_connectivity.py

Prerequisitos:
    1. El servidor MCP debe estar ejecutándose:
       python sales_analysis/sales_analysis.py
    
    2. (Opcional) PostgreSQL para pruebas completas con herramientas
=================================================================
"""

import json
import socket
import sys
import time
from datetime import datetime

try:
    import requests
except ImportError:
    print("❌ Error: Instala 'requests' con: pip install requests")
    sys.exit(1)


# Configuración
MCP_HOST = "127.0.0.1"
MCP_PORT = 8000
MCP_ENDPOINT = f"http://{MCP_HOST}:{MCP_PORT}/mcp"


def print_header():
    """Imprime el encabezado de la demo"""
    print()
    print("=" * 70)
    print("🎯 DEMO: PRUEBA DE CONECTIVIDAD MCP - ZAVA RETAIL")
    print("=" * 70)
    print(f"📅 Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🌐 Endpoint: {MCP_ENDPOINT}")
    print("=" * 70)
    print()


def print_section(title: str, icon: str = "📋"):
    """Imprime una sección con formato"""
    print()
    print(f"{icon} {title}")
    print("-" * 50)


def test_port_connectivity() -> bool:
    """Test 1: Verifica si el servidor está escuchando"""
    print_section("TEST 1: Verificación de Puerto", "🔌")
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        result = sock.connect_ex((MCP_HOST, MCP_PORT))
        sock.close()
        
        if result == 0:
            print(f"   ✅ Servidor escuchando en {MCP_HOST}:{MCP_PORT}")
            return True
        else:
            print(f"   ❌ No hay servidor en {MCP_HOST}:{MCP_PORT}")
            return False
    except Exception as e:
        print(f"   ❌ Error de conexión: {e}")
        return False


def test_http_endpoint() -> bool:
    """Test 2: Verifica que el endpoint HTTP responde"""
    print_section("TEST 2: Verificación de Endpoint HTTP", "🌐")
    
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream"
    }
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "demo-connectivity-test", "version": "1.0"}
        }
    }
    
    try:
        response = requests.post(
            MCP_ENDPOINT, 
            json=payload, 
            headers=headers, 
            timeout=5,
            stream=True
        )
        
        print(f"   ✅ Endpoint respondiendo")
        print(f"   📊 Status Code: {response.status_code}")
        print(f"   📋 Content-Type: {response.headers.get('content-type', 'N/A')}")
        
        return response.status_code == 200
        
    except requests.exceptions.ConnectionError:
        print(f"   ❌ No se puede conectar al endpoint")
        return False
    except requests.exceptions.Timeout:
        print(f"   ❌ Timeout al conectar")
        return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def test_jsonrpc_protocol() -> bool:
    """Test 3: Verifica el protocolo JSON-RPC"""
    print_section("TEST 3: Verificación de Protocolo JSON-RPC", "📡")
    
    headers = {"Content-Type": "application/json"}
    payload = {"jsonrpc": "2.0", "id": 1, "method": "ping"}
    
    try:
        response = requests.post(MCP_ENDPOINT, json=payload, headers=headers, timeout=5)
        data = response.json()
        
        if "jsonrpc" in data:
            print(f"   ✅ Servidor responde con JSON-RPC válido")
            print(f"   📄 Versión: {data.get('jsonrpc')}")
            
            # Mostrar error esperado (el servidor requiere headers específicos)
            if "error" in data:
                error_msg = data["error"].get("message", "")
                if "Not Acceptable" in error_msg:
                    print(f"   ℹ️  Servidor requiere headers MCP Streamable HTTP")
                    print(f"   ✅ Esto es el comportamiento esperado!")
            
            return True
        else:
            print(f"   ⚠️  Respuesta no es JSON-RPC estándar")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def test_mcp_streamable_http() -> bool:
    """Test 4: Verifica el protocolo MCP Streamable HTTP"""
    print_section("TEST 4: Protocolo MCP Streamable HTTP", "🚀")
    
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream"
    }
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "demo-client", "version": "1.0"}
        }
    }
    
    try:
        response = requests.post(
            MCP_ENDPOINT, 
            json=payload, 
            headers=headers, 
            timeout=5,
            stream=True
        )
        
        content_type = response.headers.get('content-type', '')
        
        if 'text/event-stream' in content_type:
            print(f"   ✅ Servidor usando Server-Sent Events (SSE)")
            print(f"   📋 Content-Type: {content_type}")
            print(f"   ✅ Protocolo MCP Streamable HTTP activo!")
            return True
        elif response.status_code == 200:
            print(f"   ✅ Servidor respondiendo correctamente")
            return True
        else:
            print(f"   ⚠️  Respuesta inesperada: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def show_server_info():
    """Muestra información del servidor MCP"""
    print_section("INFORMACIÓN DEL SERVIDOR MCP", "ℹ️")
    
    print(f"   🏪 Nombre: mcp-zava-sales")
    print(f"   🌐 URL: {MCP_ENDPOINT}")
    print(f"   📡 Protocolo: MCP Streamable HTTP")
    print(f"   🔐 Seguridad: Row Level Security (RLS)")
    print()
    print("   📋 HERRAMIENTAS DISPONIBLES:")
    print("   ├── get_multiple_table_schemas")
    print("   │   └── Obtener esquemas de tablas de la BD")
    print("   ├── execute_sales_query")
    print("   │   └── Ejecutar consultas PostgreSQL con RLS")
    print("   └── get_current_utc_date")
    print("       └── Obtener fecha/hora UTC actual")


def print_summary(results: dict):
    """Imprime el resumen de la demo"""
    print()
    print("=" * 70)
    print("📊 RESUMEN DE LA DEMOSTRACIÓN")
    print("=" * 70)
    
    all_passed = all(results.values())
    
    for test_name, passed in results.items():
        status = "✅ PASÓ" if passed else "❌ FALLÓ"
        print(f"   {test_name}: {status}")
    
    print()
    print("-" * 70)
    
    if all_passed:
        print("🎉 RESULTADO: ¡TODOS LOS TESTS PASARON!")
        print("✅ El servidor MCP está funcionando correctamente")
        print("✅ Listo para usar con el Agent Builder")
    else:
        print("⚠️  RESULTADO: ALGUNOS TESTS FALLARON")
        print("💡 Verifica que el servidor MCP esté ejecutándose:")
        print("   cd src/python/mcp_server/sales_analysis")
        print("   python sales_analysis.py")
    
    print("=" * 70)
    print()


def main():
    """Función principal de la demo"""
    print_header()
    
    results = {}
    
    # Test 1: Puerto
    results["Test 1: Puerto"] = test_port_connectivity()
    
    if not results["Test 1: Puerto"]:
        print()
        print("⚠️  SERVIDOR NO ENCONTRADO")
        print("💡 Inicia el servidor MCP con:")
        print("   cd src/python/mcp_server/sales_analysis")
        print("   python sales_analysis.py")
        print()
        return 1
    
    time.sleep(0.5)
    
    # Test 2: HTTP Endpoint
    results["Test 2: HTTP"] = test_http_endpoint()
    time.sleep(0.5)
    
    # Test 3: JSON-RPC
    results["Test 3: JSON-RPC"] = test_jsonrpc_protocol()
    time.sleep(0.5)
    
    # Test 4: MCP Streamable HTTP
    results["Test 4: MCP Protocol"] = test_mcp_streamable_http()
    
    # Información del servidor
    show_server_info()
    
    # Resumen
    print_summary(results)
    
    return 0 if all(results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
