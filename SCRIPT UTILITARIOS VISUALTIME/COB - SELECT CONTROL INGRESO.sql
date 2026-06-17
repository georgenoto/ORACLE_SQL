/*========================================================================
  CONSULTA: CONTROL DE INGRESO POR COBRANZAS
  OBJETIVO: Obtener detalle de todas las formas de pago y recibos 
            asociados a cada relación de compensación
  MODIFICADO: Optimización - Consolidación de CTEs duplicadas
========================================================================*/

WITH cteEmpresa AS (
    -- Datos generales de la empresa
    SELECT NVL(TRIM(CD.SCLINUMDOCU), '1028483024') AS NIT_EMPRESA
          ,TRIM(REAGENERALPKG.REANAMECLI(CD.SCLIENT)) AS NOMBRE_EMPRESA
          ,1 AS Id
    FROM COMPANY CM
    INNER JOIN CLIDOCUMENTS CD ON CM.SCLIENT = CD.SCLIENT
    WHERE CM.NCOMPANY = REAGENERALPKG.REAOPT_SYSTEM_COMPANY
)

,cteMonedaPoliza AS (
    -- Moneda actual de cada póliza (la más vigente)
    SELECT cpol.NBRANCH, cpol.NPRODUCT, cpol.NPOLICY, cpol.NCURRENCY
          ,ROW_NUMBER() OVER(PARTITION BY cpol.NBRANCH, cpol.NPRODUCT, cpol.NPOLICY 
                             ORDER BY cpol.DNULLDATE) AS rn
    FROM CURREN_POL cpol 
    WHERE cpol.DNULLDATE IS NULL AND cpol.SCERTYPE = 2
)

