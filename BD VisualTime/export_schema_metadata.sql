SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF LINESIZE 200 TRIMSPOOL ON

SPOOL esquema_Visualtime.md

PROMPT # Schema Knowledge
PROMPT

PROMPT ## Tables
SELECT '- ' || table_name FROM user_tables ORDER BY table_name;

PROMPT
PROMPT ## Columns by Table

SELECT '### ' || table_name
FROM user_tables
ORDER BY table_name;

SELECT '| ' || table_name || ' | ' || column_name || ' | ' || data_type || 
       CASE WHEN data_type IN ('VARCHAR2','CHAR') THEN '('||data_length||')' ELSE '' END ||
       ' | ' || nullable || ' | ' || data_default || ' |'
FROM user_tab_columns
ORDER BY table_name, column_id;

PROMPT
PROMPT ## Primary Keys

SELECT '- ' || uc.table_name || ': ' || ucc.column_name
FROM user_constraints uc
JOIN user_cons_columns ucc ON uc.constraint_name = ucc.constraint_name
WHERE uc.constraint_type = 'P'
ORDER BY uc.table_name;

PROMPT
PROMPT ## Foreign Keys

SELECT '- ' || uc.table_name || '.' || ucc.column_name ||
       ' → ' || r.table_name || '.' || r.column_name
FROM user_constraints uc
JOIN user_cons_columns ucc ON uc.constraint_name = ucc.constraint_name
JOIN user_constraints ur ON uc.r_constraint_name = ur.constraint_name
JOIN user_cons_columns r ON ur.constraint_name = r.constraint_name
WHERE uc.constraint_type = 'R'
ORDER BY uc.table_name;

PROMPT
PROMPT ## Indexes

SELECT '- ' || index_name || ' ON ' || table_name || '(' || column_name || ')'
FROM user_ind_columns
ORDER BY table_name, index_name;

PROMPT
PROMPT ## Views

SELECT '- ' || view_name FROM user_views ORDER BY view_name;

PROMPT
PROMPT ## Packages

SELECT '- ' || object_name
FROM user_objects
WHERE object_type = 'PACKAGE'
ORDER BY object_name;

PROMPT
PROMPT ## Procedures

SELECT '- ' || object_name
FROM user_objects
WHERE object_type = 'PROCEDURE'
ORDER BY object_name;

SPOOL OFF