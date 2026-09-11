
WITH PolizaMoneda AS (
    -- CTE para obtener la moneda de la póliza 
    SELECT
        SCERTYPE, NBRANCH, NPRODUCT, NPOLICY, ncurrency,
        ROW_NUMBER() OVER(PARTITION BY SCERTYPE, NBRANCH, NPRODUCT, NPOLICY ORDER BY DNULLDATE) as rn
    FROM CURREN_POL
    WHERE dnulldate IS NULL
),
TasaCambioDolar AS (
    -- CTE para calcular el tipo de cambio para la moneda DÓLAR (2), reemplazando la función GETEXCHANGE.
    -- Se une POLICY con EXCHANGE para encontrar la tasa más reciente para cada póliza.
    SELECT   p.SCERTYPE, p.NBRANCH, p.NPRODUCT, p.NPOLICY,
             COALESCE(e.NEXCHANGE, 0) as TC_DOLAR,
        ROW_NUMBER() OVER(PARTITION BY p.SCERTYPE, p.NBRANCH, p.NPRODUCT, p.NPOLICY ORDER BY e.DEFFECDATE DESC) as rn
    FROM
        -- Se limita el escaneo de pólizas a las que se van a consultar.
        (SELECT SCERTYPE, NBRANCH, NPRODUCT, NPOLICY, DISSUEDAT FROM POLICY WHERE SCERTYPE = '2') p
    LEFT JOIN 
        EXCHANGE e ON e.NCURRENCY = 2 -- Moneda dólar.
                   AND e.DEFFECDATE <= p.DISSUEDAT -- La fecha de la tasa debe ser anterior o igual a la de emisión.
                   AND (e.DNULLDATE IS NULL OR e.DNULLDATE > p.DISSUEDAT) -- La tasa debe estar vigente.
),
cteIntermediario AS(
 SELECT COM.NPOLICY, COM.NBRANCH, COM.NPRODUCT 
 , COM.NINTERMED COD_INTERMEDIARIO , INITCAP(LOWER(TRIM(CLI.SCLIENAME))) NOMBRE 
 ,  TIPO.NINTERTYP AS COD_TIPOINTERMEDIARIO, INITCAP(LOWER(TRIM(TIPO.SDESCRIPT))) TIPO_INTERMEDIARIO 
 , ROW_NUMBER() OVER(PARTITION BY  COM.NBRANCH, COM.NPRODUCT, COM.NPOLICY, COM.NINTERTYP ORDER BY COM.DEFFECDATE DESC) as rn
 FROM COMMISSION COM
 INNER JOIN INTERMEDIA INT ON COM.NINTERMED= INT.NINTERMED
 INNER JOIN CLIENT CLI ON INT.SCLIENT= CLI.SCLIENT
 INNER JOIN INTERM_TYP TIPO ON COM.NINTERTYP= TIPO.NINTERTYP
 WHERE COM.SCERTYPE=2 AND COM.DNULLDATE IS NULL
), cteDatosPrimas as (
    SELECT
           CASE
               WHEN NVL(PRE.NCONTRAT,0) = 0
                   THEN 'SIN_CONTRATO'
               ELSE 'CON_CONTRATO'
           END AS TIPO_CONTRATO,
           PRE.NPOLICY,
           PRE.NBRANCH,
           PRE.NPRODUCT,
           DET.NBRANCH_LED,
           PRE.NINSUR_AREA,
           PRE.SCLIENT,
           PRE.NCURRENCY,
           PRE.NRECEIPT,
           PRE.NTRATYPEI,
           PMO.NTYPE,
           PMO.DLEDGERDAT,
           PMO.NTRANSAC,
           PRE.DEFFECDATE,
           PRE.DEXPIRDAT AS DEXPIRDAT_PRE,
           MAX(PRE.NEXCHANGE) AS NEXCHANGE,
           SUM(
               CASE
                   WHEN NVL(PRE.NCONTRAT,0) = 0 THEN 0
                   WHEN DET.STYPE_DETAI = '3'   THEN 0
                   WHEN PMO.NTYPE IN (7,8)      THEN NVL(DET.NPREMIUME,0) * -1
                   ELSE NVL(DET.NPREMIUME,0)
               END
           ) AS NP_EXENTA_MO,
           SUM(
               CASE
                   WHEN DET.STYPE_DETAI IN ('3','8') THEN 0
                   WHEN DET.STYPE_DETAI = '4' AND D.SROUTINE = 'ACCOUNT_MAIN' THEN 0
                   WHEN PMO.NTYPE IN (7,8) THEN NVL(DET.NPREMIUMA,0) * -1
                   ELSE NVL(DET.NPREMIUMA,0)
               END
           ) AS NP_NETA_MO,
           SUM(
               CASE
                   WHEN DET.SADDTAX = '1'
                   THEN
                       CASE
                           WHEN PMO.NTYPE IN (7,8) THEN NVL(DET.NTAXAMOUNT,0) * -1
                           ELSE NVL(DET.NTAXAMOUNT,0)
                       END
                   ELSE 0
                END
           ) AS NP_IVA_MO,

           SUM(
                (
                    CASE
                        WHEN DET.STYPE_DETAI = '3' THEN 0
                        WHEN DET.STYPE_DETAI = '4' AND D.SROUTINE = 'ACCOUNT_MAIN' THEN 0
                        ELSE DET.NPREMIUM + NVL(DET.NTAXAMOUNT,0)
                    END
                )
                *
                CASE
                    WHEN PMO.NTYPE IN (7,8) THEN -1
                    ELSE 1
                END
           ) AS NP_TOTAL_MO,

           SUM(
                CASE
                    WHEN PMO.NTYPE IN (7,8)
                         THEN NVL(DET.NCOMMISION,0) * -1
                    ELSE NVL(DET.NCOMMISION,0)
                END
           ) AS NC_DEV_MO

    FROM PREMIUM_MO PMO
         INNER JOIN PREMIUM PRE  ON PRE.SCERTYPE  = PMO.SCERTYPE
									AND PRE.NBRANCH   = PMO.NBRANCH	AND PRE.NPRODUCT  = PMO.NPRODUCT
									AND PRE.NRECEIPT  = PMO.NRECEIPT AND PRE.NDIGIT    = PMO.NDIGIT
									AND PRE.NPAYNUMBE = PMO.NPAYNUMBE
         INNER JOIN DETAIL_PRE DET ON DET.SCERTYPE  = PRE.SCERTYPE
									AND DET.NBRANCH   = PRE.NBRANCH AND DET.NPRODUCT  = PRE.NPRODUCT
									AND DET.NRECEIPT  = PRE.NRECEIPT AND DET.NDIGIT    = PRE.NDIGIT
									AND DET.NPAYNUMBE = PRE.NPAYNUMBE
         LEFT JOIN DISCO_EXPR D ON D.NBRANCH   = DET.NBRANCH
							AND D.NPRODUCT  = DET.NPRODUCT 	AND D.NDISEXPRC = DET.NDET_CODE
							AND D.DEFFECDATE <= DATE '2026-08-31'
							AND (
									D.DNULLDATE IS NULL
								 OR D.DNULLDATE > DATE '2026-08-31'
								)
    WHERE PMO.SCERTYPE = '2'
		  AND PMO.NDIGIT = 0
		  AND PRE.SSTATUSVA NOT IN ('2','3')
		  AND (	PMO.NTYPE IN (1,7,8,9)
				OR ( PMO.NTYPE = 10 AND PRE.NSTATUS_PRE NOT IN (8,10))
			  )
    GROUP BY
           CASE
               WHEN NVL(PRE.NCONTRAT,0) = 0
                   THEN 'SIN_CONTRATO'
               ELSE 'CON_CONTRATO'
           END,
           PRE.NPOLICY,PRE.NBRANCH,PRE.NPRODUCT,DET.NBRANCH_LED,
           PRE.NINSUR_AREA,PRE.SCLIENT, PRE.NCURRENCY, PRE.NRECEIPT,
           PRE.NTRATYPEI, PMO.NTYPE, PMO.DLEDGERDAT, PMO.NTRANSAC,
           PRE.DEFFECDATE, PRE.DEXPIRDAT
)
SELECT
      TRIM(tcer.sdescript) AS TipoCertificado
    , pol.SCertype
    , pol.nbranch
    , pol.nproduct
    , pol.npolicy
    , reg.noffice AS CodRegionalPoliza
    , TRIM(Reg.SDESCRIPT) AS RegionalPoliza
    , pol.NBranch AS CodRamo
    , TRIM(Ram.Sdescript) AS Ramo
    , pol.NProduct AS CodProducto
    , TRIM(Prod.SDescript) AS Producto
    -- El tipo de cambio (TC) depende de la moneda de la póliza.
    , CASE WHEN Moneda.ncodigint = 1 THEN 1 ELSE Tasa.TC_DOLAR END AS TC
    , lneg.sbrancht AS CodLineaNegocio
    , TRIM(LNeg.sdescript) AS LineaNegocio
    , cven.nsellchannel AS CodCanalVenta
    , TRIM(cven.sdescript) AS CanalVenta
    , CliCont.sClient AS CodContratante
    , INITCAP(LOWER(RTRIM(CliCont.sCliename))) AS Contratante
    , pol.NPolicy AS NroPoliza
    , epol.sstatusva AS CodEstadoPoliza
    , TRIM(EPol.sdescript) AS EstadoPoliza
    , Moneda.ncodigint AS CodMonedaPoliza
    , TRIM(moneda.sdescript) AS MonedaPoliza
    , pol.ncapital AS CapitalMO
    -- Capital en moneda local calculado con el TC correspondiente.
    , pol.ncapital * (CASE WHEN Moneda.ncodigint = 1 THEN 1 ELSE Tasa.TC_DOLAR END) AS CapitalML
    
    ,REAGENERALPKG.GETCAPITALCOVER('2', PR.NBRANCH, PR.NPRODUCT, PR.NPOLICY,PR.NCERTIF, 
                                        NVL(POL.SCLIENT, CliCont.sClient), TO_DATE('31/08/2026' , 'DD-MM-YYYY')) AS NCAPITAL_MO1
    ,GETBOOKPREMIUMS('2', PR.NBRANCH, PR.NPRODUCT, PR.NPOLICY, PR.NCERTIF,
                   PR.NRECEIPT, 0, 0, 9347, '6', TO_DATE('31/08/2026' , 'DD-MM-YYYY'), PR.DEFFECDATE) AS NMONTIT_MO1
    ,GETBOOKPREMIUMS('2', PR.NBRANCH, PR.NPRODUCT, PR.NPOLICY, PR.NCERTIF,
                   PR.NRECEIPT, 0, 0, 9347, '7', TO_DATE('31/08/2026' , 'DD-MM-YYYY'), PR.DEFFECDATE) AS NMONTAPS_MO1   ---9347 RAMO CONTABLE SALUD
       
    --, Pol.DISSUEDAT AS FechaEmision
    , PR.DISSUEDAT as FechaEmision
    , pol.DSTARTDATE AS InicioVigenciaPoliza
    , pol.DEXPIRDAT AS FinVigenciaPoliza
    , PR.DEFFECDATE as IVigenciaRecibo
    , PR.DEXPIRDAT as FVigenciaRecibo
    , PR.NPERIOD as NroRenovacion
    , CanCobro.nway_pay AS IdCanalCobroAsignado
    , TRIM(CanCobro.sDescript) AS CanalCobroAsignado
    , FPag.npayfreq AS CodFrecuenciaPago
    , TRIM(FPag.sDescript) AS FrecuenciaPago
    , CTE_INTE.COD_TIPOINTERMEDIARIO AS CodTipoIntermediario
    , CTE_INTE.TIPO_INTERMEDIARIO AS TipoIntermediario
    , CTE_INTE.COD_INTERMEDIARIO AS CodIntermediario
    , CTE_INTE.NOMBRE AS Intermediario
    , CTE_SUP.COD_INTERMEDIARIO AS codSupervisor
    , CTE_SUP.NOMBRE AS Supervisor
    , cert.Nbill_day AS DiadeCobro
    , TPol.sdescript AS TipoPoliza
    , TRIM(Prod.sshort_des) AS ProductoAbreviado
    , CASE pol.SPOLITYPE WHEN '1' THEN 'Póliza Individual' ELSE pol.SCOLINVOT || ' - ' || REAGENERALPKG.REACODIGINT('TABLE50', 'SCOLINVOT', pol.SCOLINVOT) END AS TipoFacturaColectivo
    , TRIM(pol.STYPDIS_PAYPERCEN || ' - ' || REAGENERALPKG.REACODIGINT('TABLE9235', 'STYPDIS_PAYPERCEN', pol.STYPDIS_PAYPERCEN)) AS TipoDistribucion

