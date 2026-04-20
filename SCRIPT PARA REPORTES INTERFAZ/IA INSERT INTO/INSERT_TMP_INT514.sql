-- Script actualizado para insertar en TIMETMP.TMP_INT514
-- Usando MEDICALFEES como tabla origen principal, unida con MEDICALBENEFITS para descripciones
-- Grupos y subgrupos inferidos de MEDICALBENEFITS (STYPEBENEFIT, SBENEFITCLAS) y uniones con BENEFITS_GROUP y BENEFITS_CATEGORY

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
  NMONEDA_ORIGEN,
  NTIPO_CAMBIO
)
WITH TasaCambioDolar AS (    
    SELECT   COALESCE(e.NEXCHANGE, 0) as TC_DOLAR,
             e.DEFFECDATE,   
             ROW_NUMBER() OVER(ORDER BY e.DEFFECDATE DESC)  as rn       
    FROM  EXCHANGE e 
    WHERE e.NCURRENCY = 2 -- Moneda dólar.
           AND e.DEFFECDATE <= SYSDATE -- La fecha de la tasa debe ser anterior o igual a la de emisión.
           AND (e.DNULLDATE IS NULL OR e.DNULLDATE > SYSDATE) -- La tasa debe estar vigente.
)
SELECT
  '514' AS SKEY,  -- Valor de llave
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
LEFT JOIN TABLE11 MNDA ON MF.ncurrency = MNDA.ncodigint
INNER JOIN TABLE8600 GAMV ON MB.STYPEBENEFIT = GAMV.STYPEBENEFIT 
INNER JOIN TABLE8601 GSUB ON MB.SBENEFITCLAS = GSUB.SBENEFITCLAS
INNER JOIN TABLE9 OFI ON TMED.NOFFICE = OFI.NOFFICE  -- Unión para obtener ciudad desde oficina (ajustar si NOFFICE no es el campo correcto)
LEFT JOIN TasaCambioDolar Tasa on tasa.rn=1

WHERE TMED.SDESCRIPT LIKE '%AMV%'  
  AND MF.DEFFECDATE <= SYSDATE
  AND (MF.DNULLDATE IS NULL OR MF.DNULLDATE > SYSDATE)
ORDER BY  MF.NIDMEDICALFEE,TMED.NOFFICE,MB.STYPEBENEFIT,MB.SBENEFITCLAS,MF.SBENEFITCODE ;