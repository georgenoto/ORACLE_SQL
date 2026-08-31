
WITH cteEmpresa AS (
    SELECT NVL(TRIM(CD.SCLINUMDOCU), '1028483024') AS NIT_EMPRESA
          ,TRIM(REAGENERALPKG.REANAMECLI(CD.SCLIENT)) AS NOMBRE_EMPRESA
          ,1 AS Id
    FROM COMPANY CM
    INNER JOIN CLIDOCUMENTS CD ON CM.SCLIENT = CD.SCLIENT
    WHERE CM.NCOMPANY = REAGENERALPKG.REAOPT_SYSTEM_COMPANY
)
,cteMonedaPoliza AS (
    SELECT NBRANCH, NPRODUCT, NPOLICY, NCURRENCY
    FROM CURREN_POL
    WHERE DNULLDATE IS NULL
      AND SCERTYPE = 2
    GROUP BY NBRANCH, NPRODUCT, NPOLICY, NCURRENCY
)
,cteFormaPago AS (
    --- Rama 1: CASH_MOV (pagos normales)
    SELECT CF.nbordereaux
          ,CM.Ncurrency
          ,T11.sdescript AS MonedaTransaccion
          ,T78.sdescript AS FormaCobroRealizado
          ,NVL(CM.NAMOUNT, 0) AS ImporteRecibido
          ,CM.NORI_CURR AS CodMonedaOrigen
          ,CASE 
               WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
               WHEN CM.Ncurrency = 1 THEN NVL(CM.NAMOUNT, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO  
          ,CASE 
               WHEN CM.Ncurrency = 1 THEN CM.NAMOUNT
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoLO
          ,CASE WHEN CM.nmov_type = 2 THEN TO_CHAR(CM.sdocnumbe) ELSE '' END AS NroCheque
          ,CASE WHEN CM.nmov_type IN (2, 27, 57) THEN CM.ddoc_date ELSE NULL END AS FechaDeposito
          ,CASE CM.nmov_type
               WHEN 27 THEN TO_CHAR(T78.sshort_des)
               WHEN 57 THEN TO_CHAR(T78.sshort_des)
               ELSE ''
           END AS AdministradoraTarjeta
          ,CASE CM.nmov_type
               WHEN 27 THEN TO_CHAR(CM.sdocnumbe)
               WHEN 57 THEN TO_CHAR(CM.sdocnumbe)
               ELSE ''
           END AS NroTarjeta
          ,T7.sdescript AS Banco
          ,'' AS NroCuenta
          ,'' AS CodigoTransaccion
    FROM COLFORMREF CF
    INNER JOIN CASH_MOV CM ON CF.nbordereaux = CM.nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH 
                                   AND CF.NPRODUCT = MON.NPRODUCT 
                                   AND CF.NPOLICY = MON.NPOLICY
    LEFT JOIN TABLE11 T11 ON CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type = T78.nmov_type
    OUTER APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTipoCambio
    WHERE CM.nbordereaux IS NOT NULL  
      AND CF.STYPE NOT IN (2)
    
    UNION ALL

    --- Rama 2: BANK_MOV (pagos normales)
    SELECT CF2.nbordereaux
          ,BM.Ncurrency
          ,T11.sdescript AS MonedaTransaccion
          ,T296.sdescript AS FormaCobroRealizado
          ,NVL(BM.NCASH_AMOUN, 0) AS ImporteRecibido
          ,BM.NORI_CURR AS CodMonedaOrigen
          ,CASE 
               WHEN MON.NCURRENCY = BM.Ncurrency THEN NVL(BM.NCASH_AMOUN, 0)
               WHEN BM.Ncurrency = 1 THEN NVL(BM.NCASH_AMOUN, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO 
          ,CASE 
               WHEN BM.Ncurrency = 1 THEN BM.NCASH_AMOUN
               ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoLO   
          ,'' AS NroCheque
          ,CASE WHEN BM.nbordereaux IS NOT NULL THEN BM.ddoc_date ELSE NULL END AS FechaDeposito
          ,'' AS AdministradoraTarjeta
          ,'' AS NroTarjeta
          ,T7.sdescript AS Banco
          ,CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BA.SACC_NUMBER)) AS NroCuenta
          ,TO_CHAR(BM.sdep_number) AS CodigoTransaccion
    FROM COLFORMREF CF2
    INNER JOIN BANK_MOV BM ON CF2.Nbordereaux = BM.Nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF2.NBRANCH = MON.NBRANCH 
                                   AND CF2.NPRODUCT = MON.NPRODUCT 
                                   AND CF2.NPOLICY = MON.NPOLICY
    INNER JOIN TABLE11 T11 ON BM.Ncurrency = T11.ncodigint
    LEFT JOIN BANK_ACC BA ON BM.NACC_BANK = BA.NACC_BANK
    LEFT JOIN TABLE7 T7 ON BA.NBANK_CODE = T7.NBANK_CODE
    LEFT JOIN TABLE296 T296 ON BM.NTYPE_MOV = T296.NTYPE_MOV
    OUTER APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF2.DCollect) AS TC FROM dual) tblTipoCambio
    WHERE BM.nbordereaux IS NOT NULL
      AND CF2.STYPE NOT IN (2)

    UNION ALL

    --- Rama 3: MOVE_ACC (cuenta corriente cliente, NTYPE_MOVE=17)
    SELECT CF.nbordereaux
          ,CM.Ncurrency
          ,T11.sdescript AS MonedaTransaccion
          ,'Cargo cta.cte. cliente' AS FormaCobroRealizado
          ,ABS(NVL(CM.NAMOUNT, 0)) AS ImporteRecibido
          ,CM.NCURRENCY AS CodMonedaOrigen
          ,ABS(CASE 
               WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
               WHEN CM.Ncurrency = 1 THEN NVL(CM.NAMOUNT, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END) AS ImporteRecibidoMO  
          ,ABS(CASE 
               WHEN CM.Ncurrency = 1 THEN CM.NAMOUNT
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END) AS ImporteRecibidoLO
          ,NULL AS NroCheque
          ,NULL AS FechaDeposito
          ,NULL AS AdministradoraTarjeta
          ,NULL AS NroTarjeta
          ,NULL AS Banco
          ,NULL AS NroCuenta
          ,NULL AS CodigoTransaccion
    FROM COLFORMREF CF
    INNER JOIN MOVE_ACC CM ON CF.nbordereaux = CM.nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH = MON.NBRANCH 
                                   AND CF.NPRODUCT = MON.NPRODUCT 
                                   AND CF.NPOLICY = MON.NPOLICY
    LEFT JOIN TABLE11 T11 ON CM.Ncurrency = T11.ncodigint
    OUTER APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTipoCambio
    WHERE CM.nbordereaux IS NOT NULL  
      AND CF.STYPE NOT IN (2)
      AND CM.NTYPE_MOVE = 17

    UNION ALL

    --- Rama 4: CASH_MOV pagos adicionales (via RELCONCEPTS)
    SELECT CF.nbordereaux
          ,CM.Ncurrency
          ,T11.sdescript AS MonedaTransaccion
          ,T78.sdescript AS FormaCobroRealizado
          ,NVL(CM.NAMOUNT, 0) AS ImporteRecibido
          ,CM.NORI_CURR AS CodMonedaOrigen
          ,CASE 
               WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
               WHEN CM.Ncurrency = 1 THEN NVL(CM.NAMOUNT, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO  
          ,CASE 
               WHEN CM.Ncurrency = 1 THEN CM.NAMOUNT
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoLO
          ,CASE WHEN CM.nmov_type = 2 THEN TO_CHAR(CM.sdocnumbe) ELSE '' END AS NroCheque
          ,CASE WHEN CM.nmov_type IN (2, 27, 57) THEN CM.ddoc_date ELSE NULL END AS FechaDeposito
          ,CASE CM.nmov_type
               WHEN 27 THEN TO_CHAR(T78.sshort_des)
               WHEN 57 THEN TO_CHAR(T78.sshort_des)
               ELSE ''
           END AS AdministradoraTarjeta
          ,CASE CM.nmov_type
               WHEN 27 THEN TO_CHAR(CM.sdocnumbe)
               WHEN 57 THEN TO_CHAR(CM.sdocnumbe)
               ELSE ''
           END AS NroTarjeta
          ,T7.sdescript AS Banco
          ,'' AS NroCuenta
          ,'' AS CodigoTransaccion
    FROM COLFORMREF CF
    INNER JOIN CASH_MOV CM ON CF.nbordereaux = CM.nbordereaux
    INNER JOIN RELCONCEPTS RCON ON CF.NBORDEREAUX = RCON.NBORDEREAUX
    INNER JOIN cteMonedaPoliza MON ON RCON.NPOLICY = MON.NPOLICY
    LEFT JOIN TABLE11 T11 ON CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type = T78.nmov_type
    OUTER APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF.DCollect) AS TC FROM dual) tblTipoCambio
    WHERE CM.nbordereaux IS NOT NULL  
      AND CF.STYPE NOT IN (2)
    
    UNION ALL

    --- Rama 5: BANK_MOV pagos adicionales (via RELCONCEPTS)
    SELECT CF2.nbordereaux
          ,BM.Ncurrency
          ,T11.sdescript AS MonedaTransaccion
          ,T296.sdescript AS FormaCobroRealizado
          ,NVL(BM.NCASH_AMOUN, 0) AS ImporteRecibido
          ,BM.NORI_CURR AS CodMonedaOrigen
          ,CASE 
               WHEN MON.NCURRENCY = BM.Ncurrency THEN NVL(BM.NCASH_AMOUN, 0)
               WHEN BM.Ncurrency = 1 THEN NVL(BM.NCASH_AMOUN, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO 
          ,CASE 
               WHEN BM.Ncurrency = 1 THEN BM.NCASH_AMOUN
               ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoLO   
          ,'' AS NroCheque
          ,CASE WHEN BM.nbordereaux IS NOT NULL THEN BM.ddoc_date ELSE NULL END AS FechaDeposito
          ,'' AS AdministradoraTarjeta
          ,'' AS NroTarjeta
          ,T7.sdescript AS Banco
          ,CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BA.SACC_NUMBER)) AS NroCuenta
          ,TO_CHAR(BM.sdep_number) AS CodigoTransaccion
    FROM COLFORMREF CF2
    INNER JOIN BANK_MOV BM ON CF2.Nbordereaux = BM.Nbordereaux
    INNER JOIN RELCONCEPTS RCON ON CF2.NBORDEREAUX = RCON.NBORDEREAUX
    INNER JOIN cteMonedaPoliza MON ON RCON.NPOLICY = MON.NPOLICY
    INNER JOIN TABLE11 T11 ON BM.Ncurrency = T11.ncodigint
    LEFT JOIN BANK_ACC BA ON BM.NACC_BANK = BA.NACC_BANK
    LEFT JOIN TABLE7 T7 ON BA.NBANK_CODE = T7.NBANK_CODE
    LEFT JOIN TABLE296 T296 ON BM.NTYPE_MOV = T296.NTYPE_MOV
    OUTER APPLY (SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY, CF2.DCollect) AS TC FROM dual) tblTipoCambio
    WHERE BM.nbordereaux IS NOT NULL
      AND CF2.STYPE NOT IN (2)
) 
,cteFacturas_EnRelacion AS (
   SELECT CF1.Nbordereaux
        , LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum, PO_AUX.nreceipt)), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY F1.NBillnum) AS FacturasEnRelacion
        , MAX(DECODE(NVL(F1.NBILLNUM, 0), 0, 'Recibo', DECODE(NVL(tblFA.NBILLNUM, 0), 0, 'Factura', 'Factura Anticipada'))) AS TipoDocumento 
        , MAX(NVL(tblCambioDeFactura.FechaCambioFact, NULL)) AS FechaFacturaAnterior
        , MAX(NVL(tblCambioDeFactura.NroFactAnterior, NULL)) AS NroFacturaAnterior
    FROM COLFORMREF CF1
    INNER JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux
    LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux AND F1.Nbillstat NOT IN (2)
    OUTER APPLY (
         SELECT PO_AUX2.NBILLNUM 
         FROM PREMIUM_MO PO_AUX2 
         WHERE PO_AUX2.nreceipt = PO_AUX.nreceipt 
           AND PO_AUX2.NBILLNUM = PO_AUX.NBILLNUM 
           AND PO_AUX2.NTYPE IN (42)                   
           AND NVL(PO_AUX2.NNULLCODE, 0) = 0
    ) tblFA
    OUTER APPLY (
        SELECT B1.NBILLNUM AS NroFactAnterior
              ,B1.dcompdate AS FechaCambioFact
        FROM BILLS B1
        WHERE B1.NBordereaux = CF1.Nbordereaux
          AND B1.Nbillstat = 2  -- anulado
          AND B1.Nnullcode = 11  -- Cambio de Factura
    ) tblCambioDeFactura
    WHERE NVL(PO_AUX.NNULLCODE, 0) = 0 
    GROUP BY CF1.Nbordereaux
    
    UNION ALL

    --- Facturas de pagos adicionales
    SELECT CF1.Nbordereaux
         , LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum, '')), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY F1.NBillnum) AS FacturasEnRelacion
         , MAX(DECODE(NVL(F1.NBILLNUM, 0), 0, 'Recibo', 'Factura')) AS TipoDocumento 
         , NULL AS FechaFacturaAnterior
         , NULL AS NroFacturaAnterior
    FROM COLFORMREF CF1
    INNER JOIN RELCONCEPTS CON ON CF1.NBORDEREAUX = CON.NBORDEREAUX
    LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux
    WHERE F1.Nbillstat NOT IN (2)
    GROUP BY CF1.Nbordereaux
) 
,cteRecibos_EnRelacion AS (
   SELECT CF1.Nbordereaux
        , LISTAGG(DISTINCT TO_CHAR(NVL(PO_AUX.Nreceipt, '')), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY PO_AUX.Nreceipt) AS RecibosEnRelacion        
        , COUNT(PO_AUX.Nreceipt) cantRecibos
   FROM COLFORMREF CF1
   INNER JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux    
   WHERE NVL(PO_AUX.NNULLCODE, 0) = 0     
   GROUP BY CF1.Nbordereaux
)  
,cteDatosRecibo AS(
   --- Rama 1: Recibos normales (PREMIUM_MO)
   SELECT CF3.Nbordereaux 
         , TRIM(P.Nreceipt) AS Nreceipt  
         , TRIM(P.NPeriod) AS NroCuota           
         , P.dlimitdate AS FechaVencimiento
         , ROUND(NVL(P.npremium, 0), 2) ImporteCuota
         , DECODE(NVL(PO.NBILLNUM, 0), 0, TRIM(cteFRel.FacturasEnRelacion), TRIM(PO.NBILLNUM)) AS NroFactura
         , NVL(cteFRel.FechaFacturaAnterior, NULL) AS FechaFacturaAnterior
         , NVL(cteFRel.NroFacturaAnterior, 0) AS NroFacturaAnterior
         , UCash.NCASHNUM AS NCASHNUM
         , INITCAP(LOWER(RTRIM(CliCaja.scliename))) AS Cajero
         , EstRec.sdescript AS EstadoRecibo
         , CASE P.NTRATYPEI
                WHEN 1 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 2 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 3 THEN 'Anexo'
                WHEN 4 THEN 'Anexo de resicion de contrato'
                WHEN 9 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 12 THEN 'Anexo de rehabilitacion'
                ELSE TRIM(TCuo.sdescript)
           END AS TipoCuota
         , TRIM(MPag.sdescript) AS CanalCobroRealizado            
         , To_char(TRIM(P.NPeriod)) NPeriodo
         , P.Ntype Ntype
         , TRIM(cteFRel.TipoDocumento) AS TipoDocumento  
         , TRIM(cteRRel.RecibosEnRelacion) AS RecibosEnRelacion
         , TRIM(cteFRel.FacturasEnRelacion) AS FacturasEnRelacion                    
   FROM COLFORMREF CF3
   INNER JOIN PREMIUM_MO PO ON CF3.Nbordereaux = PO.Nbordereaux
   INNER JOIN PREMIUM P ON PO.SCERTYPE = P.SCERTYPE
                        AND PO.NBRANCH = P.NBRANCH
                        AND PO.NPRODUCT = P.NPRODUCT
                        AND PO.NRECEIPT = P.NRECEIPT
                        AND PO.NDIGIT = P.NDIGIT
                        AND PO.NPAYNUMBE = P.NPAYNUMBE
   INNER JOIN cteRecibos_EnRelacion cteRRel ON CF3.Nbordereaux = cteRRel.Nbordereaux
   LEFT JOIN cteFacturas_EnRelacion cteFRel ON CF3.Nbordereaux = cteFRel.Nbordereaux
   INNER JOIN TABLE19 EstRec ON P.nstatus_pre = EstRec.nstatus_pre
   INNER JOIN TABLE24 TCuo ON P.NTRATYPEI = TCuo.NTRATYPEI                     
   LEFT JOIN USER_CASHNUM UCash ON CF3.NCASHNUM = UCash.NCASHNUM
   LEFT JOIN USERS UsrCaja ON UCash.NUSER = UsrCaja.NUSERCODE
   LEFT JOIN CLIENT CliCaja ON UsrCaja.SClient = CliCaja.SClient        
   LEFT JOIN TABLE5002 MPag ON P.nway_pay = MPag.nway_pay
   LEFT JOIN TABLE6 Tipo ON PO.Ntype = tipo.ntype_tran
   WHERE PO.Ntype IN (2, 13, 14, 21, 39, 40)
     AND P.nstatus_pre IN (2, 5, 6, 7)    
     AND NVL(CF3.nnullcode, 0) = 0  
     AND CF3.STYPE NOT IN (2)
   
   UNION ALL

   --- Rama 2: Cuotas de financiamiento (FINANC_DRA)
   SELECT CF2.Nbordereaux 
         , TRIM(PRE.Nreceipt) AS Nreceipt  
         , TRIM(FDRA.Ndraft) AS NroCuota           
         , FDRA.dlimitdate AS FechaVencimiento
         , ROUND(FDRA.namount, 2) ImporteCuota
         , TRIM(fact.NBILLNUM) AS NroFactura
         , NVL(fact.DISSUEDAT, NULL) AS FechaFacturaAnterior
         , NVL(fact.NPREVBILL, 0) AS NroFacturaAnterior
         , UCash.NCASHNUM AS NCASHNUM
         , INITCAP(LOWER(RTRIM(CliCaja.scliename))) AS Cajero
         , EstRec.sdescript AS EstadoRecibo
         , CASE PRE.NTRATYPEI
                WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 3 THEN 'Anexo'
                WHEN 4 THEN 'Anexo de resicion de contrato'
                WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 12 THEN 'Anexo de rehabilitacion'
                ELSE TRIM(TCuo.sdescript)
           END AS TipoCuota            
         , To_char(TRIM(PRE.NPeriod)) NPeriodo
         , TRIM(MPag.sdescript) AS CanalCobroRealizado 
         , PRE.Ntype Ntype       
         , DECODE(NVL(fact.NBILLNUM, 0), 0, 'Recibo', DECODE(NVL(tblFA.NBILLNUM, 0), 0, 'Factura', 'Factura Anticipada')) AS TipoDocumento
         , TRIM(PRE.Nreceipt) AS RecibosEnRelacion
         , TRIM(fact.NBILLNUM) AS FacturasEnRelacion           
   FROM COLFORMREF CF2
   INNER JOIN FINANC_DRA FDRA ON CF2.NBordereaux = FDRA.NBordereaux
   INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat = DRA_HIS.ncontrat
                                  AND FDRA.NDRAFT = DRA_HIS.NDRAFT
                                  AND DRA_HIS.Ntype IN (2)
   INNER JOIN PREMIUM PRE ON FDRA.ncontrat = Pre.ncontrat
   INNER JOIN TABLE19 EstRec ON Pre.nstatus_pre = EstRec.nstatus_pre
   INNER JOIN TABLE24 TCuo ON Pre.NTRATYPEI = TCuo.NTRATYPEI                             
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
          AND DRA_HIS.Ntype IN (42)             
   ) tblFA         
   WHERE PRE.nstatus_pre IN (8)        
     AND CF2.STYPE NOT IN (2)
     AND fact.Nbillstat NOT IN (2)
   
   UNION ALL
     
   --- Rama 3: Pagos adicionales (RELCONCEPTS)
   SELECT CF3.Nbordereaux 
         , '0' AS Nreceipt  
         , TRIM(RCON.NTRANSAC) AS NroCuota            
         , RCON.DVALDATE AS FechaVencimiento
         , ROUND(NVL(RCON.NAMOUNT, 0), 2) ImporteCuota
         , TRIM(fact.NBILLNUM) AS NroFactura
         , NVL(cteFRel.FechaFacturaAnterior, NULL) AS FechaFacturaAnterior
         , NVL(cteFRel.NroFacturaAnterior, 0) AS NroFacturaAnterior
         , UCash.NCASHNUM AS NCASHNUM
         , INITCAP(LOWER(RTRIM(CliCaja.scliename))) AS Cajero
         , CASE WHEN CF3.SSTATUS = 1 THEN 'Pagado' ELSE 'Inactivo' END AS EstadoRecibo
         , TRIM(TCuo.SDESCRIPT) AS TipoCuota
         , TRIM(CPag.SDESCRIPT) AS CanalCobroRealizado 
         , To_char(TRIM(RCON.NTRANSAC)) NPeriodo                       
         , 1 Ntype
         , TRIM(cteFRel.TipoDocumento) AS TipoDocumento   
         , TRIM(cteRRel.RecibosEnRelacion) AS RecibosEnRelacion
         , TRIM(cteFRel.FacturasEnRelacion) AS FacturasEnRelacion                    
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
,cteContadores AS (
    SELECT cref.NBordereaux
         , NVL(fp.cantFPago, 0) AS cantFPago
         , NVL(rc.cantRec, 0) AS cantRec
    FROM COLFORMREF cref
    LEFT JOIN (
        SELECT NBordereaux, COUNT(*) AS cantFPago
        FROM cteFormaPago
        GROUP BY NBordereaux
    ) fp ON cref.NBordereaux = fp.NBordereaux
    LEFT JOIN (
        SELECT NBordereaux, COUNT(*) AS cantRec
        FROM cteDatosRecibo
        GROUP BY NBordereaux
    ) rc ON cref.NBordereaux = rc.NBordereaux
    WHERE NVL(cref.NNULLCODE, 0) = 0
)

