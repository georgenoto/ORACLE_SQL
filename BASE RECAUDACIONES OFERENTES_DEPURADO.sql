-- Depurado: se conservan las columnas finales, los filtros y los cruces que pueden afectar la cantidad de filas.
WITH cteEmpresa AS (
    SELECT
        1 AS Id
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
    SELECT
        CF.nbordereaux
       ,T78.sdescript AS FormaCobroRealizado
       ,CASE 
               WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
               WHEN CM.Ncurrency = 1 THEN NVL(CM.NAMOUNT, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO
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
    SELECT
        CF2.nbordereaux
       ,T296.sdescript AS FormaCobroRealizado
       ,CASE 
               WHEN MON.NCURRENCY = BM.Ncurrency THEN NVL(BM.NCASH_AMOUN, 0)
               WHEN BM.Ncurrency = 1 THEN NVL(BM.NCASH_AMOUN, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO
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
    SELECT
        CF.nbordereaux
       ,'Cargo cta.cte. cliente' AS FormaCobroRealizado
       ,ABS(CASE 
               WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
               WHEN CM.Ncurrency = 1 THEN NVL(CM.NAMOUNT, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END) AS ImporteRecibidoMO
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
    SELECT
        CF.nbordereaux
       ,T78.sdescript AS FormaCobroRealizado
       ,CASE 
               WHEN MON.NCURRENCY = CM.Ncurrency THEN NVL(CM.NAMOUNT, 0)
               WHEN CM.Ncurrency = 1 THEN NVL(CM.NAMOUNT, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(CM.NAMOUNT, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO
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
    SELECT
        CF2.nbordereaux
       ,T296.sdescript AS FormaCobroRealizado
       ,CASE 
               WHEN MON.NCURRENCY = BM.Ncurrency THEN NVL(BM.NCASH_AMOUN, 0)
               WHEN BM.Ncurrency = 1 THEN NVL(BM.NCASH_AMOUN, 0) / NVL(tblTipoCambio.TC, 0)
               ELSE NVL(BM.NCASH_AMOUN, 0) * NVL(tblTipoCambio.TC, 0)
           END AS ImporteRecibidoMO
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
   SELECT
        CF1.Nbordereaux
       ,LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum, PO_AUX.nreceipt)), ', ' ON OVERFLOW TRUNCATE) 
        WITHIN GROUP(ORDER BY F1.NBillnum) AS FacturasEnRelacion
    FROM COLFORMREF CF1
LEFT JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux 
                               AND NVL(PO_AUX.NNULLCODE, 0) = 0
LEFT JOIN RELCONCEPTS CON  ON CF1.NBORDEREAUX = CON.NBORDEREAUX
LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux  
                      AND F1.Nbillstat NOT IN (2)
WHERE  (PO_AUX.Nbordereaux IS NOT NULL OR CON.NBORDEREAUX IS NOT NULL)
GROUP BY CF1.Nbordereaux
) 
,cteRecibos_EnRelacion AS (
   SELECT
        CF1.Nbordereaux
       ,LISTAGG(DISTINCT TO_CHAR(NVL(PO_AUX.Nreceipt, '')), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY PO_AUX.Nreceipt) AS RecibosEnRelacion
    FROM COLFORMREF CF1
   INNER JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux    
   WHERE NVL(PO_AUX.NNULLCODE, 0) = 0     
   GROUP BY CF1.Nbordereaux
)  
,cteDatosRecibo AS(
   --- Rama 1: Recibos normales (PREMIUM_MO)
   SELECT
        CF3.Nbordereaux
       ,TRIM(P.Nreceipt) AS Nreceipt
       ,TRIM(P.NPeriod) AS NroCuota
       ,ROUND(NVL(P.npremium, 0), 2) ImporteCuota
       ,DECODE(NVL(PO.NBILLNUM, 0), 0, TRIM(cteFRel.FacturasEnRelacion), TRIM(PO.NBILLNUM)) AS NroFactura
       ,CASE P.NTRATYPEI
                WHEN 1 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 2 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 3 THEN 'Anexo'
                WHEN 4 THEN 'Anexo de resicion de contrato'
                WHEN 9 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 12 THEN 'Anexo de rehabilitacion'
                ELSE TRIM(TCuo.sdescript)
           END AS TipoCuota
       ,P.Ntype Ntype
       ,TRIM(cteRRel.RecibosEnRelacion) AS RecibosEnRelacion
       ,TRIM(cteFRel.FacturasEnRelacion) AS FacturasEnRelacion
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
   SELECT
        CF2.Nbordereaux
       ,TRIM(PRE.Nreceipt) AS Nreceipt
       ,TRIM(FDRA.Ndraft) AS NroCuota
       ,ROUND(FDRA.namount, 2) ImporteCuota
       ,TRIM(fact.NBILLNUM) AS NroFactura
       ,CASE PRE.NTRATYPEI
                WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 3 THEN 'Anexo'
                WHEN 4 THEN 'Anexo de resicion de contrato'
                WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                WHEN 12 THEN 'Anexo de rehabilitacion'
                ELSE TRIM(TCuo.sdescript)
           END AS TipoCuota
       ,PRE.Ntype Ntype
       ,TRIM(PRE.Nreceipt) AS RecibosEnRelacion
       ,TRIM(fact.NBILLNUM) AS FacturasEnRelacion
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
   WHERE PRE.nstatus_pre IN (8)        
     AND CF2.STYPE NOT IN (2)
     AND fact.Nbillstat NOT IN (2)
   
   UNION ALL
     
   --- Rama 3: Pagos adicionales (RELCONCEPTS)
   SELECT
        CF3.Nbordereaux
       ,'0' AS Nreceipt
       ,TRIM(RCON.NTRANSAC) AS NroCuota
       ,ROUND(NVL(RCON.NAMOUNT, 0), 2) ImporteCuota
       ,TRIM(fact.NBILLNUM) AS NroFactura
       ,TRIM(TCuo.SDESCRIPT) AS TipoCuota
       ,1 Ntype
       ,TRIM(cteRRel.RecibosEnRelacion) AS RecibosEnRelacion
       ,TRIM(cteFRel.FacturasEnRelacion) AS FacturasEnRelacion
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
    SELECT
        cterc.NBordereaux
       ,cterc.NroCuota
       ,cterc.ImporteCuota
       ,cterc.TipoCuota
       ,cterc.Ntype
       ,cterc.NReceipt AS RecibosEnRelacion
       ,cterc.NroFactura AS FacturasEnRelacion
       ,CASE WHEN cterc.NReceipt <> '0' 
                THEN tdoc.Namount 
                ELSE cteFormaPago.ImporteRecibidoMO 
           END AS ImporteRecibidoMO
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    LEFT JOIN TRELDOC tdoc ON cterc.NBordereaux = tdoc.NBordereaux AND cterc.NReceipt = tdoc.NReceipt
    WHERE (cteaux.cantFPago = 1 AND cteaux.cantRec >= 1)
       OR (cteaux.cantFPago > 1 AND cteaux.cantRec = 1) 
    
    UNION ALL
    
    SELECT
        cterc.NBordereaux
       ,LISTAGG(DISTINCT TRIM(cterc.NroCuota), ', ') WITHIN GROUP(ORDER BY cterc.NroCuota) AS NroCuota
       ,SUM(cterc.ImporteCuota) AS ImporteCuota
       ,MAX(cterc.TipoCuota) AS TipoCuota
       ,MAX(cterc.Ntype) AS Ntype
       ,MAX(cterc.RecibosEnRelacion) AS RecibosEnRelacion
       ,MAX(cterc.FacturasEnRelacion) AS FacturasEnRelacion
       ,MAX(cteFormaPago.ImporteRecibidoMO) AS ImporteRecibidoMO
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormaPago ON cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadores cteaux ON cterc.NBordereaux = cteaux.NBordereaux
    WHERE cteaux.cantFPago > 1 AND cteaux.cantRec > 1 
    GROUP BY cterc.NBordereaux, cteFormaPago.FormaCobroRealizado
), cteOferentes as (
 SELECT
        R.NPOLICY
       ,R.NINTERMED COD_OFERENTE
       ,C.SCLIENAME NOMBRE_OFERENTE
       ,CTO.NPERCENT PORC_COMISION
    FROM ROLES R
 INNER JOIN TABLE12 T12 ON R.NROLE= T12.NROLE
 INNER JOIN CLIENT C ON R.SCLIENT = C.SCLIENT 
 INNER JOIN CONTRAT_PAY CTO ON R.NCONTRAT_PAY = CTO.NCONTRAT_PAY
 WHERE R.NROLE=34 -- OFERENTE 
 AND R.DNULLDATE IS NULL
)
SELECT 
             5000 SKEY
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , TO_CHAR(cteRCob.RecibosEnRelacion) AS NRECEIPT                                   
            , VPOL.Ramo
            , TO_CHAR(VPOL.nproduct) || '-' ||VPOL.Producto as Producto
            , VPOL.LineaNegocio
            , VPOL.CodRegionalPoliza
            , VPOL.RegionalPoliza
            , CREF.DCollect AS FechaCobro
            , vpol.contratante Cliente
            , TO_CHAR(VPOL.npolicy) AS NroPoliza
            , TO_CHAR(cteRCob.NroCuota) AS NroCuota
            , cteRCob.TipoCuota
            , TO_CHAR(cteRCob.FacturasEnRelacion) As NroFactura
            , Vpol.FrecuenciaPago as Perioricidad
            , VPOL.MonedaPoliza
            , ROUND(cteRCob.ImporteCuota,2) As ImportePrimaPorCobrarMO
            , ROUND(cteRCob.ImporteRecibidoMO,2)  AS  ImporteRecibidoMO
            ,OFE.COD_OFERENTE
            ,OFE.NOMBRE_OFERENTE
            ,OFE.PORC_COMISION 
            , (ROUND(cteRCob.ImporteRecibidoMO,2)  / 1.35) * (OFE.PORC_COMISION / 100) VALOR_COMISION_MO 
            , cteRCob.Ntype
            
                        
        FROM COLFORMREF CREF
        LEFT JOIN RELCONCEPTS RCon ON CREF.NBordereaux = RCon.NBordereaux
        INNER JOIN cteDatosReciboAgrupado cteRCob ON CREF.NBordereaux = cteRCob.NBordereaux 
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON 
              CASE WHEN RCon.NPolicy IS NOT NULL THEN RCon.NPolicy ELSE CREF.NPolicy END = VPOL.NPolicy
              AND (RCon.NPolicy IS NOT NULL OR (CREF.NBRANCH = VPOL.NBRANCH AND CREF.NPRODUCT = VPOL.NPRODUCT))
        INNER JOIN cteOferentes ofe ON VPOL.npolicy = ofe.NPOLICY
        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
        INNER JOIN cteEmpresa ON cteEmpresa.Id=1
        WHERE NVL(CREF.nnullcode,0)=0  
         AND  CREF.DCollect BETWEEN TO_DATE('01/09/2026' , 'DD-MM-YYYY') AND TO_DATE('24/09/2026' , 'DD-MM-YYYY');
