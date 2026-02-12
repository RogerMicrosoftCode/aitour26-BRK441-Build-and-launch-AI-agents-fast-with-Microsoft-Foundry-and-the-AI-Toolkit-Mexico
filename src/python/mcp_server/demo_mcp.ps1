# ================================================================
# 🎯 DEMO MCP CONNECTIVITY - Script de Demostración Automatizado
# ================================================================
# 
# Este script automatiza la demostración de conectividad MCP
# para sesiones de presentación de Zava Retail.
#
# Uso:
#   .\demo_mcp.ps1           # Ejecutar demo completa
#   .\demo_mcp.ps1 -StartServer   # Iniciar servidor + demo
#   .\demo_mcp.ps1 -TestOnly      # Solo prueba de conectividad
#
# ================================================================

param(
    [switch]$StartServer,
    [switch]$TestOnly,
    [switch]$Help
)

$ErrorActionPreference = "SilentlyContinue"

# Configuración
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$McpServerDir = Join-Path $ScriptDir "sales_analysis"
$McpServerScript = Join-Path $McpServerDir "sales_analysis.py"
$DemoScript = Join-Path $ScriptDir "demo_mcp_connectivity.py"
$McpPort = 8000

function Show-Header {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  🎯 DEMO MCP CONNECTIVITY - Zava Retail" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  📅 Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "  🌐 Puerto: $McpPort" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Help {
    Write-Host ""
    Write-Host "USO:" -ForegroundColor Yellow
    Write-Host "  .\demo_mcp.ps1              Ejecutar demo completa"
    Write-Host "  .\demo_mcp.ps1 -StartServer Iniciar servidor + demo"
    Write-Host "  .\demo_mcp.ps1 -TestOnly    Solo prueba de conectividad"
    Write-Host "  .\demo_mcp.ps1 -Help        Mostrar esta ayuda"
    Write-Host ""
    Write-Host "PREREQUISITOS:" -ForegroundColor Yellow
    Write-Host "  1. Python 3.10+ instalado"
    Write-Host "  2. Dependencias instaladas (pip install -r requirements.txt)"
    Write-Host "  3. (Opcional) PostgreSQL para pruebas completas"
    Write-Host ""
}

function Test-ServerRunning {
    $connection = Test-NetConnection -ComputerName "127.0.0.1" -Port $McpPort -WarningAction SilentlyContinue
    return $connection.TcpTestSucceeded
}

function Start-McpServer {
    Write-Host "🚀 Iniciando servidor MCP..." -ForegroundColor Yellow
    
    # Verificar si ya está corriendo
    if (Test-ServerRunning) {
        Write-Host "   ⚠️  Servidor ya está ejecutándose en puerto $McpPort" -ForegroundColor Yellow
        return $true
    }
    
    # Iniciar servidor en segundo plano
    $serverJob = Start-Process -FilePath "python" `
        -ArgumentList $McpServerScript `
        -WorkingDirectory $McpServerDir `
        -NoNewWindow `
        -PassThru
    
    Write-Host "   ⏳ Esperando que el servidor inicie..." -ForegroundColor Gray
    
    # Esperar hasta 10 segundos
    $maxWait = 10
    $waited = 0
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waited++
        if (Test-ServerRunning) {
            Write-Host "   ✅ Servidor MCP iniciado exitosamente!" -ForegroundColor Green
            return $true
        }
    }
    
    Write-Host "   ❌ Timeout esperando al servidor" -ForegroundColor Red
    return $false
}

function Run-ConnectivityTest {
    Write-Host ""
    Write-Host "🔍 Ejecutando prueba de conectividad..." -ForegroundColor Yellow
    Write-Host ""
    
    if (Test-Path $DemoScript) {
        python $DemoScript
    } else {
        Write-Host "❌ Script de demo no encontrado: $DemoScript" -ForegroundColor Red
        return $false
    }
}

function Show-QuickTest {
    Write-Host ""
    Write-Host "⚡ TEST RÁPIDO DE CONECTIVIDAD" -ForegroundColor Cyan
    Write-Host "=" * 50
    
    # Test 1: Puerto
    Write-Host "1. Verificando puerto $McpPort..." -ForegroundColor White
    if (Test-ServerRunning) {
        Write-Host "   ✅ Servidor escuchando" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Servidor no encontrado" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Inicia el servidor con: .\demo_mcp.ps1 -StartServer" -ForegroundColor Yellow
        return
    }
    
    # Test 2: HTTP
    Write-Host "2. Probando endpoint HTTP..." -ForegroundColor White
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:$McpPort/mcp" `
            -Method POST `
            -ContentType "application/json" `
            -Body '{"jsonrpc":"2.0","id":1,"method":"ping"}' `
            -UseBasicParsing `
            -TimeoutSec 5 `
            -ErrorAction SilentlyContinue
        
        Write-Host "   ✅ Endpoint respondiendo (Status: $($response.StatusCode))" -ForegroundColor Green
    }
    catch {
        if ($_.Exception.Response) {
            Write-Host "   ✅ Servidor respondiendo con JSON-RPC" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Error de conexión" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "=" * 50
    Write-Host "✅ SERVIDOR MCP FUNCIONANDO" -ForegroundColor Green
    Write-Host "=" * 50
}

# ================================================================
# MAIN
# ================================================================

if ($Help) {
    Show-Help
    exit 0
}

Show-Header

if ($StartServer) {
    # Iniciar servidor y ejecutar demo
    if (Start-McpServer) {
        Start-Sleep -Seconds 2
        Run-ConnectivityTest
    }
}
elseif ($TestOnly) {
    # Solo test rápido
    Show-QuickTest
}
else {
    # Demo completa (asume servidor ya corriendo)
    if (Test-ServerRunning) {
        Run-ConnectivityTest
    } else {
        Write-Host "⚠️  Servidor MCP no está corriendo" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opciones:" -ForegroundColor White
        Write-Host "  1. Ejecutar: .\demo_mcp.ps1 -StartServer" -ForegroundColor Gray
        Write-Host "  2. O manualmente: python sales_analysis/sales_analysis.py" -ForegroundColor Gray
        Write-Host ""
        
        $response = Read-Host "¿Deseas iniciar el servidor ahora? (S/N)"
        if ($response -eq "S" -or $response -eq "s") {
            if (Start-McpServer) {
                Start-Sleep -Seconds 2
                Run-ConnectivityTest
            }
        }
    }
}

Write-Host ""
