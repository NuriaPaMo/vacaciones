---
name: skill-characterization-testing
description: >
  Caracterización y equivalencia para modernización de legacy. Captura el comportamiento
  REAL del código legacy como oráculo (golden-master / parity tests) para demostrar que el
  código modernizado lo preserva. Úsalo en brownfield antes y durante cualquier reescritura.
  Triggers: "test de caracterización", "characterization", "golden master", "parity test",
  "equivalencia", "equivalence", "pin legacy behavior", "regresión legacy", "comportamiento legacy".
version: 1.0.0
---

# Characterization & Equivalence Testing

Metodología para **fijar (pin) el comportamiento del legacy** y **probar la equivalencia** del
código modernizado. Es el control de riesgo central de toda modernización: sin esto no puedes
afirmar que "lo nuevo hace lo mismo que lo viejo".

> Bolt Framework Stage: CONSTRUCTION (brownfield). Se ejecuta **antes** de reescribir un módulo
> y como puerta de calidad **durante** la transformación. Complementa a `bolt-testing` y a la
> skill `skill-bolt-quality-gates` (gate de equivalencia).

## Principios

1. **El legacy es el oráculo.** Si el legacy calcula `19.27`, el test asevera `19.27`. Las
   discrepancias se documentan aparte como *defectos sospechosos*, no se "corrigen" en silencio.
2. **Concreto sobre abstracto.** Inputs y outputs **literales** (pares I/O reales), no mocks
   genéricos. Cubre los bordes que cubre el legacy (cada rama, valores límite).
3. **Ejecutable desde el día 1.** Los tests compilan y corren contra el legacy YA. Los
   comportamientos aún no implementados en lo nuevo se marcan como *skip* citando la regla
   (`@Disabled("pending RULE-NNN")` / `it.skip` / `[Fact(Skip="RULE-NNN")]`).
4. **Mismo input a ambos lados.** El arnés ejecuta legacy y moderno con la misma entrada y
   compara salidas (valores, efectos, errores). Trazabilidad a `RULE-NNN` (ver `bolt-legacy-analyst`).

## Estrategias (elige según el módulo)

| Estrategia | Cuándo | Cómo |
|---|---|---|
| **Golden master / snapshot** | Salidas deterministas (cálculos, transformaciones, reports) | Captura outputs del legacy para un corpus de inputs → fija como snapshot → el moderno debe reproducirlos |
| **Parity / equivalence harness** | Legacy y moderno pueden correr en paralelo | Mismo input a ambos; comparador asevera igualdad (con tolerancia para floats/fechas) |
| **Contract tests** | Interfaces/API entre módulos | Fija el contrato observado (payloads, códigos, errores) |
| **Property-based** | Reglas con dominio amplio | Genera inputs; propiedad = "moderno ≡ legacy" |
| **Approval/UAT manual** | UI o efectos no automatizables | Checklist humano con evidencia |

## Flujo

1. **Identifica el módulo y sus comportamientos observables** (entradas, salidas, efectos,
   errores). Apóyate en `bolt-legacy-analyst` (reglas `RULE-NNN` y data objects).
2. **Construye el corpus de inputs**: casos felices, bordes, valores límite, datos reales
   anonimizados. Prioriza P0 (dinero/regulatorio/integridad de datos).
3. **Captura el oráculo**: ejecuta el legacy sobre el corpus y guarda outputs (golden master)
   o monta el arnés de parity.
4. **Escribe los tests** en el framework destino (xUnit/JUnit/pytest/Vitest…), nombres que se
   leen como especificación, una clase por módulo legacy. Incluye `README` de cómo correrlos.
5. **Marca pendientes**: comportamientos no migrados aún → *skip* con `RULE-NNN`.
6. **Mide y reporta**: % de comportamiento legacy cubierto y % de equivalencia que pasa
   (alimenta el **gate de equivalencia**).
7. **Discrepancias**: si el legacy parece tener un bug, NO lo repliques a ciegas — regístralo
   como defecto sospechoso y escala a SME antes de decidir.

## Salidas

- Suite de tests de caracterización/equivalencia en el repo del módulo modernizado.
- `EQUIVALENCE_REPORT.md`: corpus, cobertura de comportamiento legacy, pass rate de equivalencia,
  discrepancias/defectos sospechosos, pendientes (`RULE-NNN`).

## Definition of Done (equivalencia)

- [ ] Todo comportamiento P0 del legacy tiene al menos un test de caracterización.
- [ ] Equivalence pass rate ≥ umbral del gate (por defecto **95%**; 100% en rutas P0).
- [ ] Discrepancias documentadas y decididas (replicar vs. corregir) con SME.
- [ ] Pendientes trazados a `RULE-NNN`.

## Integración

- **Entrada**: reglas y data objects de `bolt-legacy-analyst` (`BUSINESS_RULES.md`/`RULE-NNN`).
- **Consumido por**: `bolt-testing` (modo oráculo), `bolt-implement` (transform), y el gate de
  `skill-bolt-quality-gates`.
- **Equivalente Claude (plugin)**: agente `test-engineer` de `code-modernization`. Esta skill
  da la capacidad **nativa y dual-client** cuando el plugin no está disponible (p. ej. Copilot).
