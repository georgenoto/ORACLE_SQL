
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
),
ctePremium as (
Select npolicy, dissuedat From premium Where  dnulldate is null and sstatusva in (4,5) and NTRATYPEI = 1 
),
cteReemion as (
select nproduct, npolicy, dcompdate, deffecdate, dledgerdat 
from policy_his where ntype_hist=5
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
    , pol.ncapital * (CASE WHEN Moneda.ncodigint = 1 THEN 1 ELSE Tasa.TC_DOLAR END) AS CapitalML
    , Pol.DISSUEDAT AS FechaEmision
    , pol.DSTARTDATE AS InicioVigenciaPoliza
    , pol.DEXPIRDAT AS FinVigenciaPoliza
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
    , cteR.dcompdate, cteR.deffecdate, cteR.dledgerdat
    , cteP.dissuedat FechaEmision_LibroProduccion
    
FROM
    POLICY pol
    INNER JOIN Certificat cert ON pol.scertype = Cert.scertype AND pol.Nbranch = Cert.NBranch AND pol.NProduct = Cert.NProduct AND pol.NPolicy = Cert.NPolicy AND cert.ncertif = 0
    INNER JOIN prodmaster Prod ON pol.NBranch = Prod.NBranch AND pol.NProduct = Prod.NProduct
    INNER JOIN ROLES Rol ON cert.Scertype = Rol.Scertype AND cert.NBranch = Rol.NBranch AND cert.Nproduct = Rol.Nproduct AND cert.NPolicy = Rol.NPolicy AND Rol.NRole = 1 AND rol.dnulldate IS NULL
    INNER JOIN Client CliCont ON Rol.sclient = CliCont.sclient
    INNER JOIN Table10 Ram ON pol.NBranch = Ram.NBranch
    INNER JOIN TABLE5002 CanCobro ON cert.nway_pay = CanCobro.nway_pay
    INNER JOIN TABLE9 Reg ON pol.noffice = reg.noffice
    INNER JOIN TABLE36 FPag ON cert.npayfreq = FPag.npayfreq
    INNER JOIN TABLE5532 CVen ON cert.nsellchannel = cven.nsellchannel
    INNER JOIN TABLE5632 TCer ON pol.scertype = tcer.scertype
    INNER JOIN TABLE181 EPol ON pol.Sstatus_Pol = Epol.Sstatusva
    INNER JOIN TABLE17 TPol ON pol.spolitype = TPol.ncodigint
    INNER JOIN ctePremium cteP on pol.npolicy = cteP.npolicy
    LEFT JOIN cteReemion cteR on pol.nproduct = cteR.nproduct and pol.npolicy= cteR.npolicy
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
    --AND pol.npolicy = 75
    and pol.SSTATUS_POL NOT IN (2,3,7,8);
    -- SSTATUS_POL 6 = TERMINADA / ANULADA NO INGRESA PUESTO QUE LA VISTA MUESTRA TODAS LAS POLIZAS QUE SE EMITIERON, SIN IMPORTAR ESTADO ACTUAL