,cteFormasPago_Unificadas AS (
    -- ===== FORMAS DE PAGO: CASH_MOV (Movimientos en Caja) =====
    SELECT CF.nbordereaux, CM.Ncurrency, T11.sdescript AS MonedaTransaccion
          ,T78.sdescript AS FormaCobroRealizado
          ,NVL(CM.NAMOUNT, 0) AS ImporteRecibido
          ,CM.NORI_CURR AS CodMonedaOrigen
          ,CASE WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
                ELSE CASE WHEN CM.Ncurrency = 1
                          THEN NVL(CM.NAMOUNT, 0) / NVL(tblTC.TC, 0)
                          ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTC.TC, 0)
                     END
           END AS ImporteRecibidoMO
          ,CASE WHEN CM.Ncurrency = 1 THEN CM.NAMOUNT
                ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTC.TC, 0)
           END AS ImporteRecibidoLO
          ,CASE WHEN CM.nmov_type = 2 THEN TO_CHAR(CM.sdocnumbe) ELSE '' END AS NroCheque
          ,CASE WHEN CM.nmov_type IN (2,27,57) THEN CM.ddoc_date ELSE NULL END AS FechaDeposito
          ,CASE WHEN CM.nmov_type IN (27,57) THEN TO_CHAR(T78.sshort_des) ELSE '' END AS AdministradoraTarjeta
          ,CASE WHEN CM.nmov_type IN (27,57) THEN TO_CHAR(CM.sdocnumbe) ELSE '' END AS NroTarjeta
          ,T7.sdescript AS Banco
          ,CAST(NULL AS VARCHAR2(50)) AS NroCuenta
          ,CAST(NULL AS VARCHAR2(50)) AS CodigoTransaccion
          ,'CASH_MOV' AS TipoMovimiento
    FROM COLFORMREF CF
    INNER JOIN CASH_MOV CM ON CF.nbordereaux = CM.nbordereaux AND CF.NCASHNUM = CM.NCASHNUM
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT
                                   AND CF.NPOLICY = MON.NPOLICY AND MON.RN = 1
    LEFT JOIN TABLE11 T11 ON CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type = T78.nmov_type
    CROSS APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTC
    WHERE CM.nbordereaux IS NOT NULL AND CF.STYPE NOT IN (2)

    UNION ALL

    -- ===== FORMAS DE PAGO: BANK_MOV (Movimientos Bancarios) =====
    SELECT CF.nbordereaux, BM.Ncurrency, T11.sdescript AS MonedaTransaccion
          ,T296.sdescript AS FormaCobroRealizado
          ,NVL(BM.NCASH_AMOUN, 0) AS ImporteRecibido
          ,BM.NORI_CURR AS CodMonedaOrigen
          ,CASE WHEN MON.NCURRENCY = BM.Ncurrency THEN NVL(BM.NCASH_AMOUN, 0)
                ELSE CASE WHEN BM.Ncurrency = 1
                          THEN NVL(BM.NCASH_AMOUN, 0) / NVL(tblTC.TC, 0)
                          ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTC.TC, 0)
                     END
           END AS ImporteRecibidoMO
          ,CASE WHEN BM.Ncurrency = 1 THEN BM.NCASH_AMOUN
                ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTC.TC, 0)
           END AS ImporteRecibidoLO
          ,'' AS NroCheque
          ,CASE WHEN BM.nbordereaux IS NOT NULL THEN BM.ddoc_date ELSE NULL END AS FechaDeposito
          ,'' AS AdministradoraTarjeta
          ,'' AS NroTarjeta
          ,T7.sdescript AS Banco
          ,CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BA.SACC_NUMBER)) AS NroCuenta
          ,TO_CHAR(BM.sdep_number) AS CodigoTransaccion
          ,'BANK_MOV' AS TipoMovimiento
    FROM COLFORMREF CF
    INNER JOIN BANK_MOV BM ON CF.Nbordereaux = BM.Nbordereaux AND CF.NCASHNUM = BM.NCASHNUM
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT
                                   AND CF.NPOLICY = MON.NPOLICY AND MON.RN = 1
    INNER JOIN TABLE11 T11 ON BM.Ncurrency = T11.ncodigint
    LEFT JOIN BANK_ACC BA ON BM.NACC_BANK = BA.NACC_BANK
    LEFT JOIN TABLE7 T7 ON BA.NBANK_CODE = T7.NBANK_CODE
    LEFT JOIN TABLE296 T296 ON BM.NTYPE_MOV = T296.NTYPE_MOV
    CROSS APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTC
    WHERE BM.nbordereaux IS NOT NULL AND CF.STYPE NOT IN (2)

    UNION ALL

    -- ===== FORMAS DE PAGO: MOVE_ACC (Cargo a Cuenta Corriente) =====
    SELECT CF.nbordereaux, CM.Ncurrency, T11.sdescript AS MonedaTransaccion
          ,'Cargo cta.cte. cliente' AS FormaCobroRealizado
          ,ABS(NVL(CM.NAMOUNT, 0)) AS ImporteRecibido
          ,CM.NCURRENCY AS CodMonedaOrigen
          ,ABS(CASE WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
                    ELSE CASE WHEN CM.Ncurrency = 1
                              THEN NVL(CM.NAMOUNT, 0) / NVL(tblTC.TC, 0)
                              ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTC.TC, 0)
                         END
               END) AS ImporteRecibidoMO
          ,ABS(CASE WHEN CM.Ncurrency = 1 THEN CM.NAMOUNT
                    ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTC.TC, 0)
               END) AS ImporteRecibidoLO
          ,NULL AS NroCheque
          ,NULL AS FechaDeposito
          ,NULL AS AdministradoraTarjeta
          ,NULL AS NroTarjeta
          ,NULL AS Banco
          ,NULL AS NroCuenta
          ,NULL AS CodigoTransaccion
          ,'MOVE_ACC' AS TipoMovimiento
    FROM COLFORMREF CF
    INNER JOIN MOVE_ACC CM ON CF.nbordereaux = CM.nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT
                                   AND CF.NPOLICY = MON.NPOLICY AND MON.RN = 1
    LEFT JOIN TABLE11 T11 ON CM.Ncurrency = T11.ncodigint
    CROSS APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTC
    WHERE CM.nbordereaux IS NOT NULL AND CF.STYPE NOT IN (2)

    UNION ALL

    -- ===== FORMAS DE PAGO: CONCEPTOS ADICIONALES (RELCONCEPTS) =====
    SELECT CF.nbordereaux, CM.Ncurrency, T11.sdescript AS MonedaTransaccion
          ,T78.sdescript AS FormaCobroRealizado
          ,NVL(CM.NAMOUNT, 0) AS ImporteRecibido
          ,CM.NORI_CURR AS CodMonedaOrigen
          ,CASE WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
                ELSE CASE WHEN CM.Ncurrency = 1
                          THEN NVL(CM.NAMOUNT, 0) / NVL(tblTC.TC, 0)
                          ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTC.TC, 0)
                     END
           END AS ImporteRecibidoMO
          ,CASE WHEN CM.Ncurrency = 1 THEN CM.NAMOUNT
                ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTC.TC, 0)
           END AS ImporteRecibidoLO
          ,CASE WHEN CM.nmov_type = 2 THEN TO_CHAR(CM.sdocnumbe) ELSE '' END AS NroCheque
          ,CASE WHEN CM.nmov_type IN (2,27,57) THEN CM.ddoc_date ELSE NULL END AS FechaDeposito
          ,CASE WHEN CM.nmov_type IN (27,57) THEN TO_CHAR(T78.sshort_des) ELSE '' END AS AdministradoraTarjeta
          ,CASE WHEN CM.nmov_type IN (27,57) THEN TO_CHAR(CM.sdocnumbe) ELSE '' END AS NroTarjeta
          ,T7.sdescript AS Banco
          ,'' AS NroCuenta
          ,'' AS CodigoTransaccion
          ,'CASH_MOV_RELCONCEPTS' AS TipoMovimiento
    FROM COLFORMREF CF
    INNER JOIN CASH_MOV CM ON CF.nbordereaux = CM.nbordereaux
    INNER JOIN RELCONCEPTS RCON ON CF.NBORDEREAUX = RCON.NBORDEREAUX
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT AND RCON.NPOLICY = MON.NPOLICY AND MON.RN = 1
    LEFT JOIN TABLE11 T11 ON CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type = T78.nmov_type
    CROSS APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTC
    WHERE CM.nbordereaux IS NOT NULL AND CF.STYPE NOT IN (2) AND CM.nbordereaux = 159

    UNION ALL

    -- ===== FORMAS DE PAGO: BANK_MOV + RELCONCEPTS =====
    SELECT CF.nbordereaux, BM.Ncurrency, T11.sdescript AS MonedaTransaccion
          ,T296.sdescript AS FormaCobroRealizado
          ,NVL(BM.NCASH_AMOUN, 0) AS ImporteRecibido
          ,BM.NORI_CURR AS CodMonedaOrigen
          ,CASE WHEN MON.NCURRENCY = BM.Ncurrency THEN NVL(BM.NCASH_AMOUN, 0)
                ELSE CASE WHEN BM.Ncurrency = 1
                          THEN NVL(BM.NCASH_AMOUN, 0) / NVL(tblTC.TC, 0)
                          ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTC.TC, 0)
                     END
           END AS ImporteRecibidoMO
          ,CASE WHEN BM.Ncurrency = 1 THEN BM.NCASH_AMOUN
                ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTC.TC, 0)
           END AS ImporteRecibidoLO
          ,'' AS NroCheque
          ,CASE WHEN BM.nbordereaux IS NOT NULL THEN BM.ddoc_date ELSE NULL END AS FechaDeposito
          ,'' AS AdministradoraTarjeta
          ,'' AS NroTarjeta
          ,T7.sdescript AS Banco
          ,CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BA.SACC_NUMBER)) AS NroCuenta
          ,TO_CHAR(BM.sdep_number) AS CodigoTransaccion
          ,'BANK_MOV_RELCONCEPTS' AS TipoMovimiento
    FROM COLFORMREF CF
    INNER JOIN BANK_MOV BM ON CF.Nbordereaux = BM.Nbordereaux
    INNER JOIN RELCONCEPTS RCON ON CF.NBORDEREAUX = RCON.NBORDEREAUX
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT AND RCON.NPOLICY = MON.NPOLICY AND MON.RN = 1
    INNER JOIN TABLE11 T11 ON BM.Ncurrency = T11.ncodigint
    LEFT JOIN BANK_ACC BA ON BM.NACC_BANK = BA.NACC_BANK
    LEFT JOIN TABLE7 T7 ON BA.NBANK_CODE = T7.NBANK_CODE
    LEFT JOIN TABLE296 T296 ON BM.NTYPE_MOV = T296.NTYPE_MOV
    CROSS APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTC
    WHERE BM.nbordereaux IS NOT NULL AND CF.STYPE NOT IN (2) AND BM.nbordereaux = 159
) 
---cteFacturas_EnRelacion, se agrupan las facturas que participan en la relacion
,cteFacturas_EnRelacion AS (
    -- ===== FACTURAS EN RELACION: Desde PREMIUM_MO (Recibos/Facturas regulares) =====
    SELECT CF1.Nbordereaux
          ,LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum,'')), ', ' ON OVERFLOW TRUNCATE) 
              WITHIN GROUP(ORDER BY F1.NBillnum) AS FacturasEnRelacion
          ,MAX(DECODE(NVL(F1.NBILLNUM,0), 0, 'Recibo', 
               DECODE(NVL(tblFA.NBILLNUM, 0), 0, 'Factura', 'Factura Anticipada'))) AS TipoDocumento
          ,MAX(NVL(tblCambioDeFactura.FechaCambioFact, NULL)) AS FechaFacturaAnterior
          ,MAX(NVL(tblCambioDeFactura.NroFactAnterior, NULL)) AS NroFacturaAnterior
    FROM COLFORMREF CF1
    INNER JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux
    LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux
    OUTER APPLY (
        SELECT PO_AUX2.NBILLNUM 
        FROM PREMIUM_MO PO_AUX2 
        WHERE PO_AUX2.nreceipt = PO_AUX.nreceipt 
          AND PO_AUX2.NBILLNUM = PO_AUX.NBILLNUM 
          AND PO_AUX2.NTYPE = 42 -- Factura Anticipada
          AND NVL(PO_AUX2.NNULLCODE, 0) = 0
    ) tblFA
    OUTER APPLY (
        SELECT B1.NBILLNUM AS NroFactAnterior
              ,B1.dcompdate AS FechaCambioFact
        FROM BILLS B1
        WHERE B1.NBordereaux = CF1.Nbordereaux
          AND B1.Nbillstat = 2 -- Anulado
          AND B1.Nnullcode = 11 -- Cambio de Factura
    ) tblCambioDeFactura
    WHERE NVL(PO_AUX.NNULLCODE, 0) = 0 
      AND F1.Nbillstat NOT IN (2) -- No Anulado
    GROUP BY CF1.Nbordereaux

    UNION ALL

    -- ===== FACTURAS EN RELACION: Desde RELCONCEPTS (Conceptos adicionales) =====
    SELECT CF1.Nbordereaux
          ,LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum,'')), ', ' ON OVERFLOW TRUNCATE) 
              WITHIN GROUP(ORDER BY F1.NBillnum) AS FacturasEnRelacion
          ,MAX(DECODE(NVL(F1.NBILLNUM, 0), 0, 'Recibo', 'Factura')) AS TipoDocumento
          ,NULL AS FechaFacturaAnterior
          ,NULL AS NroFacturaAnterior
    FROM COLFORMREF CF1
    INNER JOIN RELCONCEPTS CON ON CF1.NBORDEREAUX = CON.NBORDEREAUX
    LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux
    WHERE F1.Nbillstat NOT IN (2) -- No Anulado
    GROUP BY CF1.Nbordereaux
) 
---cteRecibos_EnRelacion, se agrupan los recibos que participan en la relacion
,cteRecibos_EnRelacion AS (
    -- Agrupación de recibos que participan en cada relación de compensación
    SELECT CF1.Nbordereaux
          ,LISTAGG(DISTINCT TO_CHAR(NVL(PO_AUX.Nreceipt,'')), ', ' ON OVERFLOW TRUNCATE) 
              WITHIN GROUP(ORDER BY PO_AUX.Nreceipt) AS RecibosEnRelacion
          ,COUNT(PO_AUX.Nreceipt) AS cantRecibos
    FROM COLFORMREF CF1
    INNER JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux
    WHERE NVL(PO_AUX.NNULLCODE, 0) = 0
    GROUP BY CF1.Nbordereaux
)  

