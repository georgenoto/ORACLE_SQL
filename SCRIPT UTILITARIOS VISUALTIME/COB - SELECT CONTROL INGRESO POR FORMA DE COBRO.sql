-------------------------------------------------------------------------------------
---- PAGOS ORIGINALES Y ANTICIPADOS UNIFICADOS
-------------------------------------------------------------------------------------
WITH cteMonedaPoliza AS(
        SELECT 
             cpol.NBRANCH,cpol.NPRODUCT, cpol.NPOLICY, cpol.NCURRENCY
            ,ROW_NUMBER() OVER(PARTITION BY  cpol.NBRANCH,cpol.NPRODUCT, cpol.NPOLICY ORDER BY DNULLDATE) as rn
        FROM CURREN_POL cpol 
        WHERE cpol.dnulldate IS NULL AND CPOL.SCERTYPE=2
)
,ctePago as (
     SELECT CF.nbordereaux,CM.Ncurrency
       ,T11.sdescript as MonedaTransaccion
       ,T78.sdescript as FormaCobroRealizado
       ,NVL(CM.NAMOUNT,0) As ImporteRecibido 
       ,CM.NORI_CURR AS   CodMonedaOrigen
       , ROUND(
                  CASE WHEN MON.NCURRENCY = CM.Ncurrency
                       THEN NVL(CM.NORI_AMOUNT,0)
                       ELSE CASE WHEN  CM.Ncurrency = 1
                                 THEN NVL(CM.NORI_AMOUNT,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(CM.NORI_AMOUNT,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END,2) as ImporteRecibidoMO  
       ,(CM.NORI_AMOUNT * CM.NEXCHANGE) as ImporteRecibidoLO
       , CASE WHEN CM.nmov_type = 2 THEN TO_CHAR(CM.sdocnumbe) ELSE '' END As NroCheque
       , CASE WHEN CM.nmov_type IN (2,27,57) THEN CM.ddoc_date                  
              ELSE NULL
              END As FechaDeposito
       , CASE CM.nmov_type
                  WHEN 27 THEN TO_CHAR(T78.sshort_des)
                  WHEN 57 THEN TO_CHAR(T78.sshort_des)
                  ELSE ''
              END As AdministradoraTarjeta
        , CASE CM.nmov_type
                  WHEN 27 THEN TO_CHAR(CM.sdocnumbe)
                  WHEN 57 THEN TO_CHAR(CM.sdocnumbe)
                  ELSE ''
          END NroTarjeta
        ,T7.sdescript As Banco
        ,'' as NroCuenta
        ,'' As CodigoTransaccion
    FROM COLFORMREF CF
    INNER JOIN CASH_MOV CM ON CF.nbordereaux= CM.nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH= MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT
                                         AND CF.NPOLICY = MON.NPOLICY
                                         AND MON.RN=1
    LEFT JOIN TABLE11 T11 On  CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type= T78.nmov_type
    OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY , CF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
    WHERE CM.nbordereaux IS NOT NULL  
       
    UNION ALL

    SELECT CF2.nbordereaux,BM.Ncurrency
        ,T11.sdescript as MonedaTransaccion
        ,T296.sdescript as FormaCobroRealizado
        ,NVL(BM.NCASH_AMOUN,0) As ImporteRecibido 
        ,BM.NORI_CURR AS   CodMonedaOrigen
        , ROUND(
                  CASE WHEN MON.NCURRENCY = BM.Ncurrency
                       THEN NVL(BM.NORI_AMOUNT ,0)
                       ELSE CASE WHEN  BM.Ncurrency = 1
                                 THEN NVL(BM.NORI_AMOUNT ,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(BM.NORI_AMOUNT ,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END,2) as ImporteRecibidoMO 
        ,(BM.NORI_AMOUNT * BM.NEXCHANGE) as ImporteRecibidoLO    
        ,'' As NroCheque
        , CASE WHEN BM.nbordereaux IS NOT NULL THEN BM.ddoc_date
               ELSE NULL
               END As FechaDeposito
        ,'' As AdministradoraTarjeta
        ,'' As NroTarjeta
        ,T7.sdescript As Banco
        ,CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BA.SACC_NUMBER)) as NroCuenta
        ,TO_CHAR(BM.sdep_number) As CodigoTransaccion
    FROM COLFORMREF CF2
    INNER JOIN BANK_MOV BM On CF2.Nbordereaux=BM.Nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF2.NBRANCH= MON.NBRANCH AND CF2.NPRODUCT = MON.NPRODUCT
                                        AND CF2.NPOLICY = MON.NPOLICY
                                        AND MON.RN=1
    INNER JOIN TABLE11 T11 On  BM.Ncurrency = T11.ncodigint
    LEFT JOIN BANK_ACC BA On BM.NACC_BANK= BA.NACC_BANK
    LEFT JOIN TABLE7 T7 on BA.NBANK_CODE= T7.NBANK_CODE
    LEFT JOIN TABLE296 T296 ON BM.NTYPE_MOV= T296.NTYPE_MOV
    OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY , CF2.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
    WHERE  BM.nbordereaux IS NOT NULL
), cteRelacionCobro as(
   SELECT CF3.Nbordereaux 
            ,LISTAGG( TRIM(P.Nreceipt), ', ') WITHIN GROUP(ORDER BY P.NPolicy) As Nreceipt  
            ,LISTAGG( DISTINCT trim(P.NPeriod), ', ') WITHIN GROUP(ORDER BY P.NPolicy) As NroCuota           
            , MAX(P.dlimitdate) AS VencimientoDeCuota
            , SUM(ROUND(NVL(P.npremium,0),2)) ImporteCuota
            , MAX(CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PO.NRECEIPT END) As NroFactura
            , MAX(NVL(fact.DISSUEDAT,NULL)) As FechaFacturaAnterior
            , MAX(NVL(fact.NPREVBILL,0)) As NroFacturaAnterior
            , MAX(UCash.NCASHNUM) As NCASHNUM
            , MAX(INITCAP(LOWER(RTRIM(CliCaja.scliename)))) Cajero
            , MAX(EstRec.sdescript) as EstadoRecibo
            , MAX( CASE P.NTRATYPEI
                   WHEN 1 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END) as TipoCuota
            , MAX(TRIM(MPag.sdescript))  As CanalCobroRealizado            
            , MAX(To_char(TRIM(P.NPeriod))) NPeriodo
            , MAX(P.Ntype) Ntype
            , MAX(DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura')) As TipoDocumento
            
            
       FROM COLFORMREF CF3
       INNER JOIN PREMIUM_MO PO ON CF3.Nbordereaux = PO.Nbordereaux
       INNER JOIN PREMIUM P  ON PO.SCERTYPE= P.SCERTYPE
                             AND PO.NBRANCH= P.NBRANCH
                             AND PO.NPRODUCT= P.NPRODUCT
                             AND PO.NRECEIPT= P.NRECEIPT
                             AND PO.NDIGIT= P.NDIGIT
                             AND PO.NPAYNUMBE= P.NPAYNUMBE
        INNER JOIN TABLE19 EstRec ON P.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE24 TCuo ON P.NTRATYPEI= TCuo.NTRATYPEI                     
        LEFT JOIN BILLS fact ON CF3.NBordereaux = fact.NBordereaux and PO.nbillnum= fact.nbillnum
        LEFT JOIN USER_CASHNUM UCash ON CF3.NCASHNUM= UCash.NCASHNUM
        LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient        
        LEFT JOIN TABLE5002 MPag ON P.nway_pay= MPag.nway_pay
        LEFT JOIN TABLE6 Tipo ON PO.Ntype= tipo.ntype_tran
    
    WHERE 
    PO.Ntype IN (2,3,13,14,21,39,40,42)
    AND P.nstatus_pre in (2,5,6,7)
    AND NVL(CF3.nnullcode,0)=0  
    GROUP BY CF3.Nbordereaux
), cteRelacionCobroFinanciada as(
        SELECT CF2.Nbordereaux 
            , LISTAGG( PRE.Nreceipt, ', ') WITHIN GROUP(ORDER BY PRE.NPolicy) As Nreceipt  
            , LISTAGG(DISTINCT FDRA.Ndraft, ', ') WITHIN GROUP(ORDER BY PRE.NPolicy) As NroCuota           
            , MAX(CASE WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate END) AS VencimientoDeCuota
            , SUM(ROUND(CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount END,2)) ImporteCuota
            , MAX(CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE.NRECEIPT END) As NroFactura
            , MAX(NVL(fact.DISSUEDAT,NULL)) As FechaFacturaAnterior
            , MAX(NVL(fact.NPREVBILL,0)) As NroFacturaAnterior
            , MAX(UCash.NCASHNUM) As NCASHNUM
            , MAX(INITCAP(LOWER(RTRIM(CliCaja.scliename)))) Cajero
            , MAX(EstRec.sdescript) as EstadoRecibo
            , MAX( CASE PRE.NTRATYPEI
                   WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END) as TipoCuota            
            , MAX(To_char(TRIM(PRE.NPeriod))) NPeriodo
            , MAX(TRIM(MPag.sdescript))  As CanalCobroRealizado 
            , MAX(PRE.Ntype) Ntype
            , MAX(DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura')) As TipoDocumento
                        
        FROM  COLFORMREF CF2
        INNER JOIN FINANC_DRA FDRA ON CF2.NBordereaux = FDRA.NBordereaux
        INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat
                                         AND FDRA.NDRAFT= DRA_HIS.NDRAFT
                                         AND DRA_HIS.Ntype IN (2)
        INNER JOIN PREMIUM PRE ON FDRA.ncontrat = Pre.ncontrat
        INNER JOIN TABLE19 EstRec ON Pre.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE24 TCuo ON Pre.NTRATYPEI= TCuo.NTRATYPEI    
                         
        LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux 
        LEFT JOIN USER_CASHNUM UCash ON CF2.NCASHNUM= UCash.NCASHNUM
        LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient
        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay            
        WHERE PRE.nstatus_pre in (8)
               
        GROUP BY CF2.Nbordereaux 
)
SELECT 
              511 skey
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , TO_CHAR(VPOL.npolicy) AS NPOLICY
            , Vpol.FrecuenciaPago
            , TO_CHAR(cteRCob.Nreceipt) AS NRECEIPT
            , 'Nacional Seguros Vida y Salud S.A' As NombreEmpresa
            , '145776027' AS NitEmpresa
            , VPOL.LineaNegocio
            , VPOL.CanalVenta
            , VPOL.Ramo
            , VPOL.Producto
            , TRIM(VPOL.CanalCobroAsignado) AS CanalCobroAsignado
            , VPOL.CodRegionalPoliza
            , VPOL.RegionalPoliza
            , suc.noffice As CodRegionalTransaccion
            , TRIM(suc.sdescript) as RegionalCobro
            , cteRCob.NCASHNUM CodCajero
            , cteRCob.Cajero
            , cteRCob.CanalCobroRealizado as CanalCobroRealizado
            , CREF.DCollect AS FechaCobro
            , vpol.contratante Cliente
            , cteRCob.TipoCuota
            , TO_CHAR(cteRCob.NroCuota) AS NROCUOTA
            , cteRCob.VencimientoDeCuota
            , cteRCob.TipoDocumento
            , TO_CHAR(cteRCob.NroFactura)
            , ctePago.FormaCobroRealizado 
            , TO_CHAR(CREF.NBordereaux) As NroRelacionCompensacion
            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :' || To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(cteRCob.NroCuota)) As Concepto
            , Vpol.FrecuenciaPago as Perioricidad
            , ctePago.Banco 
            , ctePago.NroCuenta
            , ctePago.CodigoTransaccion
            , ctePago.NroCheque
            , ctePago.FechaDeposito
            , ctePago.AdministradoraTarjeta
            , ctePago.NroTarjeta
            , VPOL.MonedaPoliza
            , ROUND(cteRCob.ImporteCuota,2) As ImportePrimaPorCobrarMO
            , ROUND(cteRCob.ImporteCuota  * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
            , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCob.ImporteCuota,2))
                    THEN  ROUND(cteRCob.ImporteCuota,2)  
                    ELSE ROUND(ctePago.ImporteRecibidoMO,2) END as ImporteRecibidoMO   
            , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCob.ImporteCuota,2))
                    THEN  ROUND(cteRCob.ImporteCuota  * NVL(tblTipoCambio.TC,0),2)  
                    ELSE ROUND(ctePago.ImporteRecibidoLO,2) END as ImporteRecibidoML          
            , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCob.ImporteCuota,2))
                    THEN  (ROUND(ctePago.ImporteRecibidoMO,2) - ROUND(cteRCob.ImporteCuota,2)) 
                    ELSE 0 END as SaldoFavorMO  
            , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCob.ImporteCuota,2))
                    THEN  (ROUND(ctePago.ImporteRecibidoMO,2) - ROUND(cteRCob.ImporteCuota,2)) * NVL(tblTipoCambio.TC,0)
                    ELSE 0 END as SaldoFavorML 
            , 0 As RegularizacionSaldoMO
            , 0 As RegularizacionSaldoML
            , tblTipoCambio.TC as TipoCambio
            , VPol.CodTipoIntermediario
            , VPOL.TipoIntermediario As TipoIntermediario
            , VPol.CodIntermediario
            , VPOL.Intermediario As Intermediario
            , cteRCob.Ntype
            , ctePago.ncurrency as CodMonedaTransaccion
            , ctePago.MonedaTransaccion
            , cteRCob.EstadoRecibo
            , CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.FechaFacturaAnterior ELSE NULL END As FechaFacturaRecibo
            , TO_CHAR(CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.NroFacturaAnterior ELSE NULL END) AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , TO_CHAR(CREF.NCERTIF) As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
            , ctePago.ImporteRecibido as ImporteTotalRecibido
        FROM COLFORMREF CREF              
        INNER JOIN ctePago on CREF.NBordereaux = ctePago.NBordereaux
        INNER JOIN cteRelacionCobro cteRCob ON CREF.NBordereaux = cteRCob.NBordereaux 
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON 
              CREF.NBRANCH= VPOL.NBRANCH
             AND CREF.NPRODUCT= VPOL.NPRODUCT
             AND CREF.NPolicy= VPOL.NPolicy
        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
        WHERE VPOL.codFrecuenciaPago <> 8
           AND NVL(CREF.nnullcode,0)=0    
          