FROM (
       SELECT SCERTYPE, NBRANCH, NPRODUCT, NPOLICY, NCERTIF,
             NRECEIPT, NDIGIT, NPAYNUMBE, DISSUEDAT, NWAY_PAY,
             DEFFECDATE,DEXPIRDAT, NPERIOD, NCURRENCY
       FROM PREMIUM
       WHERE SCERTYPE  = '2'
         AND NDIGIT    = 0
         AND NPAYNUMBE = 0
       GROUP BY SCERTYPE, NBRANCH, NPRODUCT, NPOLICY, NCERTIF,
                NRECEIPT, NDIGIT, NPAYNUMBE, DISSUEDAT, NWAY_PAY,
                DEFFECDATE,DEXPIRDAT, NPERIOD, NCURRENCY
          ) PR
    INNER JOIN CERTIFICAT CERT  ON CERT.SCERTYPE = PR.SCERTYPE AND CERT.NBRANCH = PR.NBRANCH
                                     AND CERT.NPRODUCT = PR.NPRODUCT AND CERT.NPOLICY = PR.NPOLICY
                                     AND CERT.NCERTIF = PR.NCERTIF
    INNER JOIN POLICY POL   ON POL.SCERTYPE = PR.SCERTYPE AND POL.NBRANCH = PR.NBRANCH
                                AND POL.NPRODUCT = PR.NPRODUCT AND POL.NPOLICY = PR.NPOLICY
    INNER JOIN cteDatosPrimas ctePri on POL.NBRANCH = ctePri.NBRANCH AND POL.NPRODUCT = ctePri.NPRODUCT 
                                        AND POL.NPOLICY = ctePri.NPOLICY
    --INNER JOIN Certificat cert ON pol.scertype = Cert.scertype AND pol.Nbranch = Cert.NBranch AND pol.NProduct = Cert.NProduct AND pol.NPolicy = Cert.NPolicy AND cert.ncertif = 0
    INNER JOIN prodmaster Prod ON pol.NBranch = Prod.NBranch AND pol.NProduct = Prod.NProduct
    INNER JOIN ROLES Rol ON cert.Scertype = Rol.Scertype AND cert.NBranch = Rol.NBranch 
                            AND cert.Nproduct = Rol.Nproduct AND cert.NPolicy = Rol.NPolicy 
                            AND Rol.NRole = 1 AND rol.dnulldate IS NULL
    INNER JOIN Client CliCont ON Rol.sclient = CliCont.sclient
    INNER JOIN Table10 Ram ON pol.NBranch = Ram.NBranch
    INNER JOIN TABLE5002 CanCobro ON cert.nway_pay = CanCobro.nway_pay
    INNER JOIN TABLE9 Reg ON pol.noffice = reg.noffice
    INNER JOIN TABLE36 FPag ON cert.npayfreq = FPag.npayfreq
    INNER JOIN TABLE5532 CVen ON cert.nsellchannel = cven.nsellchannel
    INNER JOIN TABLE5632 TCer ON pol.scertype = tcer.scertype
    INNER JOIN TABLE181 EPol ON pol.Sstatus_Pol = Epol.Sstatusva
    INNER JOIN TABLE17 TPol ON pol.spolitype = TPol.ncodigint
    LEFT JOIN TABLE37 LNeg ON prod.sbrancht = lneg.sbrancht

    -- Se une primero para obtener la moneda de la póliza.
    LEFT JOIN PolizaMoneda pm ON pol.SCERTYPE = pm.SCERTYPE AND pol.NBRANCH = pm.NBRANCH AND pol.NPRODUCT = pm.NPRODUCT AND pol.NPOLICY = pm.NPOLICY AND pm.rn = 1
    LEFT JOIN TABLE11 Moneda ON pm.ncurrency = Moneda.ncodigint

    -- Se une al CTE que calcula el tipo de cambio para dólar. Se filtra por rn=1 para obtener solo la tasa más reciente.
    -- Se usa LEFT JOIN para no descartar pólizas en moneda local (que no tendrán tasa en dólar).
    LEFT JOIN TasaCambioDolar Tasa ON pol.SCERTYPE = Tasa.SCERTYPE AND pol.NBRANCH = Tasa.NBRANCH AND pol.NPRODUCT = Tasa.NPRODUCT AND pol.NPOLICY = Tasa.NPOLICY AND Tasa.rn = 1

    LEFT JOIN cteIntermediario CTE_INTE ON POL.NBRANCH=  CTE_INTE.NBRANCH AND POL.NPRODUCT = CTE_INTE.NPRODUCT AND POL.NPOLICY= CTE_INTE.NPOLICY AND CTE_INTE.COD_TIPOINTERMEDIARIO NOT IN (5) AND CTE_INTE.RN=1
    LEFT JOIN cteIntermediario CTE_SUP ON POL.NBRANCH=  CTE_SUP.NBRANCH AND POL.NPRODUCT = CTE_SUP.NPRODUCT AND POL.NPOLICY= CTE_SUP.NPOLICY AND CTE_SUP.COD_TIPOINTERMEDIARIO  IN (5) AND CTE_SUP.RN=1
     

WHERE
    pol.SCERTYPE = '2'
--    AND pol.npolicy = 7
    and pol.SSTATUS_POL NOT IN (2,3,7,8)
    -- SSTATUS_POL 6 = TERMINADA / ANULADA NO INGRESA PUESTO QUE LA VISTA MUESTRA TODAS LAS POLIZAS QUE SE EMITIERON, SIN IMPORTAR ESTADO ACTUAL
    and PR.DISSUEDAT BETWEEN TO_DATE('01/08/2026' , 'DD-MM-YYYY') AND TO_DATE('31/08/2026' , 'DD-MM-YYYY')
    order by pol.npolicy