--cteDatosRecibo: Unifica datos de recibos/cuotas de diferentes fuentes
, cteDatosRecibo AS (
    -- ===== OPCION 1: Datos de PREMIUM_MO (Recibos regulares y financiamientos) =====
    SELECT CF3.Nbordereaux
          ,TRIM(P.Nreceipt) AS Nreceipt
          ,TRIM(P.NPeriod) AS NroCuota
          ,P.dlimitdate AS FechaVencimiento
          ,ROUND(NVL(P.npremium, 0), 2) AS ImporteCuota
          ,DECODE(NVL(PO.NBILLNUM, 0), 0, TRIM(cteFRel.FacturasEnRelacion), TRIM(PO.NBILLNUM)) AS NroFactura
          ,NVL(cteFRel.FechaFacturaAnterior, NULL) AS FechaFacturaAnterior
          ,NVL(cteFRel.NroFacturaAnterior, 0) AS NroFacturaAnterior
          ,UCash.NCASHNUM AS NCASHNUM
          ,INITCAP(LOWER(RTRIM(CliCaja.scliename))) AS Cajero
          ,EstRec.sdescript AS EstadoRecibo
          ,CASE P.NTRATYPEI
               WHEN 1 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento', 'Cuota Regular')
               WHEN 2 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento', 'Cuota Regular')
               WHEN 3 THEN 'Anexo'
               WHEN 4 THEN 'Anexo de resicion de contrato'
               WHEN 9 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento', 'Cuota Regular')
               WHEN 12 THEN 'Anexo de rehabilitacion'
               ELSE TRIM(TCuo.sdescript)
           END AS TipoCuota
          ,TRIM(MPag.sdescript) AS CanalCobroRealizado
          ,TO_CHAR(TRIM(P.NPeriod)) AS NPeriodo
          ,P.Ntype AS Ntype
          ,TRIM(cteFRel.TipoDocumento) AS TipoDocumento
          ,TRIM(cteRRel.RecibosEnRelacion) AS RecibosEnRelacion
          ,TRIM(cteFRel.FacturasEnRelacion) AS FacturasEnRelacion
          ,'PREMIUM_MO' AS SourceType
    FROM COLFORMREF CF3
    INNER JOIN PREMIUM_MO PO ON CF3.Nbordereaux = PO.Nbordereaux
    INNER JOIN PREMIUM P ON PO.SCERTYPE = P.SCERTYPE AND PO.NBRANCH = P.NBRANCH
                        AND PO.NPRODUCT = P.NPRODUCT AND PO.NRECEIPT = P.NRECEIPT
                        AND PO.NDIGIT = P.NDIGIT AND PO.NPAYNUMBE = P.NPAYNUMBE
    INNER JOIN cteRecibos_EnRelacion cteRRel ON CF3.Nbordereaux = cteRRel.Nbordereaux
    INNER JOIN cteFacturas_EnRelacion cteFRel ON CF3.Nbordereaux = cteFRel.Nbordereaux
    INNER JOIN TABLE19 EstRec ON P.nstatus_pre = EstRec.nstatus_pre
    INNER JOIN TABLE24 TCuo ON P.NTRATYPEI = TCuo.NTRATYPEI
    LEFT JOIN USER_CASHNUM UCash ON CF3.NCASHNUM = UCash.NCASHNUM
    LEFT JOIN USERS UsrCaja ON UCash.NUSER = UsrCaja.NUSERCODE
    LEFT JOIN CLIENT CliCaja ON UsrCaja.SClient = CliCaja.SClient
    LEFT JOIN TABLE5002 MPag ON P.nway_pay = MPag.nway_pay
    WHERE PO.Ntype IN (2, 13, 14, 21, 39, 40) -- Excluye 42 (Factura Anticipada) y 3 (Devolución)
      AND P.nstatus_pre IN (2, 5, 6, 7)
      AND NVL(CF3.nnullcode, 0) = 0
      AND CF3.STYPE NOT IN (2)

    UNION ALL

    -- ===== OPCION 2: Datos de FINANC_DRA (Cuotas de financiamiento) =====
    SELECT CF2.Nbordereaux
          ,TRIM(PRE.Nreceipt) AS Nreceipt
          ,TRIM(FDRA.Ndraft) AS NroCuota
          ,FDRA.dlimitdate AS FechaVencimiento
          ,ROUND(FDRA.namount, 2) AS ImporteCuota
          ,TRIM(fact.NBILLNUM) AS NroFactura
          ,NVL(fact.DISSUEDAT, NULL) AS FechaFacturaAnterior
          ,NVL(fact.NPREVBILL, 0) AS NroFacturaAnterior
          ,UCash.NCASHNUM AS NCASHNUM
          ,INITCAP(LOWER(RTRIM(CliCaja.scliename))) AS Cajero
          ,EstRec.sdescript AS EstadoRecibo
          ,CASE PRE.NTRATYPEI
               WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento', 'Cuota Regular')
               WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento', 'Cuota Regular')
               WHEN 3 THEN 'Anexo'
               WHEN 4 THEN 'Anexo de resicion de contrato'
               WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento', 'Cuota Regular')
               WHEN 12 THEN 'Anexo de rehabilitacion'
               ELSE TRIM(TCuo.sdescript)
           END AS TipoCuota
          ,TRIM(MPag.sdescript) AS CanalCobroRealizado
          ,TO_CHAR(TRIM(PRE.NPeriod)) AS NPeriodo
          ,PRE.Ntype AS Ntype
          ,DECODE(NVL(fact.NBILLNUM, 0), 0, 'Recibo', 
               DECODE(NVL(tblFA.NBILLNUM, 0), 0, 'Factura', 'Factura Anticipada')) AS TipoDocumento
          ,TRIM(PRE.Nreceipt) AS RecibosEnRelacion
          ,TRIM(fact.NBILLNUM) AS FacturasEnRelacion
          ,'FINANC_DRA' AS SourceType
    FROM COLFORMREF CF2
    INNER JOIN FINANC_DRA FDRA ON CF2.NBordereaux = FDRA.NBordereaux
    INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat = DRA_HIS.ncontrat
                                   AND FDRA.NDRAFT = DRA_HIS.NDRAFT
                                   AND DRA_HIS.Ntype = 2
    INNER JOIN PREMIUM PRE ON FDRA.ncontrat = PRE.ncontrat
    INNER JOIN TABLE19 EstRec ON PRE.nstatus_pre = EstRec.nstatus_pre
    INNER JOIN TABLE24 TCuo ON PRE.NTRATYPEI = TCuo.NTRATYPEI
    LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux
    LEFT JOIN USER_CASHNUM UCash ON CF2.NCASHNUM = UCash.NCASHNUM
    LEFT JOIN USERS UsrCaja ON UCash.NUSER = UsrCaja.NUSERCODE
    LEFT JOIN CLIENT CliCaja ON UsrCaja.SClient = CliCaja.SClient
    LEFT JOIN TABLE5002 MPag ON PRE.nway_pay = MPag.nway_pay
    OUTER APPLY (
        SELECT DRA_HIS2.NBILLNUM 
        FROM DRAFT_HIST DRA_HIS2 
        WHERE FDRA.ncontrat = DRA_HIS2.ncontrat
          AND FDRA.NDRAFT = DRA_HIS2.NDRAFT
          AND DRA_HIS2.Ntype = 42 -- Factura Anticipada
    ) tblFA
    WHERE PRE.nstatus_pre = 8 -- Estado Financiamiento
      AND CF2.STYPE NOT IN (2)
      AND fact.Nbillstat NOT IN (2) -- No Anulado

    UNION ALL

    -- ===== OPCION 3: Datos de RELCONCEPTS (Conceptos adicionales) =====
    SELECT CF3.Nbordereaux
          ,'0' AS Nreceipt
          ,TRIM(RCON.NTRANSAC) AS NroCuota
          ,RCON.DVALDATE AS FechaVencimiento
          ,ROUND(NVL(RCON.NAMOUNT, 0), 2) AS ImporteCuota
          ,TRIM(fact.NBILLNUM) AS NroFactura
          ,NVL(cteFRel.FechaFacturaAnterior, NULL) AS FechaFacturaAnterior
          ,NVL(cteFRel.NroFacturaAnterior, 0) AS NroFacturaAnterior
          ,UCash.NCASHNUM AS NCASHNUM
          ,INITCAP(LOWER(RTRIM(CliCaja.scliename))) AS Cajero
          ,CASE WHEN CF3.SSTATUS = 1 THEN 'Pagado' ELSE 'Inactivo' END AS EstadoRecibo
          ,TRIM(TCuo.SDESCRIPT) AS TipoCuota
          ,TRIM(CPag.SDESCRIPT) AS CanalCobroRealizado
          ,TO_CHAR(TRIM(RCON.NTRANSAC)) AS NPeriodo
          ,1 AS Ntype
          ,TRIM(cteFRel.TipoDocumento) AS TipoDocumento
          ,TRIM(cteRRel.RecibosEnRelacion) AS RecibosEnRelacion
          ,TRIM(cteFRel.FacturasEnRelacion) AS FacturasEnRelacion
          ,'RELCONCEPTS' AS SourceType
    FROM COLFORMREF CF3
    INNER JOIN RELCONCEPTS RCON ON CF3.Nbordereaux = RCON.Nbordereaux
    LEFT JOIN cteRecibos_EnRelacion cteRRel ON CF3.Nbordereaux = cteRRel.Nbordereaux
    LEFT JOIN cteFacturas_EnRelacion cteFRel ON CF3.Nbordereaux = cteFRel.Nbordereaux
    INNER JOIN TABLE22 TCuo ON RCON.NCONCEPT = TCuo.NCONCEPT
    INNER JOIN BILLS fact ON CF3.NBordereaux = fact.NBordereaux
    LEFT JOIN USER_CASHNUM UCash ON CF3.NCASHNUM = UCash.NCASHNUM
    LEFT JOIN USERS UsrCaja ON UCash.NUSER = UsrCaja.NUSERCODE
    LEFT JOIN CLIENT CliCaja ON UsrCaja.SClient = CliCaja.SClient
    LEFT JOIN TABLE5554 CPag ON CF3.NINPUTTYP = CPag.NINPUTTYP
    WHERE NVL(CF3.nnullcode, 0) = 0
      AND CF3.STYPE NOT IN (2)
) 
--cteContadores: Contadores de formas de pago y recibos por relación
,cteContadores AS (
    SELECT cref.NBordereaux
          ,COUNT(DISTINCT CASE WHEN fpago.nbordereaux IS NOT NULL THEN fpago.nbordereaux END) AS cantFPago
          ,COUNT(DISTINCT CASE WHEN drec.nbordereaux IS NOT NULL THEN drec.nbordereaux END) AS cantRec
    FROM COLFORMREF cref
    LEFT JOIN cteFormasPago_Unificadas fpago ON cref.NBordereaux = fpago.NBordereaux
    LEFT JOIN cteDatosRecibo drec ON cref.NBordereaux = drec.NBordereaux
    WHERE NVL(cref.NNULLCODE, 0) = 0
    GROUP BY cref.NBordereaux
)
-- cteDatosReciboAgrupado: Detalle completo con formas de pago y recibos
, cteDatosReciboAgrupado AS (
    -- ===== CASO 1: Una forma de pago con uno o varios recibos =====
    SELECT cterc.NBordereaux, cterc.NReceipt, cterc.NroCuota, cterc.FechaVencimiento, cterc.ImporteCuota
          ,cterc.NroFactura, cterc.FechaFacturaAnterior, cterc.NroFacturaAnterior, cterc.NCashnum, cterc.Cajero
          ,cterc.EstadoRecibo, cterc.TipoCuota, cterc.CanalCobroRealizado, cterc.Nperiodo, cterc.Ntype
          ,cterc.TipoDocumento, cterc.NReceipt AS RecibosEnRelacion, cterc.NroFactura AS FacturasEnRelacion
          ,cteFormaPago.FormaCobroRealizado, cteFormaPago.Banco, cteFormaPago.NroCuenta
          ,cteFormaPago.CodigoTransaccion, cteFormaPago.NroCheque, cteFormaPago.FechaDeposito
          ,cteFormaPago.AdministradoraTarjeta, cteFormaPago.NroTarjeta
          ,cteFormaPago.ImporteRecibidoMO, (cteFormaPago.ImporteRecibidoMO * nexchange) AS ImporteRecibidoML
          ,cteFormaPago.ncurrency AS CodMonedaTransaccion, cteFormaPago.MonedaTransaccion
          ,cteFormaPago.ImporteRecibido AS ImporteTotalRecibido
          ,CASE WHEN ABS(ROUND(cterc.ImporteCuota, 2) - ROUND(cteFormaPago.ImporteRecibidoMO, 2)) > 0.5
                THEN ABS(ROUND(cterc.ImporteCuota, 2) - ROUND(cteFormaPago.ImporteRecibidoMO, 2))
                ELSE 0 
           END AS SaldoFavorMO
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormasPago_Unificadas cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    INNER JOIN TRELDOC tdoc ON cterc.NBordereaux = tdoc.NBordereaux AND cterc.NReceipt = tdoc.NReceipt
    CROSS APPLY (SELECT 1 AS nexchange FROM dual) xe -- Ajustar según lógica real de tipo de cambio
    WHERE (cteaux.cantFPago = 1 AND cteaux.cantRec >= 1)
       OR (cteaux.cantFPago > 1 AND cteaux.cantRec = 1)

    UNION ALL

    -- ===== CASO 2: Múltiples formas de pago Y múltiples recibos (Agrupado) =====
    SELECT cterc.NBordereaux
          ,LISTAGG(DISTINCT TRIM(cterc.NReceipt), ', ') WITHIN GROUP(ORDER BY cterc.NReceipt) AS Nreceipt
          ,LISTAGG(DISTINCT TRIM(cterc.NroCuota), ', ') WITHIN GROUP(ORDER BY cterc.NroCuota) AS NroCuota
          ,MAX(cterc.FechaVencimiento) AS FechaVencimiento
          ,SUM(cterc.ImporteCuota) AS ImporteCuota
          ,LISTAGG(DISTINCT TRIM(cterc.NroFactura), ', ') WITHIN GROUP(ORDER BY cterc.NroFactura) AS NroFactura
          ,MAX(cterc.FechaFacturaAnterior) AS FechaFacturaAnterior
          ,MAX(cterc.NroFacturaAnterior) AS NroFacturaAnterior
          ,MAX(cterc.NCashnum) AS NCashnum
          ,MAX(cterc.Cajero) AS Cajero
          ,MAX(cterc.EstadoRecibo) AS EstadoRecibo
          ,MAX(cterc.TipoCuota) AS TipoCuota
          ,MAX(cterc.CanalCobroRealizado) AS CanalCobroRealizado
          ,MAX(cterc.Nperiodo) AS Nperiodo
          ,MAX(cterc.Ntype) AS Ntype
          ,MAX(cterc.TipoDocumento) AS TipoDocumento
          ,MAX(cterc.RecibosEnRelacion) AS RecibosEnRelacion
          ,MAX(cterc.FacturasEnRelacion) AS FacturasEnRelacion -- Se repite intencionalmente
          ,cteFormaPago.FormaCobroRealizado
          ,MAX(cteFormaPago.Banco) AS Banco
          ,MAX(cteFormaPago.NroCuenta) AS NroCuenta
          ,MAX(cteFormaPago.CodigoTransaccion) AS CodigoTransaccion
          ,MAX(cteFormaPago.NroCheque) AS NroCheque
          ,MAX(cteFormaPago.FechaDeposito) AS FechaDeposito
          ,MAX(cteFormaPago.AdministradoraTarjeta) AS AdministradoraTarjeta
          ,MAX(cteFormaPago.NroTarjeta) AS NroTarjeta
          ,MAX(cteFormaPago.ImporteRecibidoMO) AS ImporteRecibidoMO
          ,MAX(cteFormaPago.ImporteRecibidoLO) AS ImporteRecibidoML
          ,MAX(cteFormaPago.ncurrency) AS CodMonedaTransaccion
          ,MAX(cteFormaPago.MonedaTransaccion) AS MonedaTransaccion
          ,MAX(cteFormaPago.ImporteRecibido) AS ImporteTotalRecibido
          ,0 AS SaldoFavorMO
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormasPago_Unificadas cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    WHERE cteaux.cantFPago > 1 AND cteaux.cantRec > 1
    GROUP BY cterc.NBordereaux, cteFormaPago.FormaCobroRealizado

    UNION ALL

    -- ===== CASO 3: Conceptos adicionales (RELCONCEPTS) =====
    SELECT cterc.NBordereaux, cterc.NReceipt, cterc.NroCuota, cterc.FechaVencimiento, cterc.ImporteCuota
          ,cterc.NroFactura, cterc.FechaFacturaAnterior, cterc.NroFacturaAnterior, cterc.NCashnum, cterc.Cajero
          ,cterc.EstadoRecibo, cterc.TipoCuota, cterc.CanalCobroRealizado, cterc.Nperiodo, cterc.Ntype
          ,cterc.TipoDocumento, cterc.NReceipt AS RecibosEnRelacion, cterc.NroFactura AS FacturasEnRelacion
          ,cteFormaPago.FormaCobroRealizado, cteFormaPago.Banco, cteFormaPago.NroCuenta
          ,cteFormaPago.CodigoTransaccion, cteFormaPago.NroCheque, cteFormaPago.FechaDeposito
          ,cteFormaPago.AdministradoraTarjeta, cteFormaPago.NroTarjeta
          ,cteFormaPago.ImporteRecibidoMO AS ImporteRecibidoMO
          ,cteFormaPago.ImporteRecibidoLO AS ImporteRecibidoML
          ,cteFormaPago.ncurrency AS CodMonedaTransaccion
          ,cteFormaPago.MonedaTransaccion
          ,cteFormaPago.ImporteRecibido AS ImporteTotalRecibido
          ,0 AS SaldoFavorMO
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormasPago_Unificadas cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    INNER JOIN RELCONCEPTS RCon ON cterc.NBordereaux = RCon.NBordereaux
    WHERE (cteaux.cantFPago = 1 AND cteaux.cantRec >= 1)
       OR (cteaux.cantFPago > 1 AND cteaux.cantRec = 1)
)
/* ========================================================================
   SELECT FINAL: REPORTE DE CONTROL DE INGRESO 
   ======================================================================== */