-------------------------------------------------------------------------------------
---- PAGOS FINANCIADOS
-------------------------------------------------------------------------------------   
UNION ALL

        SELECT
          511 skey
        , VPOL.SCertype
        , VPOL.nbranch
        , VPOL.nproduct
        , TO_CHAR(VPOL.npolicy) AS NPOLICY
        , Vpol.FrecuenciaPago
        , TO_CHAR(cteRCobF.Nreceipt) AS NRECEIPT
        , 'Nacional Seguros Vida y Salud S.A' As NombreEmpresa
        , '145776027' AS NitEmpresa
        , VPOL.LineaNegocio
        , VPOL.CanalVenta
        , VPOL.Ramo
        , VPOL.Producto
        , TRIM(VPOL.CanalCobroAsignado) AS CanalCobroAsignado
        , VPOL.CodRegionalPoliza
        , VPOL.RegionalPoliza
        , suc.noffice As CodRegionalTransaccion
        , TRIM(suc.sdescript) as RegionalCobro
        , cteRCobF.NCASHNUM CodCajero
        , cteRCobF.Cajero
        , cteRCobF.CanalCobroRealizado
        , CREF.DCollect AS FechaCobro
        , vpol.contratante Cliente
        , cteRCobF.TipoCuota
        , TO_CHAR(cteRCobF.NroCuota) AS NROCUOTA
        , cteRCobF.VencimientoDeCuota
        , cteRCobF.TipoDocumento
        , TO_CHAR(cteRCobF.NroFactura) AS NROFACTURA
        , ctePago.FormaCobroRealizado 
        , TO_CHAR(cteRCobF.NBordereaux) As NroRelacionCompensacion
        , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :' || To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(cteRCobF.NroCuota) As Concepto
        , Vpol.FrecuenciaPago as Perioricidad
        , ctePago.Banco 
        , ctePago.NroCuenta
        , ctePago.CodigoTransaccion
        , ctePago.NroCheque
        , ctePago.FechaDeposito
        , ctePago.AdministradoraTarjeta
        , ctePago.NroTarjeta
        , VPOL.MonedaPoliza
        , cteRCobF.ImporteCuota As ImportePrimaPorCobrarMO
        , cteRCobF.ImporteCuota  * NVL(tblTipoCambio.TC,0) As ImportePrimaPorCobrarML
        , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCobF.ImporteCuota,2))
                    THEN  ROUND(cteRCobF.ImporteCuota,2)  
                    ELSE ROUND(ctePago.ImporteRecibidoMO,2) END as ImporteRecibidoMO   
        , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCobF.ImporteCuota,2))
                THEN  ROUND(cteRCobF.ImporteCuota  * NVL(tblTipoCambio.TC,0),2)  
                ELSE ROUND(ctePago.ImporteRecibidoLO,2) END as ImporteRecibidoML          
        , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCobF.ImporteCuota,2))
                THEN  (ROUND(ctePago.ImporteRecibidoMO,2) - ROUND(cteRCobF.ImporteCuota,2)) 
                ELSE 0 END as SaldoFavorMO  
        , CASE WHEN  (ROUND(ctePago.ImporteRecibidoMO,2) > ROUND(cteRCobF.ImporteCuota,2))
                THEN  (ROUND(ctePago.ImporteRecibidoMO,2) - ROUND(cteRCobF.ImporteCuota,2)) * NVL(tblTipoCambio.TC,0)
                ELSE 0 END as SaldoFavorML 
        , 0 As RegularizacionSaldoMO
        , 0 As RegularizacionSaldoML
        , tblTipoCambio.TC as TipoCambio
        , VPol.CodTipoIntermediario
        , VPOL.TipoIntermediario As TipoIntermediario
        , VPol.CodIntermediario
        , VPOL.Intermediario As Intermediario
        , cteRCobF.Ntype
        , ctePago.ncurrency as CodMonedaTransaccion
        , ctePago.MonedaTransaccion
        , cteRCobF.EstadoRecibo
        , CASE WHEN NVL(cteRCobF.NroFacturaAnterior,0) <> 0 THEN cteRCobF.FechaFacturaAnterior ELSE NULL END As FechaFacturaRecibo
        , TO_CHAR(CASE WHEN NVL(cteRCobF.NroFacturaAnterior,0) <> 0 THEN cteRCobF.NroFacturaAnterior ELSE NULL END) AS NroFacturaAnterior
        , '' AS MonedaOriginalAnterior
        , TO_CHAR(CREF.NCERTIF) As NroCertificado
        , VPOL.TipoFacturaColectivo
        , VPOL.TipoDistribucion
         , ctePago.ImporteRecibido as ImporteTotalRecibido
    FROM COLFORMREF CREF 
    INNER JOIN ctePago on CREF.NBordereaux = ctePago.NBordereaux
    INNER JOIN cteRelacionCobroFinanciada cteRCobF ON CREF.NBordereaux = cteRCobF.NBordereaux 
    INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON CREF.NBRANCH= VPOL.NBRANCH
                                                     AND CREF.NPRODUCT= VPOL.NPRODUCT
                                                     AND CREF.NPolicy= VPOL.NPolicy
    INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice                   
    OUTER APPLY (
        SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
        FROM dual
    ) tblTipoCambio
    WHERE VPOL.codFrecuenciaPago = 8
    
