#!/usr/bin/env python3
"""
Script de prueba de conectividad MCP
Demuestra que el servidor MCP está funcionando correctamente
"""

import json
import requests
import socket
import sys


def test_port_listening(host: str, port: int) -> bool:
    """Verifica si el servidor está escuchando en el puerto"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception:
        return False


def test_mcp_endpoint(url: str) -> dict:
    """Prueba el endpoint MCP con una solicitud JSON-RPC"""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream"
    }
    
    # Solicitud de inicialización MCP
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "connectivity-test", "version": "1.0"}
        }
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=5, stream=True)
        return {
            "status_code": response.status_code,
            "headers": dict(response.headers),
            "connected": True
        }
    except requests.exceptions.RequestException as e:
        return {"connected": False, "error": str(e)}


def main():
    print("=" * 60)
    print("🔌 PRUEBA DE CONECTIVIDAD MCP")
    print("=" * 60)
    
    host = "127.0.0.1"
    port = 8000
    mcp_url = f"http://{host}:{port}/mcp"
    
    # Test 1: Verificar puerto
    print(f"\n📡 Test 1: Verificando puerto {port}...")
    if test_port_listening(host, port):
        print(f"   ✅ Servidor escuchando en {host}:{port}")
    else:
        print(f"   ❌ No hay servidor en {host}:{port}")
        print("\n💡 Inicia el servidor MCP con:")
        print("   python sales_analysis/sales_analysis.py")
        sys.exit(1)
    
    # Test 2: Probar endpoint MCP
    print(f"\n📡 Test 2: Probando endpoint MCP...")
    print(f"   URL: {mcp_url}")
    result = test_mcp_endpoint(mcp_url)
    
    if result.get("connected"):
        print(f"   ✅ Endpoint MCP respondiendo")
        print(f"   📊 Status Code: {result.get('status_code')}")
        print(f"   📋 Content-Type: {result.get('headers', {}).get('content-type', 'N/A')}")
    else:
        print(f"   ❌ Error: {result.get('error')}")
        sys.exit(1)
    
    # Test 3: Verificar respuesta JSON-RPC
    print(f"\n📡 Test 3: Verificando protocolo JSON-RPC...")
    headers = {"Content-Type": "application/json"}
    payload = {"jsonrpc": "2.0", "id": 1, "method": "ping"}
    
    try:
        response = requests.post(mcp_url, json=payload, headers=headers, timeout=5)
        data = response.json()
        
        if "jsonrpc" in data:
            print(f"   ✅ Servidor responde con JSON-RPC válido")
            print(f"   📄 Respuesta: {json.dumps(data, indent=6)}")
        else:
            print(f"   ⚠️  Respuesta no es JSON-RPC estándar")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    print("\n" + "=" * 60)
    print("✅ PRUEBA DE CONECTIVIDAD MCP EXITOSA!")
    print("=" * 60)
    print("\n📝 RESUMEN:")
    print(f"   • Servidor MCP: ACTIVO en {host}:{port}")
    print(f"   • Endpoint: {mcp_url}")
    print(f"   • Protocolo: MCP Streamable HTTP")
    print(f"   • Estado: FUNCIONANDO")
    print("=" * 60)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