SELECT 
    VPOL.ID AS SKEY
   ,VPOL.SCertype
   ,VPOL.nbranch
   ,VPOL.nproduct
   ,TO_CHAR(VPOL.npolicy) AS NPOLICY
   ,Vpol.FrecuenciaPago
   ,TO_CHAR(cteRCob.RecibosEnRelacion) AS NRECEIPT
   ,cteEmpresa.NOMBRE_EMPRESA AS NombreEmpresa
   ,TO_CHAR(cteEmpresa.NIT_EMPRESA) AS NitEmpresa
   ,VPOL.LineaNegocio
   ,VPOL.CanalVenta
   ,VPOL.Ramo
   ,TO_CHAR(VPOL.nproduct) || '-' || VPOL.Producto AS Producto
   ,TRIM(VPOL.CanalCobroAsignado) AS CanalCobroAsignado
   ,VPOL.CodRegionalPoliza
   ,VPOL.RegionalPoliza
   ,suc.noffice AS CodRegionalTransaccion
   ,TRIM(suc.sdescript) AS RegionalCobro
   ,cteRCob.NCASHNUM AS CodCajero
   ,cteRCob.Cajero
   ,cteRCob.CanalCobroRealizado
   ,CREF.DCollect AS FechaCobro
   ,vpol.contratante AS Cliente
   ,cteRCob.TipoCuota
   ,TO_CHAR(cteRCob.NroCuota) AS NroCuota
   ,cteRCob.FechaVencimiento
   ,cteRCob.TipoDocumento
   ,TO_CHAR(cteRCob.FacturasEnRelacion) AS NroFactura
   ,cteRCob.FormaCobroRealizado
   ,TO_CHAR(CREF.NBordereaux) AS NroRelacionCompensacion
   ,'Producto:' || VPOL.Producto || ' | Nro. Poliza:' || TO_CHAR(TRIM(VPOL.NroPoliza)) 
    || ' | Tipo Cuota:' || TO_CHAR(cteRCob.TipoCuota) || ' | Nro. Cuota: ' || TO_CHAR(TRIM(cteRCob.NroCuota)) AS Concepto
   ,Vpol.FrecuenciaPago AS Perioricidad
   ,cteRCob.Banco
   ,cteRCob.NroCuenta
   ,cteRCob.CodigoTransaccion
   ,cteRCob.NroCheque
   ,cteRCob.FechaDeposito
   ,cteRCob.AdministradoraTarjeta
   ,cteRCob.NroTarjeta
   ,VPOL.MonedaPoliza
   ,ROUND(cteRCob.ImporteCuota, 2) AS ImportePrimaPorCobrarMO
   ,ROUND(cteRCob.ImporteCuota * NVL(tblTipoCambio.TC, 0), 2) AS ImportePrimaPorCobrarML
   ,ROUND(cteRCob.ImporteRecibidoMO, 2) AS ImporteRecibidoMO
   ,ROUND(cteRCob.ImporteRecibidoML, 2) AS ImporteRecibidoML
   ,ROUND(cteRCob.SaldoFavorMO, 2) AS SaldoFavorMO
   ,ROUND(cteRCob.SaldoFavorMO, 2) * NVL(tblTipoCambio.TC, 0) AS SaldoFavorML
   ,0 AS RegularizacionSaldoMO
   ,0 AS RegularizacionSaldoML
   ,tblTipoCambio.TC AS TipoCambio
   ,VPol.CodTipoIntermediario
   ,VPOL.TipoIntermediario
   ,VPol.CodIntermediario
   ,VPOL.Intermediario
   ,cteRCob.Ntype
   ,cteRCob.CodMonedaTransaccion
   ,cteRCob.MonedaTransaccion
   ,cteRCob.EstadoRecibo
   ,CASE WHEN NVL(cteRCob.NroFacturaAnterior, 0) <> 0 THEN cteRCob.FechaFacturaAnterior ELSE NULL END AS FechaFacturaRecibo
   ,TO_CHAR(CASE WHEN NVL(cteRCob.NroFacturaAnterior, 0) <> 0 THEN cteRCob.NroFacturaAnterior ELSE NULL END) AS NroFacturaAnterior
   ,'' AS MonedaOriginalAnterior
   ,TO_CHAR(CREF.NCERTIF) AS NroCertificado
   ,VPOL.TipoFacturaColectivo
   ,VPOL.TipoDistribucion
   ,cteRCob.ImporteTotalRecibido
FROM COLFORMREF CREF
INNER JOIN cteDatosReciboAgrupado cteRCob ON CREF.NBordereaux = cteRCob.NBordereaux
INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON 
    CREF.NBRANCH = VPOL.NBRANCH 
    AND CREF.NPRODUCT = VPOL.NPRODUCT 
    AND CREF.NPolicy = VPOL.NPolicy
INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
INNER JOIN cteEmpresa ON cteEmpresa.Id = 1
OUTER APPLY (SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC FROM dual) tblTipoCambio
WHERE NVL(CREF.nnullcode, 0) = 0;     