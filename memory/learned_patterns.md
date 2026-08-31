# Patrones Aprendidos - Oracle DBA Agent

Este archivo es la memoria del agente. Se actualiza automáticamente con cada interacción.

## Formato de cada patrón
```
### [ID] Nombre del patrón
- **Fecha**: YYYY-MM-DD
- **Contexto**: Descripción del problema
- **Solución**: Qué se hizo
- **Resultado**: Impacto medido
- **Aplicabilidad**: Cuándo reutilizar este patrón
```

---

## Patrones de Optimización

### [001] Refactorización de SPs con cursores a CTEs y JOINs
- **Fecha**: 2026-08-25
- **Contexto**: SP INSTMP_CAL503 con múltiples cursores anidados y bloques BEGIN/EXCEPTION
- **Solución**:
  1. Reemplazar cursores por subconsultas con ROW_NUMBER() OVER (ORDER BY ...) para obtener el registro más relevante
  2. Mantener la consulta principal con INNER JOIN y LEFT JOIN en lugar de selects separados
  3. Eliminar bloques BEGIN/EXCEPTION innecesarios (solo mantener donde hay manejo de errores específico)
  4. Organizar la lógica en pasos numerados con comentarios claros
  5. Mantener las llamadas a funciones PL/SQL existentes (REAGENERALPKG, GETBOOKPREMIUMS, etc.)
- **Resultado**: SP más legible, mantenible y con mejor rendimiento por reducir context switches
- **Aplicabilidad**: Cualquier SP con múltiples cursores secuenciales que alimentan variables locales
- **Archivo**: `SCRIPTS ORACLE SQL VT/INSTMP_CAL503_V2.sql`
- **Tablas involucradas**: POLICY, PREMIUM, CERTIFICAT, PREMIUM_MO, DETAIL_PRE, COMMISS_PR, POLICY_HIS, INTERMEDIA, ROLES, COVER, LIFE_COVER, DISCO_EXPR, FINANC_DRA

---

## Patrones de Consultas

### [001] Filtro obligatorio SCERTYPE = 2 en búsquedas de pólizas
- **Fecha**: 2026-08-25
- **Contexto**: El usuario indicó que todas las búsquedas de pólizas deben filtrar por SCERTYPE = 2
- **Solución**: Agregar siempre `AND SCERTYPE = 2` en el WHERE de cualquier consulta que involucre la tabla POLICY
- **Resultado**: Consultas más rápidas y resultados consistentes con el tipo de póliza requerido
- **Aplicabilidad**: Cualquier SELECT, UPDATE o análisis que incluya la tabla POLICY

---

## Errores Comunes Detectados

_(Se irán agregando con cada error encontrado y corregido)_

---

## Mejores Prácticas Acumuladas

### [001] Uso de ROW_NUMBER() para reemplazar cursores con MIN/MAX
- **Fecha**: 2026-08-25
- **Contexto**: Cursores que buscaban el registro con MIN(NMOVEMENT) o MAX(NMOVEMENT)
- **Solución**: Usar subconsulta con `ROW_NUMBER() OVER (ORDER BY NMOVEMENT ASC/DESC) = 1`
- **Resultado**: Eliminación de context switches PL/SQL → SQL, mejor rendimiento
- **Aplicabilidad**: Cualquier consulta que busque el primer/último registro de un grupo

### [002] Estructura recomendada para SPs complejos
- **Fecha**: 2026-08-25
- **Contexto**: SPs con lógica extensa y difícil de mantener
- **Solución**: Organizar en pasos numerados (PASO 1, PASO 2, etc.) con comentarios descriptivos
- **Resultado**: Código más legible y mantenible
- **Aplicabilidad**: Todos los SPs nuevos o refactorizados

---

## Patrones de Optimización de CTEs

### [002] Reducción de CTEs: Fusión de contadores simples en un solo CTE
- **Fecha**: 2026-08-25
- **Contexto**: Script COB - SELECT CONTROL INGRESO.sql con 9 CTEs + 2 ramas en SELECT final (~708 líneas)
- **Solución**:
  1. **Fusionar CTEs de conteo**: `cteContadorFPago` + `cteContadorRecibos` + `cteContadorGeneral` → 1 solo CTE `cteContadores` usando subqueries escalares en LEFT JOIN
  2. **Extraer `cteMonedaPoliza`**: Pre-calcula la moneda de póliza (CURREN_POL con SCERTYPE=2 y DNULLDATE IS NULL) que antes se repetía en 5 OUTER APPLY dentro de cteFormaPago
  3. **Fusión de ramas duplicadas en SELECT final**: Las 2 ramas (regular + adicionales) se unifican en 1 sola usando LEFT JOIN RELCONCEPTS + CASE condicional en el JOIN a VPOL
  4. **Fusión de ramas en `cteDatosReciboAgrupado`**: Ramas 1+3 (ambas detalle) se fusionan usando LEFT JOIN TRELDOC con CASE para seleccionar ImporteRecibidoMO
- **Resultado**: 9 CTEs + 2 ramas → 6 CTEs + 1 rama (~480 líneas, reducción ~32%)
- **Aplicabilidad**: Cualquier query con múltiples CTEs de conteo simple + UNION ALL de ramas similares con JOINs diferentes
- **Archivo**: `SCRIPT UTILITARIOS VISUALTIME/COB - SELECT CONTROL INGRESO_OPTIMIZADO.sql`
- **Tablas involucradas**: COLFORMREF, CASH_MOV, BANK_MOV, MOVE_ACC, RELCONCEPTS, CURREN_POL, PREMIUM_MO, PREMIUM, FINANC_DRA, BILLS, TRELDOC, NS_View_DatosGeneralesPoliza

### [003] Patrón de fusión de SELECT final con UNION ALL (join condicional)
- **Fecha**: 2026-08-25
- **Contexto**: Dos ramas de SELECT casi idénticas que difieren solo en cómo hacen JOIN a una tabla de dimensión (una por PK directa, otra por FK intermediaria)
- **Solución**: LEFT JOIN a la tabla intermediaria + CASE condicional en el INNER JOIN:
  ```sql
  LEFT JOIN INTERMEDIARY_TABLE i ON主.key = i.key
  INNER JOIN DIMENSION_TABLE dim ON 
      CASE WHEN i.fk IS NOT NULL THEN i.fk ELSE 主.direct_fk END = dim.pk
      AND (i.fk IS NOT NULL OR (主.col1 = dim.col1 AND 主.col2 = dim.col2))
  ```
- **Resultado**: Eliminación de ~100 líneas duplicadas, mayor mantenibilidad
- **Aplicabilidad**: Query con UNION ALL donde las ramas solo difieren en el path de JOIN a una dimensión
- **Nota**: El optimizer de Oracle suele manejar bien el CASE en INNER JOIN. Verificar con EXPLAIN PLAN en producción.
