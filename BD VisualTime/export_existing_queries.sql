SET LONG 200000 LONGCHUNKSIZE 200000 PAGESIZE 0 FEEDBACK OFF HEADING OFF LINESIZE 200 TRIMSPOOL ON

SPOOL consultas_existentes.md

PROMPT # Existing Queries and PL/SQL Code
PROMPT

PROMPT ## Stored Procedures
SELECT '### ' || name || CHR(10) || '```sql' || CHR(10) ||
       text || CHR(10) || '```'
FROM user_source
WHERE type = 'PROCEDURE'
ORDER BY name, line;

PROMPT ## Functions
SELECT '### ' || name || CHR(10) || '```sql' || CHR(10) ||
       text || CHR(10) || '```'
FROM user_source
WHERE type = 'FUNCTION'
ORDER BY name, line;

PROMPT ## Packages
SELECT '### ' || name || ' (PACKAGE)' || CHR(10) || '```sql' || CHR(10) ||
       text || CHR(10) || '```'
FROM user_source
WHERE type = 'PACKAGE'
ORDER BY name, line;

PROMPT ## Package Bodies
SELECT '### ' || name || ' (PACKAGE BODY)' || CHR(10) || '```sql' || CHR(10) ||
       text || CHR(10) || '```'
FROM user_source
WHERE type = 'PACKAGE BODY'
ORDER BY name, line;

PROMPT ## Views
SELECT '### ' || view_name || CHR(10) || '```sql' || CHR(10) ||
       text || CHR(10) || '```'
FROM user_views
ORDER BY view_name;

SPOOL OFF