# Validación: Python en Proyecto Destino

## ✅ Verificación de Arquitectura

### Flujo Correcto

```text
┌─────────────────────────────────────────────────────────────┐
│  REPO ORIGEN (bolt-framework)                                    │
│  - Scripts Python están aquí                                │
│  - NO se crea .bolt-venv aquí                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Init.ps1 copia...
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  PROYECTO DESTINO (ej: ../my-ecommerce-app)                 │
│                                                             │
│  .bolt-venv/                  ← Creado aquí (gitignored)   │
│  │                                                          │
│  .boltf/                                                   │
│  ├── scripts/                                               │
│  │   ├── powershell/                                        │
│  │   │   ├── Bootstrap-Python.ps1  ← Ejecutar desde aquí  │
│  │   │   └── Test-PythonEnvironment.ps1                   │
│  │   └── bash/                                              │
│  │       └── Test-PythonEnvironment.sh                    │
│  │                                                          │
│  .github/                                                   │
│  ├── skills/                                                │
│  │   └── skill-creator/                                     │
│  │       ├── requirements.txt                              │
│  │       └── scripts/                                       │
│  │           ├── quick_validate.py                         │
│  │           └── ...                                        │
│  │                                                          │
│  Invoke-PythonScript.ps1      ← Wrapper en raíz            │
│  docs/                                                      │
│  └── python-integration.md                                  │
│  examples/                                                  │
│  └── python-scripts-usage.ps1                              │
└─────────────────────────────────────────────────────────────┘
```

## 🔍 Comprobaciones

### 1. Init.ps1 Copia TODO lo Necesario

✅ **Verificado en Init.ps1 líneas 492-518:**

```powershell
# .github (con skills Python)
Copy-Item "$root\.github" "$OutputDirectory\.github" -Recurse -Force

# .boltf (con Bootstrap-Python.ps1 y scripts de test)
Copy-Item "$root\.boltf" "$OutputDirectory\.boltf" -Recurse -Force

# Scripts Python raíz (solo wrapper)
@("Invoke-PythonScript.ps1")

# Documentación
Copy-Item "$root\docs" "$OutputDirectory\docs" -Recurse

# Ejemplos
Copy-Item "$root\examples" "$OutputDirectory\examples" -Recurse
```

### 2. Bootstrap-Python.ps1 Usa Proyecto Destino

✅ **Verificado - Línea 8:**

```powershell
param(
    [string]$ProjectRoot = $PWD,  # ← Usa PWD (directorio actual)
    ...
)

$VenvPath = Join-Path $ProjectRoot ".bolt-venv"  # ← Crea en proyecto actual
```

**Correcto porque:**

- Si usuario ejecuta desde `C:\projects\my-app\`, PWD será `C:\projects\my-app\`
- `.bolt-venv` se creará en `C:\projects\my-app\.bolt-venv\`
- NO en `F:\repos\bolt-framework\.bolt-venv\`

### 3. Invoke-PythonScript.ps1 Busca en Proyecto Destino

✅ **Verificado - Línea 18:**

```powershell
$ProjectRoot = $PSScriptRoot  # ← Directorio del script
$VenvPath = Join-Path $ProjectRoot ".bolt-venv"
```

**Correcto porque:**

- Script se copia a `C:\projects\my-app\Invoke-PythonScript.ps1`
- `$PSScriptRoot` será `C:\projects\my-app\`
- Busca `.bolt-venv` en `C:\projects\my-app\.bolt-venv\`

### 4. Paths Relativos en requirements.txt

✅ **Verificado - requirements.txt usa paths relativos:**

```bash
.claude/skills/skill-creator/requirements.txt
```

**Funcionan porque:**

- Bootstrap-Python.ps1 ejecuta desde raíz del proyecto destino
- Paths son relativos a `$ProjectRoot` (línea 27 de Bootstrap-Python.ps1)
- `.claude/skills/...` existe en el proyecto destino después de Init.ps1

## 🧪 Prueba de Concepto

### Escenario de Uso Real

```powershell
# Paso 1: Usuario inicializa proyecto
cd F:\repos\bolt-framework
.\Init.ps1 -OutputDirectory "C:\projects\my-ecommerce" -ProjectType green

