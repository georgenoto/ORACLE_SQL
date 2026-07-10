--############### SELECT TABLAS CON DATOS ###############
SELECT owner, table_name, num_rows
FROM dba_tables
WHERE owner = 'INSUDB'       -- o el schema que necesites
  and table_name like '%BATCH%'
  AND num_rows > 0
ORDER BY table_name;
--############### SELECT BUSCAR COLUMNAS EN TABLAS ###############
SELECT owner AS esquema, table_name AS tabla, 
       column_name AS columna, data_type AS tipo_dato
FROM  all_tab_cols
WHERE owner = 'INSUDB'
    AND column_name = 'NAMOUNT_VAT'
ORDER BY owner, table_name;
--############### BUSCAR EN TODA LAS BASE DE DATOS ###############
    select * from SYS.ALL_SOURCE where upper(TEXT) like '%ODONTOLOGIA%%' 
--############### LOG ERRORES POR PROCEDIMIENTO ALMACENADOS  ###############
select * from TRACE where proc like '%TMP_INT51%'
select * from T_ERR_INTERFACE order by dcompdate desc
--############### TABLAS PARA REPORTES POR INTERFAZ  ###############
SELECT * FROM MASTERSHEET Where Nsheet IN ('511','512','513','514','515')
SELECT * FROM FIELDSHEET Where Nsheet IN ('511','512','513','514','515')
SELECT * FROM WINDOWS WHERE SCODISPL IN ('INT511','INT512','INT513','INT514','INT515')

--############### PROVEEDORES  ###############
-- SSTATREGT --> ESTADOS DE PROVEEDORES
SELECT * FROM TABLE26
-- NTYPEPROV --> TIPOS DE PROVEEDORES
SELECT * FROM TABLE7027

--############### POLIZAS  ###############
--NCODIGINT --> MONEDAS
SELECT * FROM TABLE11
--ROLES.nrole= TABLE12.nrole --> ROLES DE UNA POLIZA
SELECT * FROM TABLE12
--POLICY.spolitype = TABLE17.ncodigint --> TIPOS DE POLIZAS
SELECT * FROM TABLE17 
--POLICY.Sstatus_Pol = TABLE181.Sstatusva --> ESTADOS DE POLIZAS Y DE LOS CERTIFICADOS
SELECT * FROM TABLE181
-- TAB_MEDBENEFITS.SBENEFCATEG_CODE = TABLE8604.STYPECARE --> AMBULATORIA/HOSPITALARIA
SELECT * FROM TABLE8604

--############### PROCESOS BATCH  ###############
select * from BATCH_JOB where skey= 'T2025110310060900442'
select * from BATCH_PARAM WHERE NBATCH= 86 ---86	1	4	Fecha Proceso	PARAM4	1	20/02/2006 10:06:07
select * from BATCH_PARAM_VALUE WHERE skey= 'T2025110310060900442' AND NSEQ=4