,cteDatosReciboAgrupado AS(
    SELECT cterc.NBordereaux, cterc.NReceipt, cterc.NroCuota, cterc.FechaVencimiento, cterc.ImporteCuota
          ,cterc.NroFactura, cterc.FechaFacturaAnterior, cterc.NroFacturaAnterior, cterc.NCashnum, cterc.Cajero
          ,cterc.EstadoRecibo, cterc.TipoCuota, cterc.CanalCobroRealizado, cterc.Nperiodo, cterc.Ntype
          ,cterc.TipoDocumento
          ,cterc.NReceipt AS RecibosEnRelacion 
          ,cterc.NroFactura AS FacturasEnRelacion 
          ,cteFormaPago.FormaCobroRealizado 
          ,cteFormaPago.Banco 
          ,cteFormaPago.NroCuenta
          ,cteFormaPago.CodigoTransaccion
          ,cteFormaPago.NroCheque
          ,cteFormaPago.FechaDeposito
          ,cteFormaPago.AdministradoraTarjeta
          ,cteFormaPago.NroTarjeta
          ,CASE WHEN cterc.NReceipt <> '0' 
                THEN tdoc.Namount 
                ELSE cteFormaPago.ImporteRecibidoMO 
           END AS ImporteRecibidoMO   
          ,CASE WHEN cterc.NReceipt <> '0' 
                THEN (tdoc.Namount * NVL(tdoc.nexchange, 1))
                ELSE cteFormaPago.ImporteRecibidoLO 
           END AS ImporteRecibidoML  
          ,cteFormaPago.ncurrency AS CodMonedaTransaccion
          ,cteFormaPago.MonedaTransaccion 
          ,cteFormaPago.ImporteRecibido AS ImporteTotalRecibido
          ,CASE 
               WHEN cterc.NReceipt <> '0' THEN
                   CASE WHEN ABS(ROUND(cterc.ImporteCuota, 2) - ROUND(tdoc.Namount, 2)) > 0.5
                        THEN ABS(ROUND(cterc.ImporteCuota, 2) - ROUND(tdoc.Namount, 2))
                        ELSE 0 
                   END
               ELSE 0
           END AS SaldoFavorMO         
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    LEFT JOIN TRELDOC tdoc ON cterc.NBordereaux = tdoc.NBordereaux AND cterc.NReceipt = tdoc.NReceipt
    WHERE (cteaux.cantFPago = 1 AND cteaux.cantRec >= 1)
       OR (cteaux.cantFPago > 1 AND cteaux.cantRec = 1) 
    
    UNION ALL
    
    --- Escenario agregado: N formas de pago + N recibos (se agrupa todo)
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
          ,MAX(cterc.FacturasEnRelacion) AS FacturasEnRelacion
          ,cteFormaPago.FormaCobroRealizado AS FormaCobroRealizado
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
    INNER JOIN cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    WHERE cteaux.cantFPago > 1 AND cteaux.cantRec > 1 
    GROUP BY cterc.NBordereaux, cteFormaPago.FormaCobroRealizado
)
SELECT 
              511 SKEY
            , cteEmpresa.NOMBRE_EMPRESA As NOMBRE_COMPANIA
            , TO_CHAR(cteEmpresa.NIT_EMPRESA) AS NIT_COMPANIA
            , VPOL.LineaNegocio as LINEA_NEGOCIO
            , VPOL.CanalVenta as CANAL_VENTA
            , VPOL.Ramo  as RAMO
            , TO_CHAR(VPOL.nproduct) || '-' ||VPOL.Producto as PRODUCTO
            , TRIM(VPOL.CanalCobroAsignado) AS CANAL_COBRO_ASIGNADO 
            , VPOL.RegionalPoliza  as REGIONAL_ORIGEN
            , TRIM(suc.sdescript) as REGIONAL_COBRO
            , cteRCob.Cajero as CAJERO
            , cteRCob.CanalCobroRealizado as CANAL_COBRO
            , TO_CHAR(CREF.DCollect, 'DD-MM-YYYY') AS FECHA_COBRO
            , VPOL.TipoFacturaColectivo as TIPO_FACTURA_COLECTIVO
            , VPOL.TipoDistribucion as TIPO_DISTRIBUCION
            , vpol.contratante CLIENTE
            , TO_CHAR(VPOL.npolicy) AS NRO_POLIZA
            , TO_CHAR(CREF.NCERTIF) As NRO_CERTIFICADO
            , cteRCob.TipoCuota as TIPO_CUOTA
            , TO_CHAR(cteRCob.NroCuota) AS NRO_CUOTA
            , TO_CHAR(cteRCob.RecibosEnRelacion) AS COD_RECIBO 
            , TO_CHAR(cteRCob.FechaVencimiento, 'DD-MM-YYYY') as FECHA_VENCIMIENTO
            , cteRCob.TipoDocumento as TIPO_DOCUMENTO
            , TO_CHAR(cteRCob.FacturasEnRelacion) As NRO_FACTURA_RECIBO
            , cteRCob.FormaCobroRealizado  as FORMA_COBRO
            , TO_CHAR(CREF.NBordereaux) As NRO_RELACION
            , 'Producto:'|| VPOL.Producto ||' | Nro. Poliza:' || To_char(TRIM(VPOL.NroPoliza))|| ' | Tipo Cuota:' || to_char(cteRCob.TipoCuota)  || ' | Nro. Cuota: ' || To_char(TRIM(cteRCob.NroCuota)) As CONCEPTO
            , Vpol.FrecuenciaPago as PERIODICIDAD
            , cteRCob.Banco  as BANCO
            , cteRCob.NroCuenta  as NRO_CUENTA
            , cteRCob.CodigoTransaccion as COD_TRANSACCION
            , cteRCob.NroCheque as NRO_CHEQUE
            , cteRCob.FechaDeposito as FECHA_DEPOSITO
            , cteRCob.AdministradoraTarjeta as ADMINISTRADORA_TARJETA
            , cteRCob.NroTarjeta as NRO_TARJETA
            , VPOL.MonedaPoliza as MONEDA_POLIZA
            , ROUND(cteRCob.ImporteCuota,2) As IMPORTE_POR_COBRAR_MO
            , ROUND(cteRCob.ImporteCuota  * NVL(tblTipoCambio.TC,0),2) As IMPORTE_POR_COBRAR_LO
            , ROUND(cteRCob.ImporteRecibidoMO,2)  AS  IMPORTE_RECIBIDO_MO
            , ROUND(cteRCob.ImporteRecibidoML ,2)   AS  IMPORTE_RECIBIDO_LO  
            , ROUND(cteRCob.SaldoFavorMO ,2)   AS  SALDO_FAVOR_MO           
            , ROUND(cteRCob.SaldoFavorMO ,2) * NVL(tblTipoCambio.TC,0)  AS SALDO_FAVOR_LO       
            , 0 As REGULARIZACION_SALDO_MO
            , 0 As REGULARIZACION_SALDO_LO
            , tblTipoCambio.TC as TIPO_CAMBIO
            , VPOL.TipoIntermediario As TIPO_INTERMEDIARIO
            , VPOL.Intermediario As INTERMEDIARIO
            , cteRCob.MonedaTransaccion as MONEDA_TRANSACCION
            , cteRCob.EstadoRecibo as ESTADO_RECIBO
            , CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.FechaFacturaAnterior ELSE NULL END As FECHA_FACTURA_RECIBO
            , TO_CHAR(CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.NroFacturaAnterior ELSE NULL END) AS NRO_FACTURA_ANTERIOR
            , '' AS MONEDA_TRANSACCION_ANTERIOR
            , RCon.NPolicy AS Npolicy_adicional  -- Campo indicador: NULL = regular, NO NULL = pago adicional
                        
        FROM COLFORMREF CREF
        LEFT JOIN RELCONCEPTS RCon ON CREF.NBordereaux = RCon.NBordereaux
        INNER JOIN cteDatosReciboAgrupado cteRCob ON CREF.NBordereaux = cteRCob.NBordereaux 
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON 
              CASE WHEN RCon.NPolicy IS NOT NULL THEN RCon.NPolicy ELSE CREF.NPolicy END = VPOL.NPolicy
              AND (RCon.NPolicy IS NOT NULL OR (CREF.NBRANCH = VPOL.NBRANCH AND CREF.NPRODUCT = VPOL.NPRODUCT))
        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
        INNER JOIN cteEmpresa ON cteEmpresa.Id=1
        WHERE NVL(CREF.nnullcode,0)=0               		                                     		             
        --parametros>                  		
        AND  CREF.DCollect BETWEEN TO_DATE('01/07/2026' , 'DD-MM-YYYY') AND TO_DATE('24/08/2026' , 'DD-MM-YYYY')
