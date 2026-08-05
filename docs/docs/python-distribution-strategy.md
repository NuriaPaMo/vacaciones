# Bolt Framework - Python Distribution Strategy

## 📋 Resumen Ejecutivo

Esta estrategia permite distribuir Bolt Framework con scripts Python **sin requerir instalación manual** de dependencias por parte del usuario final. Los scripts de bootstrap automatizan todo el proceso.

---

## 🏗️ Arquitectura de la Solución

### ✅ VALIDADO: Entorno en Proyecto Destino

**CRÍTICO**: El entorno virtual Python (`.bolt-venv/`) se crea en el **proyecto destino**, NO en el repositorio bolt-framework.

```text
┌─────────────────────────────────────────────────────────────┐
│  REPO ORIGEN (bolt-framework)                                    │
│  - Contiene scripts Python source                           │
│  - NO contiene .bolt-venv/                                  │
│  - Solo se usa para inicialización                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Init.ps1 copia todo a...
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  PROYECTO DESTINO (ej: C:\projects\my-ecommerce)            │
│                                                             │
│  .bolt-venv/                  ← AQUÍ se crea el entorno    │
│  ├── Scripts/python.exe       ← Python isolado             │
│  └── Lib/site-packages/       ← Packages instalados aquí  │
│                                                             │
│  .boltf/scripts/powershell/                                │
│  └── Bootstrap-Python.ps1     ← Copiado aquí, ejecuta aquí│
│                                                             │
│  .claude/skills/                                            │
│  └── skill-creator/                                         │
│      ├── requirements.txt     ← Copiado aquí               │
│      └── scripts/*.py         ← Copiados aquí              │
│                                                             │
│  Invoke-PythonScript.ps1      ← Copiado aquí               │
│  Test-PythonEnvironment.ps1   ← Copiado aquí               │
│  docs/python-integration.md   ← Copiado aquí               │
└─────────────────────────────────────────────────────────────┘
```

**Verificación automática**: Ver [python-environment-validation.md](python-environment-validation.md)

### Componentes Implementados

```text
bolt-framework/
├── 📁 .bolt-venv/                           # Virtual environment (gitignored)
│   ├── Scripts/python.exe                   # Python isolado (Windows)
│   └── bin/python                          # Python isolado (Linux/macOS)
│
├── 📁 .boltf/scripts/
│   ├── powershell/
│   │   └── Bootstrap-Python.ps1            # ✨ Setup automático (Windows)
│   └── bash/
│       └── bootstrap-python.sh             # ✨ Setup automático (Linux/macOS)
│
├── 📁 .claude/skills/skill-creator/
│   ├── requirements.txt                    # ✨ Dependencias Python
│   └── scripts/                            # Scripts Python funcionales
│       ├── quick_validate.py               # Validación (NO requiere IA)
│       ├── package_skill.py                # Empaquetado (NO requiere IA)
│       ├── run_eval.py                     # Evaluación (requiere IA)
│       ├── improve_description.py          # Optimización (requiere IA)
│       └── run_loop.py                     # Loop completo (requiere IA)
├── 📁 .boltf/
│   └── 📁 scripts/
│       ├── 📁 powershell/
│       │   ├── Bootstrap-Python.ps1            # ✨ Inicializador
│       │   ├── Test-PythonEnvironment.ps1      # ✨ Verificación
│       │   └── Test-PythonIntegration.ps1      # ✨ E2E test
│       └── 📁 bash/
│           ├── bootstrap-python.sh             # ✨ Inicializador
│           └── Test-PythonEnvironment.sh       # ✨ Verificación
│
├── 📁 docs/
│   └── python-integration.md               # ✨ Guía completa para usuarios
│
├── 📁 examples/
│   └── python-scripts-usage.ps1            # ✨ Ejemplos de uso comunes
│
├── 📄 Invoke-PythonScript.ps1              # ✨ Wrapper conveniente
├── 📄 package.json                         # ✨ Scripts npm integrados
├── 📄 .gitignore                           # ✨ Actualizado con .bolt-venv/
└── 📄 README.md                            # ✨ Sección Python añadida
```

---

## 🚀 Flujo de Usuario

### Para Usuarios Finales

#### 1️⃣ Clonar el Repositorio

```powershell
git clone https://github.com/your-org/bolt-framework.git
cd bolt-framework
```

#### 2️⃣ Bootstrap Automático (Una sola vez)