-------------------------------------------------------------------------------------
---- PAGOS ANTICIPADA NORMAL
-------------------------------------------------------------------------------------   
UNION ALL        
        
        SELECT
              511 skey
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , TO_CHAR(VPOL.npolicy) AS NPOLICY
            , Vpol.FrecuenciaPago
            , TO_CHAR(pre.Nreceipt) AS NRECEIPT
            , 'Nacional Seguros Vida y Salud S.A' As NombreEmpresa
            , '145776027' AS NitEmpresa
            , VPOL.LineaNegocio
            , VPOL.CanalVenta
            , VPOL.Ramo
            , VPOL.Producto
            , TRIM(VPOL.CanalCobroAsignado) AS CanalCobroAsignado
            , VPOL.CodRegionalPoliza
            , VPOL.RegionalPoliza
            , suc.noffice As CodRegionalTransaccion
            , TRIM(suc.sdescript) as RegionalCobro
            , UsrCaja.NUSERCODE CodCajero
            , INITCAP(LOWER(RTRIM(CliCaja.scliename))) as Cajero
            , TRIM(MPag.sdescript) as CanalCobroRealizado
            , PRE_MO.Dcompdate AS FechaCobro
            , vpol.contratante Cliente
            , CASE PRE.NTRATYPEI
                   WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END as TipoCuota
            , TO_CHAR(pre.NPeriod) AS NROCUOTA
            , pre.dlimitdate AS VencimientoDeCuota
            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
            , TO_CHAR(CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE_MO.NRECEIPT END) As NROFACTURA
            , 'Facturacion Anticipada' as FormaCobroRealizado
            , TO_CHAR(pre_mo.NBordereaux) As NroRelacionCompensacion
            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :' || To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(pre.NPeriod)) As Concepto
            , Vpol.FrecuenciaPago as Perioricidad
            , '' As Banco
            , '' As NroCuenta
            , '' As CodigoTransaccion
            , '' As NroCheque
            , null As FechaDeposito
            , '' As AdministradoraTarjeta
            , '' NroTarjeta
            , VPOL.MonedaPoliza
            , NVL(pre.npremium,0) As ImportePrimaPorCobrarMO
            , NVL(pre.npremium,0) * NVL(tblTipoCambio.TC,0) As ImportePrimaPorCobrarML
            , NVL(PRE_MO.NAMOUNT,0) as ImporteRecibidoMO
            , NVL(PRE_MO.NAMOUNT,0) * NVL(tblTipoCambio.TC,0) as ImporteRecibidoML
            , 0 As SaldoFavorMO
            , 0 As SaldoFavorML
            , 0 As RegularizacionSaldoMO
            , 0 As RegularizacionSaldoML
            , tblTipoCambio.TC as TipoCambio
            , VPol.CodTipoIntermediario
            , VPOL.TipoIntermediario As TipoIntermediario
            , VPol.CodIntermediario
            , VPOL.Intermediario As Intermediario
            , pre.Ntype
            , pre.ncurrency as CodMonedaTransaccion
            , mon.sdescript  as MonedaTransaccion
            , EstRec.sdescript as EstadoRecibo
            , NULL as FechaFacturaRecibo
            , TO_CHAR(PRE_MO.NBILLNUM_OLD) AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , TO_CHAR(fact.NCERTIF) As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
            , NVL(pre.npremium,0) As ImporteTotalRecibido
        FROM PREMIUM PRE
        INNER JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE
             AND PRE.NBRANCH= PRE_MO.NBRANCH
             AND PRE.NPRODUCT= PRE_MO.NPRODUCT
             AND PRE.NRECEIPT= PRE_MO.NRECEIPT
             AND PRE.NDIGIT= PRE_MO.NDIGIT
             AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE
             AND PRE_MO.Ntype IN (42)
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON PRE.SCERTYPE= VPOL.SCERTYPE
             AND PRE.NBRANCH= VPOL.NBRANCH
             AND PRE.NPRODUCT= VPOL.NPRODUCT
             AND PRE.NPolicy= VPOL.NPolicy
        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE11 Mon On pre.ncurrency = mon.ncodigint
        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI
        
        
        LEFT JOIN BILLS fact ON pre_mo.nbillnum= fact.nbillnum
        LEFT JOIN USERS UsrCaja ON pre_mo.NUSERCODE= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient
        LEFT JOIN TABLE9 Suc ON UsrCaja.noffice = suc.noffice
        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay
        LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran        
        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, PRE_MO.Dcompdate) AS TC
            FROM dual
        ) tblTipoCambio
        WHERE VPOL.codFrecuenciaPago <> 8
          AND pre.nstatus_pre in (10)
