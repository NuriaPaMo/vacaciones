---
mode: agent
description: Revisa todos los diagramas Mermaid del proyecto, detecta errores de sintaxis usando Mermaid CLI y los corrige directamente en los archivos fuente.
---

# Revisión y Corrección de Diagramas Mermaid

## Objetivo

Auditar **todos los diagramas Mermaid** del proyecto, identificar los que tienen errores
de sintaxis y corregirlos preservando la intención original del diagrama.

## Instrucciones para el agente

### Paso 1 — Validación con Mermaid CLI

Ejecuta el script de validación en terminal (ajusta la ruta a la raíz de tu repositorio):

```powershell
.\scripts\powershell\Validate-MermaidDiagrams.ps1 -Fix -OutputReport test-output/mermaid-validation-report.json
```

Lee el informe generado en `test-output/mermaid-validation-report.json` para obtener
la lista completa de diagramas con errores (campo `errors`).

### Paso 2 — Análisis de cada error

Para cada diagrama con error en el informe:

1. Lee el archivo fuente indicado en `file`.
2. Localiza el bloque mermaid por número de línea (`lineNumber`).
3. Analiza el error reportado por mmdc.
4. Identifica el tipo de problema (ver tabla de errores comunes abajo).
5. Propón la corrección **mínima** que resuelva el error sin cambiar la semántica.

#### Errores comunes y correcciones

| Patrón de error mmdc | Causa probable | Corrección |
|---|---|---|
| `Parse error` en línea N | Sintaxis inválida (flecha, nodo, etc.) | Revisar tokens en esa línea |
| `Expecting 'NEWLINE'` | Falta salto de línea entre nodos | Añadir `\n` |
| `Duplicate node id` | ID de nodo repetido | Renombrar uno de los nodos |
| `Unknown diagram type` | Tipo mal escrito (ej: `sequenDiagram`) | Corregir el tipo |
| `Lexical error` | Caracteres especiales sin comillas | Envolver etiqueta en comillas dobles |
| `Cannot read properties of undefined` | Bloque vacío o solo tipo | Añadir al menos un nodo/arco |
| `flowchart` sin dirección | Falta `TD`, `LR`, etc. | Añadir dirección |

### Paso 3 — Corrección

Para cada diagrama con error:

1. Aplica la corrección en el archivo fuente usando `replace_string_in_file`.
2. **No cambies** el tipo de diagrama, la lógica ni los nodos existentes.
3. Si el error es ambiguo y la corrección podría cambiar la semántica, documéntalo
   como comentario inline `%% REVISAR: <motivo>` justo antes del bloque.
4. Si el diagrama está **completamente vacío o irrecuperable**, sustitúyelo por un
   placeholder válido:

   ````markdown
   ```mermaid
   graph TD
       A[Diagrama pendiente de definir]
   ```
   ````

### Paso 4 — Re-validación

Tras aplicar todas las correcciones, vuelve a ejecutar el script:

```powershell
.\scripts\powershell\Validate-MermaidDiagrams.ps1 -OutputReport test-output/mermaid-validation-report-after.json -FailOnError
```

Compara los dos informes: `mermaid-validation-report.json` (antes) vs
`mermaid-validation-report-after.json` (después).

### Paso 5 — Informe de cambios

Genera un resumen con:

- Nº de diagramas revisados
- Nº de errores encontrados y corregidos
- Nº de errores que requieren revisión manual (con `%% REVISAR`)
- Lista de archivos modificados

Luego haz commit de los cambios:

```powershell
git add -A
git commit -m "fix: corregir sintaxis de diagramas Mermaid

- X diagramas corregidos automáticamente
- Y diagramas marcados para revisión manual
- Informe: test-output/mermaid-validation-report-after.json"
```

## Notas importantes

- **Alcance**: busca en todo el proyecto excepto directorios generados o de terceros
  (p. ej. `node_modules/`, `legacy/`, carpetas de salida de herramientas).
- **Preserva la intención**: las correcciones deben ser sintácticas, no semánticas.
- **Un cambio por bloque**: usa `replace_string_in_file` con el bloque completo como contexto.
- **Idioma**: los comentarios `%% REVISAR` van en español.
