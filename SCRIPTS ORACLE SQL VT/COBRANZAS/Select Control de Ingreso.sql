SELECT
      VPol.SCertype
    , VPol.nbranch
    , VPol.nproduct
    , VPol.npolicy
    , pre.Nreceipt
    , 'Nacional Seguros Vida y Salud S.A' AS NombreEmpresa
    , '145776027'                        AS NitEmpresa
    , VPol.LineaNegocio
    , VPol.CanalVenta
    , VPol.Ramo
    , VPol.Producto
    , TRIM(VPol.CanalCobroAsignado)      AS CanalCobroAsignado
    , VPol.CodRegionalPoliza
    , VPol.RegionalPoliza
    , TRIM(suc.sdescript)                AS RegionalCobro
    , INITCAP(LOWER(RTRIM(CliCaja.sCliename))) AS Cajero
    , TRIM(MPag.sdescript)               AS CanalCobroRealizado
    , TO_DATE(PRE_MO.DLEDGERDAT, 'DD-MM-YYYY') AS FechaCobro
    , vpol.contratante                   AS Cliente
    , VPol.NroPoliza
    , TRIM(TCuo.sdescript)               AS TipoCuota
    , CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE cuo.Ndraft END AS NroCuota
    , CASE WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE cuo.dlimitdate END AS VencimientoDeCuota
    , CASE WHEN NVL(PRE_MO.NBILLNUM, 0) = 0 THEN 'Recibo' ELSE 'Factura' END AS TipoDocumento
    , NVL(PRE_MO.NBILLNUM, 0)            AS NroFactura
    , FCob.sdescript                     AS FormaCobroRealizado
    , NULL                               AS NroRelacionCompensacion
    , TO_CHAR(TRIM(VPol.CanalCobroAsignado)) || '- Poliza :' || TO_CHAR(TRIM(VPol.NroPoliza)) || ' ' || TO_CHAR(TRIM(CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE cuo.Ndraft END)) AS Concepto
    , Vpol.FrecuenciaPago                AS Perioricidad
    , bco.sdescript                      AS Banco
    , mcash.nvoucher                     AS CodigoTransaccion
    , mcash.sdocnumbe                    AS NroCheque
    , mcash.deffecdate                   AS FechaDeposito
    , ''                                 AS AdministradoraTarjeta
    , ''                                 AS NroTarjeta
    , VPol.MonedaPoliza
    , CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium, 0) ELSE cuo.namount END AS ImportePrimaPorCobrarMO
    , (CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium, 0) ELSE cuo.namount END) * NVL(PRE_MO.NEXCHANGE, 0) AS ImportePrimaPorCobrarML
    , NVL(PRE_MO.NAMOUNT, 0)             AS ImporteRecibidoMO
    , NVL(PRE_MO.NAMOUNT, 0) * NVL(PRE_MO.NEXCHANGE, 0) AS ImporteRecibidoML
    , 0                                  AS SaldoFavorMO
    , 0                                  AS SaldoFavorML
    , 0                                  AS RegularizacionSaldoMO
    , 0                                  AS RegularizacionSaldoML
    , NVL(PRE_MO.NEXCHANGE, 0)           AS TipoCambio
    , VPol.TipoIntermediario             AS TipoIntermediario
    , VPol.Intermediario                 AS Intermediario
    , pre.Ntype
    , pre.ncurrency                      AS CodMonedaTransaccion
    , mon.sdescript                      AS MonedaTransaccion
    , EstRec.sdescript                   AS EstadoRecibo
    , NULL                               AS FechaFacturaRecibo
    , 0                                  AS NroFacturaAnterior
    , ''                                 AS MonedaOriginalAnterior
FROM
    PREMIUM PRE
    INNER JOIN NS_View_DatosPolizas VPol ON PRE.SCERTYPE = VPol.SCERTYPE
                                        AND PRE.NBRANCH = VPol.NBRANCH
                                        AND PRE.NPRODUCT = VPol.NPRODUCT
                                        AND PRE.NPolicy = VPol.NPolicy
    INNER JOIN TABLE19 EstRec           ON pre.nstatus_pre = EstRec.nstatus_pre
    INNER JOIN Table11 Mon              ON pre.ncurrency = mon.ncodigint
    INNER JOIN TABLE24 TCuo             ON pre.NTRATYPEI = TCuo.NTRATYPEI
    INNER JOIN Table9 Suc               ON pre.noffice = suc.noffice
    LEFT JOIN PREMIUM_MO PRE_MO         ON PRE.SCERTYPE = PRE_MO.SCERTYPE
                                        AND PRE.NBRANCH = PRE_MO.NBRANCH
                                        AND PRE.NPRODUCT = PRE_MO.NPRODUCT
                                        AND PRE.NRECEIPT = PRE_MO.NRECEIPT
                                        AND PRE.NDIGIT = PRE_MO.NDIGIT
                                        AND PRE.NPAYNUMBE = PRE_MO.NPAYNUMBE
                                        AND PRE_MO.Ntype IN (2, 3, 13, 14, 21, 39, 40, 42) -- Abono,Financiamiento, Cargo a Cuenta Corriente
    LEFT JOIN Financ_dra Cuo            ON Pre.ncontrat = Cuo.ncontrat
    LEFT JOIN TABLE5002 MPag            ON PRE.nway_pay = MPag.nway_pay
    LEFT JOIN TABLE36 FPag              ON pre.npayfreq = FPag.npayfreq
    LEFT JOIN Table6 Tipo               ON PRE_MO.Ntype = tipo.ntype_tran
    LEFT JOIN Table182 FCob             ON PRE_MO.SPAY_FORM = FCob.SPAY_FORM
    LEFT JOIN USER_CASHNUM UCash        ON PRE_MO.NCASHNUM = UCash.NCASHNUM
    LEFT JOIN USERS UsrCaja             ON UCash.NUSER = UsrCaja.NUSERCODE
    LEFT JOIN CLIENT CliCaja            ON UsrCaja.SClient = CliCaja.SClient
    LEFT JOIN CASH_MOV mcash            ON pre_mo.nbordereaux = mcash.nbordereaux
    LEFT JOIN TABLE7 bco                ON mcash.nbank_code = bco.Nbank_code
WHERE
    pre.nstatus_pre IN (2, 5, 6, 7)