```powershell
# Windows
.\.boltf\scripts\powershell\Bootstrap-Python.ps1

# Linux/macOS
source .boltf/scripts/bash/bootstrap-python.sh
```

**Qué hace:**

- ✅ Verifica Python 3.9+
- ✅ Crea virtual environment en `.bolt-venv/`
- ✅ Instala `anthropic` y `pyyaml`
- ✅ Muestra instrucciones de uso

#### 3️⃣ Usar Scripts Python

```powershell
# Opción A: Wrapper conveniente
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\quick_validate.py my-skill\

# Opción B: npm scripts
npm run skill:validate my-skill\

# Opción C: Activación manual
.\.bolt-venv\Scripts\Activate.ps1
python .claude\skills\skill-creator\scripts\quick_validate.py my-skill\
deactivate
```

---

## 📦 Dependencias Python

### Core (Siempre Instaladas)

| Paquete     | Versión  | Propósito                                  |
| ----------- | -------- | ------------------------------------------ |
| `anthropic` | >=0.39.0 | SDK oficial de Claude para optimización IA |
| `pyyaml`    | >=6.0    | Parseo YAML frontmatter                    |

### Stdlib (Built-in)

- `pathlib`, `json`, `subprocess`, `concurrent.futures`, `argparse`, `re`, `zipfile`

---

## 🎯 Casos de Uso

### Sin IA (No requiere API key)

#### ✅ Validación de Skills

```powershell
npm run skill:validate .claude\skills\my-skill\
```

**Uso:** Validar estructura de SKILL.md antes de commit

#### 📦 Empaquetado

```powershell
npm run skill:package .claude\skills\my-skill\ .\dist\
```

**Uso:** Crear `.skill` distributable

### Con IA (Requiere ANTHROPIC_API_KEY)

#### 🤖 Evaluación de Triggers

```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_eval.py `
    --eval-set evals\my-skill.json `
    --skill-path .claude\skills\my-skill\
```

**Uso:** Testing de precisión de activación

#### 🚀 Optimización Automática

```powershell
.\Invoke-PythonScript.ps1 .claude\skills\skill-creator\scripts\run_loop.py `
    --eval-set evals\my-skill.json `
    --skill-path .claude\skills\my-skill\ `
    --max-iterations 10
```

**Uso:** Mejorar descripción del skill con IA

---

## 🔧 Integración CI/CD

### GitHub Actions

```yaml
name: Python Scripts CI
on: [push, pull_request]

jobs:
  validate-skills:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Bootstrap Python Environment
        run: .\.boltf\scripts\powershell\Bootstrap-Python.ps1

      - name: Verify Environment
        run: .\.boltf\scripts\powershell\Test-PythonEnvironment.ps1

      - name: Validate All Skills
        run: npm run skill:validate-all
```

### Azure Pipelines

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.11'

  - powershell: .\.boltf\scripts\powershell\Bootstrap-Python.ps1
    displayName: 'Bootstrap Python'

  - powershell: .\.boltf\scripts\powershell\Test-PythonEnvironment.ps1
    displayName: 'Verify Environment'

  - powershell: npm run skill:validate-all
    displayName: 'Validate Skills'
```

---

## 🛡️ Aislamiento de Dependencias

### Virtual Environment (`.bolt-venv/`)

**Ventajas:**

- ✅ **Aislamiento completo** - No contamina Python del sistema
- ✅ **Reproducible** - Mismo entorno en cualquier máquina
- ✅ **Portable** - Cada proyecto tiene su entorno
- ✅ **Gitignored** - No se commitea (cada dev crea el suyo)

**Ubicación:**

- Windows: `.bolt-venv\Scripts\python.exe`
- Linux/macOS: `.bolt-venv/bin/python`

### requirements.txt por Skill

Cada skill que requiere Python tiene su propio `requirements.txt`:

```text
.claude/skills/
├── skill-creator/
│   └── requirements.txt     # anthropic, pyyaml
├── skill-senior-devops/
│   └── requirements.txt     # terraform-related
└── skill-senior-frontend/
    └── requirements.txt     # webpack-analyzer
```

---

## 📊 Estrategia de Fallback

### Nivel 1: Scripts Básicos (Sin Python)

- Usar PowerShell/Bash para tareas simples
- Ejemplo: `Validate-Scopes.ps1`

### Nivel 2: Scripts Python Sin IA

- Validación, empaquetado, análisis estático
- **No requieren API key**

### Nivel 3: Scripts Python Con IA

