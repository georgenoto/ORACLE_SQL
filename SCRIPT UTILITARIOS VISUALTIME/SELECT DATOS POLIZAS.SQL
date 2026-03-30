WITH PolizaMoneda AS (
    -- Subconsulta para obtener la moneda de la póliza de forma determinista,
    -- seleccionando la primera fila en caso de múltiples monedas.
    SELECT
        SCERTYPE, NBRANCH, NPRODUCT, NPOLICY, ncurrency,
        ROW_NUMBER() OVER(PARTITION BY SCERTYPE, NBRANCH, NPRODUCT, NPOLICY ORDER BY DNULLDATE) as rn
    FROM CURREN_POL
    WHERE dnulldate IS NULL
),
TasaCambioDolar AS (
    -- CTE para calcular el tipo de cambio para la moneda DÓLAR (2), reemplazando la función GETEXCHANGE.
    -- Se une POLICY con EXCHANGE para encontrar la tasa más reciente para cada póliza.
    SELECT
        p.SCERTYPE, p.NBRANCH, p.NPRODUCT, p.NPOLICY,
        -- Si no se encuentra tasa, se usa 0, replicando la lógica de la función.
        COALESCE(e.NEXCHANGE, 0) as TC_DOLAR,
        -- Se numera las filas para obtener solo la tasa más reciente (con fecha <= a la de emisión).
        ROW_NUMBER() OVER(PARTITION BY p.SCERTYPE, p.NBRANCH, p.NPRODUCT, p.NPOLICY ORDER BY e.DEFFECDATE DESC) as rn
    FROM
        -- Se limita el escaneo de pólizas a las que se van a consultar.
        (SELECT SCERTYPE, NBRANCH, NPRODUCT, NPOLICY, DISSUEDAT FROM POLICY WHERE SCERTYPE = '2') p
    LEFT JOIN
        EXCHANGE e ON e.NCURRENCY = 2 -- Moneda dólar.
                   AND e.DEFFECDATE <= p.DISSUEDAT -- La fecha de la tasa debe ser anterior o igual a la de emisión.
                   AND (e.DNULLDATE IS NULL OR e.DNULLDATE > p.DISSUEDAT) -- La tasa debe estar vigente.
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
    , Pol.DISSUEDAT AS FechaEmision
    , pol.DSTARTDATE AS InicioVigenciaPoliza
    , pol.DEXPIRDAT AS FinVigenciaPoliza
    , CanCobro.nway_pay AS IdCanalCobroAsignado
    , TRIM(CanCobro.sDescript) AS CanalCobroAsignado
    , FPag.npayfreq AS CodFrecuenciaPago
    , TRIM(FPag.sDescript) AS FrecuenciaPago
    , TInte.NINTERTYP AS CodTipoIntermediario
    , TRIM(TInte.sDescript) AS TipoIntermediario
    , Inte.NINTERMED AS CodIntermediario
    , INITCAP(LOWER(RTRIM(CliInte.sCliename))) AS Intermediario
    , cert.Nbill_day AS DiadeCobro
    , TPol.sdescript AS TipoPoliza
    , TRIM(Prod.sshort_des) AS ProductoAbreviado
    -- NOTA DE OPTIMIZACIÓN: La función REAGENERALPKG.REACODIGINT también se ejecuta por fila.
    -- Evaluar si puede ser sustituida por un JOIN.
    , CASE pol.SPOLITYPE WHEN '1' THEN 'Póliza Individual' ELSE pol.SCOLINVOT || ' - ' || REAGENERALPKG.REACODIGINT('TABLE50', 'SCOLINVOT', pol.SCOLINVOT) END AS TipoFacturaColectivo
    , TRIM(pol.STYPDIS_PAYPERCEN || ' - ' || REAGENERALPKG.REACODIGINT('TABLE9235', 'STYPDIS_PAYPERCEN', pol.STYPDIS_PAYPERCEN)) AS TipoDistribucion

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
    LEFT JOIN TABLE37 LNeg ON prod.sbrancht = lneg.sbrancht

    -- Se une primero para obtener la moneda de la póliza.
    LEFT JOIN PolizaMoneda pm ON pol.SCERTYPE = pm.SCERTYPE AND pol.NBRANCH = pm.NBRANCH AND pol.NPRODUCT = pm.NPRODUCT AND pol.NPOLICY = pm.NPOLICY AND pm.rn = 1
    LEFT JOIN TABLE11 Moneda ON pm.ncurrency = Moneda.ncodigint

    -- Se une al CTE que calcula el tipo de cambio para dólar. Se filtra por rn=1 para obtener solo la tasa más reciente.
    -- Se usa LEFT JOIN para no descartar pólizas en moneda local (que no tendrán tasa en dólar).
    LEFT JOIN TasaCambioDolar Tasa ON pol.SCERTYPE = Tasa.SCERTYPE AND pol.NBRANCH = Tasa.NBRANCH AND pol.NPRODUCT = Tasa.NPRODUCT AND pol.NPOLICY = Tasa.NPOLICY AND Tasa.rn = 1

    LEFT JOIN INTERMEDIA Inte ON pol.NINTERMED = Inte.NINTERMED
    LEFT JOIN Client CliInte ON Inte.sClient = CliInte.sClient
    LEFT JOIN INTERM_TYP TInte ON Inte.NINTERTYP = TInte.NINTERTYP

WHERE
    pol.SCERTYPE = '2'
    -- La condición "cert.ncertif=0" es redundante porque ya está en el INNER JOIN.
    -- El "ORDER BY" se ha eliminado de la vista; debe aplicarse en la consulta final.
    -- AND pol.npolicy = 28; -- Condición de prueba comentada.


