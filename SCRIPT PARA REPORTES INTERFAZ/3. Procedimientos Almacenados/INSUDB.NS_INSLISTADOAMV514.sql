CREATE OR REPLACE PROCEDURE INSUDB.NS_INSLISTADOAMV514
/*-------------------------------------------------------------------------------*/
/* NOMBRE    : NS_INSLISTADOAMV514                                                      */
/* OBJETIVO  : OBTENER LISTADO AMV CONFIGURADOS EN EL SISTEMA                           */
/* PARAMETROS: 1 -                                                                      */
/*             2 -                                                                      */
/*             3 -                                                                      */
/*             4 -                                                                      */
/*             5 -                                                                      */
/*             6 -                                                                      */
/* SOURCESAFE INFORMATION                                                                                       */
/*     $Author: NSB- GEORGE NOTO $                                                                              */
/*     $Date: 31/03/26  $                                                                                       */
/*     $Revision:  $                                                                                            */

/*-------------------------------------------------------------------------------*/
   (SKEY                	            T_INTERFACE.SKEY%TYPE,
	NSHEET              	            MASTERSHEET.NSHEET%TYPE,
	NUSERCODE           	            MASTERSHEET.NUSERCODE%TYPE,
	NERROR                              OUT T_ERR_INTERFACE.NERROR%TYPE,
    SERRORDESC                          OUT VARCHAR2 
	) AUTHID CURRENT_USER AS

BEGIN

   -- Borrar solo la ejecución sobre la misma llave; si no existe, limpiar tabla de reporte
   DELETE FROM TIMETMP.TMP_INT514 WHERE SKEY = NS_INSLISTADOAMV514.SKEY;
   IF SQL%ROWCOUNT = 0 THEN
      DELETE FROM TIMETMP.TMP_INT514;
   END IF;
   --DELETE TRACE WHERE NUSERCODE = 15;
   COMMIT;


INSERT INTO TIMETMP.TMP_INT514 (
  SKEY,
  SCOD_GRUPO,
  SGRUPO,
  SCOD_SUBGRUPO,
  SSUBGRUPO,
  SCOD_PRESTACION,
  SPRESTACION,
  NVALOR_MO,
  NVALOR_LO,
  SCIUDAD,
  STIPO,
  SCOD_MONEDAORIGEN,
  SMONEDA_ORIGEN,
  NTIPO_CAMBIO,
  SDESCRIPCION_AMV
)
WITH TasaCambioDolar AS (    
    SELECT   COALESCE(e.NEXCHANGE, 0) as TC_DOLAR,
             e.DEFFECDATE,   
             ROW_NUMBER() OVER(ORDER BY e.DEFFECDATE DESC)  as rn       
    FROM  EXCHANGE e 
    WHERE e.NCURRENCY = 2 -- Moneda dólar.
           AND e.DEFFECDATE <= SYSDATE
           AND (e.DNULLDATE IS NULL OR e.DNULLDATE > SYSDATE) 
)
SELECT
  NS_INSLISTADOAMV514.SKEY AS SKEY,  -- Valor de llave
  MB.STYPEBENEFIT AS SCOD_GRUPO,  -- Código grupo inferido de tipo beneficio
  GAMV.SDESCRIPT AS SGRUPO,  -- Descripción grupo de BENEFITS_GROUP
  MB.SBENEFITCLAS AS SCOD_SUBGRUPO,  -- Código subgrupo inferido de clase beneficio
  GSUB.SDESCRIPT AS SSUBGRUPO,  -- Descripción subgrupo de BENEFITS_CATEGORY (ajustar mapeo si NBENEFCATEG no coincide)
  MF.SBENEFITCODE AS SCOD_PRESTACION,  -- Código de la prestación
  MB.SDESCRIPT AS SPRESTACION,  -- Descripción de la prestación
  CAST(MF.NVALUE AS NUMBER(18,6)) AS SVALOR_MO,  -- Valor en moneda origen
  CASE WHEN MF.NCURRENCY = 1 THEN (MF.NVALUE) ELSE (MF.NVALUE* Tasa.TC_DOLAR) END AS SVALOR_LO,  -- Valor en moneda local (placeholder para tipo cambio)
  OFI.SDESCRIPT AS SCIUDAD,  -- Ciudad (placeholder, ajustar con tabla de oficinas si NOFFICE indica ciudad)
  'BASE' AS STIPO,  -- Tipo
  MF.NCURRENCY AS COD_MONEDAORIGEN,  -- Código moneda origen
  MNDA.SDESCRIPT AS MONEDA_ORIGEN,  -- Nombre moneda (placeholder, ajustar con tabla de monedas)
  CASE WHEN MF.NCURRENCY = 1 THEN 1 ELSE Tasa.TC_DOLAR END AS TIPO_CAMBIO,  -- Tipo cambio (placeholder)
  TMED.SDESCRIPT 
FROM MEDICALFEES MF
INNER JOIN MEDICALBENEFITS MB ON MF.SBENEFITCODE = MB.SBENEFIT
INNER JOIN TAB_MEDICALFEES TMED ON MF.NIDMEDICALFEE = TMED.NIDMEDICALFEE
INNER JOIN TABLE8600 GAMV ON MB.STYPEBENEFIT = GAMV.STYPEBENEFIT 
INNER JOIN TABLE8601 GSUB ON MB.SBENEFITCLAS = GSUB.SBENEFITCLAS
LEFT JOIN TABLE11 MNDA ON MF.ncurrency = MNDA.ncodigint
INNER JOIN TABLE9 OFI ON TMED.NOFFICE = OFI.NOFFICE  
LEFT JOIN TasaCambioDolar Tasa on tasa.rn=1

WHERE TMED.SDESCRIPT LIKE '%AMV%'  
  AND MF.DEFFECDATE <= SYSDATE
  AND (MF.DNULLDATE IS NULL OR MF.DNULLDATE > SYSDATE);
  
  
  COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NERROR := SQLCODE;
        SERRORDESC := SQLERRM;
        CRETRACE2('ERR TMP_INT514', 593, SERRORDESC);          
        RAISE;    
END NS_INSLISTADOAMV514;