-------------------------------------------------------------------------------------
---- PAGOS ANTICIPADA FINANCIADA
-------------------------------------------------------------------------------------   
UNION ALL
        SELECT
              511 skey
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , TO_CHAR(VPOL.npolicy) AS NPOLICY
            , Vpol.FrecuenciaPago
            , TO_CHAR(pre.Nreceipt) AS NRECEIPT
            , 'Nacional Seguros Vida y Salud S.A' As NombreEmpresa
            , '145776027' AS NitEmpresa
            , VPOL.LineaNegocio
            , VPOL.CanalVenta
            , VPOL.Ramo
            , VPOL.Producto
            , TRIM(VPOL.CanalCobroAsignado) AS CanalCobroAsignado
            , VPOL.CodRegionalPoliza
            , VPOL.RegionalPoliza
            , suc.noffice As CodRegionalTransaccion
            , TRIM(suc.sdescript) as RegionalCobro
            , UsrCaja.NUSERCODE CodCajero
            , INITCAP(LOWER(RTRIM(CliCaja.scliename)))  As Cajero
            , TRIM(MPag.sdescript) as CanalCobroRealizado
            , DRA_HIS.dcompdate AS FechaCobro
            , vpol.contratante Cliente
            , CASE PRE.NTRATYPEI
                   WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END as TipoCuota
            , TO_CHAR(CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft END) AS NroCuota
            , CASE WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate END AS VencimientoDeCuota
            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
            , TO_CHAR(CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE.NRECEIPT END) As NroFactura
            , 'Facturaci�n Anticipada' as FormaCobroRealizado
            , TO_CHAR(FDRA.NBordereaux) As NroRelacionCompensacion
            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :' || To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft END)) As Concepto
            , Vpol.FrecuenciaPago as Perioricidad
            , '' As Banco
            , '' As NroCuenta
            , '' As CodigoTransaccion
            , '' As NroCheque
            , null As FechaDeposito
            , '' As AdministradoraTarjeta
            , '' NroTarjeta
            , VPOL.MonedaPoliza
            , CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount END As ImportePrimaPorCobrarMO
            , (CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount END) * NVL(tblTipoCambio.TC,0) As ImportePrimaPorCobrarML
            , NVL(DRA_HIS.NAMOUNT,0) as ImporteRecibidoMO
            , NVL(DRA_HIS.NAMOUNT,0) * NVL(tblTipoCambio.TC,0) as ImporteRecibidoML
            , 0 As SaldoFavorMO
            , 0 As SaldoFavorML
            , 0 As RegularizacionSaldoMO
            , 0 As RegularizacionSaldoML
            , tblTipoCambio.TC as TipoCambio
            , VPol.CodTipoIntermediario
            , VPOL.TipoIntermediario As TipoIntermediario
            , VPol.CodIntermediario
            , VPOL.Intermediario As Intermediario
            , pre.Ntype
            , pre.ncurrency as CodMonedaTransaccion
            , mon.sdescript  as MonedaTransaccion
            , EstRec.sdescript as EstadoRecibo
            , NULL as FechaFacturaRecibo
            , TO_CHAR('0') AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , TO_CHAR(fact.NCERTIF) As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
             , NVL(DRA_HIS.NAMOUNT,0) as ImporteTotalRecibido
        FROM PREMIUM PRE
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON PRE.SCERTYPE= VPOL.SCERTYPE
             AND PRE.NBRANCH= VPOL.NBRANCH
             AND PRE.NPRODUCT= VPOL.NPRODUCT
             AND PRE.NPolicy= VPOL.NPolicy
        INNER JOIN Financ_dra FDRA On Pre.ncontrat= FDRA.ncontrat
        INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat
             AND FDRA.NDRAFT= DRA_HIS.NDRAFT
             AND DRA_HIS.Ntype IN (42)        
        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE11 Mon On pre.ncurrency = mon.ncodigint
        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI
                    
        LEFT JOIN BILLS fact ON FDRA.Nbillnum = fact.nbillnum
        LEFT JOIN USERS UsrCaja ON FDRA.NUSERCODE= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient
        LEFT JOIN TABLE9 Suc ON UsrCaja.noffice = suc.noffice
        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay
        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, DRA_HIS.dcompdate) AS TC
            FROM dual
        ) tblTipoCambio
        WHERE VPOL.codFrecuenciaPago = 8
          AND pre.nstatus_pre in (8)
 