- Optimización, evaluación automática
- **Requieren ANTHROPIC_API_KEY**

### Detección Automática

```powershell
# En Init.ps1 o scripts principales
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Warning "Python no disponible. Funcionalidades avanzadas limitadas."
    # Continuar sin Python
}
```

---

## 🧪 Verificación

### Test Manual

```powershell
# Windows
.\.boltf\scripts\powershell\Test-PythonEnvironment.ps1

# Linux/macOS
bash .boltf/scripts/bash/Test-PythonEnvironment.sh
```

### Test Automatizado (CI)

```yaml
- name: Test Python Environment
  run: .\Test-PythonEnvironment.ps1
```

**Verifica:**

1. ✅ Python 3.9+ disponible
2. ✅ Virtual environment existe
3. ✅ Paquetes instalados (`anthropic`, `pyyaml`)
4. ✅ Imports funcionan
5. ✅ Wrapper script funciona

---

## 📚 Documentación

| Arquivo                               | Propósito                      |
| ------------------------------------- | ------------------------------ |
| **docs/python-integration.md**        | Guía completa para usuarios    |
| **examples/python-scripts-usage.ps1** | Ejemplos prácticos             |
| **README.md**                         | Quick start y referencia       |
| **.bolt-venv-README.md**              | Notas sobre el entorno virtual |

---

## 🔄 Actualización de Dependencias

```powershell
# Recrear entorno con nuevas versiones
Remove-Item -Recurse -Force .bolt-venv
.\.boltf\scripts\powershell\Bootstrap-Python.ps1

# O forzar actualización
.\.boltf\scripts\powershell\Bootstrap-Python.ps1 -Force
```

---

## 🎓 Mejores Prácticas

### ✅ Hacer

1. **Usar wrapper** `Invoke-PythonScript.ps1` para portabilidad
2. **Verificar entorno** antes de operaciones críticas
3. **Documentar requisitos** de API key cuando aplique
4. **Proveer fallbacks** si Python no está disponible
5. **Gitignore venv** - nunca comitear `.bolt-venv/`

### ⛔ Evitar

1. **No instalar globalmente** - siempre usar venv
2. **No hardcodear rutas** - usar variables
3. **No asumir Python** - verificar disponibilidad
4. **No comitear secrets** - usar variables de entorno
5. **No mezclar versiones** - respetar requirements.txt

---

## 🚀 Próximos Pasos

### Implementado ✅

- [x] Bootstrap scripts (PowerShell + Bash)
- [x] Virtual environment automático
- [x] requirements.txt
- [x] Wrapper script conveniente
- [x] Scripts de verificación
- [x] npm scripts integration
- [x] Documentación completa
- [x] Ejemplos de uso
- [x] .gitignore actualizado
- [x] **Init.ps1 copia todos los archivos al proyecto destino**
- [x] **Validación end-to-end (.boltf/scripts/powershell/Test-PythonIntegration.ps1)**
- [x] **Documentación de validación (python-environment-validation.md)**
- [x] **Entorno se crea en proyecto destino, NO en bolt-framework**

### Testing 🧪

- ✅ **.boltf/scripts/powershell/Test-PythonEnvironment.ps1** - Verifica entorno en proyecto actual
- ✅ **.boltf/scripts/powershell/Test-PythonIntegration.ps1** - E2E test completo del flujo
- ✅ **.boltf/scripts/bash/Test-PythonEnvironment.sh** - Test para Linux/macOS
- ✅ **python-environment-validation.md** - Documentación de validación

### Pendiente 🔜

- [x] ~~Integración en Init.ps1 (detección automática)~~ COMPLETADO
- [ ] GitHub Action workflow pregenerado
- [ ] Azure Pipeline template
- [ ] Script de actualización de skills Python
- [ ] Telemetría de uso (opcional)

---

## 📞 Soporte

**Problemas comunes:**

1. **"Python not found"**
   → Instalar Python 3.9+ y añadir a PATH

2. **"anthropic module not found"**
   → Ejecutar `Bootstrap-Python.ps1 -Force`

3. **"Permission denied"** (Windows)
   → `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

4. **Virtual env corrupto**
   → Eliminar `.bolt-venv/` y ejecutar bootstrap

**Documentación:**

- 📖 [docs/python-integration.md](docs/python-integration.md)
- 🔧 [examples/python-scripts-usage.ps1](examples/python-scripts-usage.ps1)

---

**Bolt Framework v2.0.0** - AI-Driven Development Lifecycle