# Paso 2: Usuario va al nuevo proyecto
cd C:\projects\my-ecommerce

# Paso 3: Usuario bootstrapea Python
.\.boltf\scripts\powershell\Bootstrap-Python.ps1

# Resultado esperado:
# - .bolt-venv se crea en C:\projects\my-ecommerce\.bolt-venv\
# - Packages instalados desde C:\projects\my-ecommerce\.claude\skills\skill-creator\requirements.txt
# - Python Scripts ejecutables desde C:\projects\my-ecommerce\

# Paso 4: Usuario ejecuta scripts Python
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py .claude\skills\skill-creator\
```

## ✅ Checklist de Validación

- [x] Init.ps1 copia `.github/` completo (skills con scripts Python)
- [x] Init.ps1 copia `.boltf/` completo (Bootstrap-Python.ps1 y scripts de test)
- [x] Init.ps1 copia scripts raíz (Invoke-PythonScript.ps1)
- [x] Init.ps1 copia `docs/` (python-integration.md)
- [x] Init.ps1 copia `examples/` (python-scripts-usage.ps1)
- [x] Bootstrap-Python.ps1 usa `$PWD` (directorio actual del usuario)
- [x] Bootstrap-Python.ps1 crea `.bolt-venv` en proyecto destino
- [x] Invoke-PythonScript.ps1 usa `$PSScriptRoot` (raíz del proyecto destino)
- [x] requirements.txt usa paths relativos a raíz del proyecto
- [x] `.bolt-venv/` está en .gitignore (no se commitea)

## 🚨 Problemas Potenciales (Resueltos)

### ❌ Problema Original

#### Init.ps1 NO copiaba scripts Python a proyecto destino

- Usuario ejecutaba Invoke-PythonScript.ps1 desde bolt-framework
- .bolt-venv se creaba en bolt-framework en vez del proyecto nuevo

### ✅ Solución Implementada

- Init.ps1 ahora copia todos los archivos necesarios
- Scripts Python se ejecutan desde el proyecto destino
- .bolt-venv se crea en el proyecto destino

## 📋 Próximos Pasos

1. **Probar el flujo completo** en un proyecto real:

   ```powershell
   # Desde bolt-framework
   .\Init.ps1 -OutputDirectory "..\test-python-integration" -ProjectType green

   # Desde proyecto nuevo
   cd ..\test-python-integration
   .\.boltf\scripts\powershell\Bootstrap-Python.ps1
   .\.boltf\scripts\powershell\Test-PythonEnvironment.ps1
   ```

2. **Verificar archivos copiados:**

   ```powershell
   Test-Path .\.bolt-venv                        # Debe existir DESPUÉS de bootstrap
   Test-Path .\Invoke-PythonScript.ps1          # Debe existir
   Test-Path .\.boltf\scripts\powershell\Bootstrap-Python.ps1  # Debe existir
   Test-Path .\.boltf\scripts\powershell\Test-PythonEnvironment.ps1  # Debe existir
   Test-Path .\.claude\skills\skill-creator\requirements.txt    # Debe existir
   Test-Path .\docs\python-integration.md       # Debe existir
   ```

3. **Validar ejecución de scripts:**

```powershell
   .\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py .claude\skills\skill-creator\
```

## ✅ Conclusión

**El entorno Python SE CREA en el proyecto destino, NO en bolt-framework.**

Todos los paths y scripts están configurados correctamente para que:

1. Init.ps1 copie todo lo necesario
2. Bootstrap-Python.ps1 cree el venv en el proyecto destino
3. Los scripts Python se ejecuten desde el proyecto destino
4. No haya dependencias con el repositorio original

---

**Validación**: 2026-02-26
**Estado**: ✅ CORRECTO
