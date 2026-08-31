"""
MCP Oracle Server - Conecta opencode a Oracle Database
Herramientas: run_sql, run_script, get_schema, explain_plan, search_tables
"""
import os
import json
import oracledb
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("oracle-db")

# Configuración de conexión desde variables de entorno
ORACLE_USER = os.environ.get("ORACLE_USER", "INSUDB")
ORACLE_PASSWORD = os.environ.get("ORACLE_PASSWORD", "Ns8U4t23")
ORACLE_DSN = os.environ.get("ORACLE_DSN", "172.16.19.80:1521/BDUAT")

def get_connection():
    """Obtiene conexión a Oracle"""
    if not all([ORACLE_USER, ORACLE_PASSWORD, ORACLE_DSN]):
        raise ValueError("Faltan variables de entorno: ORACLE_USER, ORACLE_PASSWORD, ORACLE_DSN")
    return oracledb.connect(user=ORACLE_USER, password=ORACLE_PASSWORD, dsn=ORACLE_DSN)


@mcp.tool()
def run_sql(sql: str) -> str:
    """
    Ejecuta una consulta SQL en Oracle y retorna los resultados.
    Usar para SELECT simples, verificación de datos, conteos, etc.
    
    Args:
        sql: Consulta SQL a ejecutar (máximo 4000 caracteres recomendado)
    
    Returns:
        Resultados de la consulta en formato tabla
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(sql)
        
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        if not rows:
            return f"Consulta ejecutada. Columnas: {columns}\nSin resultados."
        
        result = f"Columnas: {columns}\n"
        result += f"Filas retornadas: {len(rows)}\n\n"
        
        # Mostrar primeras 50 filas para no saturar
        display_rows = rows[:50]
        for i, row in enumerate(display_rows):
            result += f"Row {i+1}: {dict(zip(columns, row))}\n"
        
        if len(rows) > 50:
            result += f"\n... y {len(rows) - 50} filas más."
        
        return result
        
    except Exception as e:
        return f"Error ejecutando SQL: {str(e)}"


@mcp.tool()
def run_script(script: str) -> str:
    """
    Ejecuta un script PL/SQL completo en Oracle.
    Usar para procedimientos almacenados, bloques anónimos, DDL, etc.
    
    Args:
        script: Script PL/SQL a ejecutar
    
    Returns:
        Resultado de la ejecución
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(script)
        
        result = "Script ejecutado exitosamente."
        
        # Si hay output de DBMS_OUTPUT
        if hasattr(cursor, 'fetchall'):
            try:
                rows = cursor.fetchall()
                if rows:
                    result += f"\nSalida:\n{json.dumps([dict(zip([d[0] for d in cursor.description], r)) for r in rows], indent=2, default=str)}"
            except:
                pass
        
        cursor.close()
        conn.close()
        return result
        
    except Exception as e:
        return f"Error ejecutando script: {str(e)}"


@mcp.tool()
def get_schema(owner: str = None) -> str:
    """
    Obtiene metadata del esquema Oracle: tablas, columnas, tipos, PK/FK.
    
    Args:
        owner: Owner/esquema a consultar (default: usuario actual)
    
    Returns:
        Estructura del esquema en formato JSON
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        owner_filter = f"AND OWNER = '{owner.upper()}'" if owner else ""
        
        # Obtener tablas
        cursor.execute(f"""
            SELECT TABLE_NAME, NUM_ROWS, LAST_ANALYZED
            FROM ALL_TABLES
            WHERE 1=1 {owner_filter}
            ORDER BY TABLE_NAME
        """)
        tables = [{"name": r[0], "rows": r[1], "analyzed": str(r[2]) if r[2] else None} 
                  for r in cursor.fetchall()]
        
        # Obtener columnas de cada tabla principal
        table_columns = {}
        for t in tables[:30]:  # Limitar a 30 tablas para no saturar
            cursor.execute(f"""
                SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE, 
                       (SELECT COUNT(*) FROM ALL_CONS_COLUMNS ACC 
                        JOIN ALL_CONSTRAINTS AC ON ACC.CONSTRAINT_NAME = AC.CONSTRAINT_NAME 
                        WHERE ACC.COLUMN_NAME = ATC.COLUMN_NAME 
                        AND ACC.TABLE_NAME = ATC.TABLE_NAME 
                        AND AC.CONSTRAINT_TYPE = 'P') as IS_PK
                FROM ALL_TAB_COLUMNS ATC
                WHERE TABLE_NAME = '{t["name"]}' {owner_filter}
                ORDER BY COLUMN_ID
            """)
            table_columns[t["name"]] = [
                {"name": r[0], "type": r[1], "length": r[2], 
                 "nullable": r[3] == 'Y', "is_pk": r[4] > 0}
                for r in cursor.fetchall()
            ]
        
        cursor.close()
        conn.close()
        
        return json.dumps({
            "tables_count": len(tables),
            "tables": tables[:30],
            "columns": table_columns
        }, indent=2, default=str)
        
    except Exception as e:
        return f"Error obteniendo esquema: {str(e)}"


@mcp.tool()
def explain_plan(sql: str) -> str:
    """
    Ejecuta EXPLAIN PLAN para una consulta SQL y retorna el plan de ejecución.
    Usar para analizar rendimiento, costos, cardinalidades y paths de acceso.
    
    Args:
        sql: Consulta SQL para analizar el plan
    
    Returns:
        Plan de ejecución formateado
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Ejecutar EXPLAIN PLAN
        explain_sql = f"EXPLAIN PLAN FOR {sql}"
        cursor.execute(explain_sql)
        
        # Obtener el plan
        cursor.execute("""
            SELECT PLAN_TABLE_OUTPUT 
            FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'ALL'))
        """)
        
        plan = "\n".join([r[0] for r in cursor.fetchall()])
        
        cursor.close()
        conn.close()
        
        return f"Plan de ejecución:\n{plan}"
        
    except Exception as e:
        return f"Error generando plan: {str(e)}"


@mcp.tool()
def search_tables(pattern: str) -> str:
    """
    Busca tablas en el esquema Oracle por patrón de nombre.
    
    Args:
        pattern: Patrón de búsqueda (puede usar % como wildcard)
    
    Returns:
        Lista de tablas que coinciden con el patrón
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        cursor.execute(f"""
            SELECT TABLE_NAME, NUM_ROWS, LAST_ANALYZED
            FROM ALL_TABLES
            WHERE TABLE_NAME LIKE '%{pattern.upper()}%'
            ORDER BY TABLE_NAME
        """)
        
        results = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        if not results:
            return f"No se encontraron tablas con el patrón '{pattern}'"
        
        result = f"Tablas encontradas ({len(results)}):\n"
        for r in results[:30]:
            result += f"  - {r[0]} (filas: {r[1]}, analizado: {r[2]})\n"
        
        return result
        
    except Exception as e:
        return f"Error buscando tablas: {str(e)}"


if __name__ == "__main__":
    mcp.run(transport="stdio")
