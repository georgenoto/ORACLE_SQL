CREATE OR REPLACE PROCEDURE INSUDB.NS_INSCONTROLINGRESO511
/*-------------------------------------------------------------------------------*/
/* NOMBRE    : NS_INSCONTROLINGRESO511                                           */
/* OBJETIVO  : OBTENER INFORMACIÓN DE TODAS LAS COBRANZAS REALIZADAS             */
/* PARAMETROS: 1 -  SKEY                : LLAVE DE PROCESO                       */
/*             2 -  NSHEET       		: C¿DIGO DE INTERFAZ                     */
/*             3 -  NUSERCODE    		: C¿DIGO DE USUARIO                      */
/*             4 -  DINIDATE   	    	: FECHA DE INICIO DE LA TRANSACCION      */
/*             5 -  DENDDATE   	    	: FECHA DE INICIO DE LA TRANSACCION      */
/*             6 -  NOFFICE           	: CODIGO REGIONAL DE COBRO               */
/*             7 -  NINTERTYP  			: CODIGO TIPO DE INTERMEDIARIO           */
/*             8 -  NINTERMED   		: CODIGO DE INTERMEDIARIO                */
/*			   9 - NCASHNUM				: CODIGO DEL CAJERO						*/
/*             10 - NERROR               : CODIGO DE ERROR                       */
/*             11 - SERRORDESC          : DESCRIPCION DEL ERROR                 */
/*-------------------------------------------------------------------------------*/
   (SKEY                	T_INTERFACE.SKEY%TYPE,
	NSHEET              	MASTERSHEET.NSHEET%TYPE,
	NUSERCODE           	MASTERSHEET.NUSERCODE%TYPE,    
	DINIDATE	    		DATE,
    DENDDATE	    		DATE,
    NOFFICE     			TABLE9.NOFFICE%TYPE,
	NINTERTYP     			INTERM_TYP.NINTERTYP%TYPE,
    NINTERMED	    		INTERMEDIA.NINTERMED%TYPE,  
    NCASHNUM           		USER_CASHNUM.NCASHNUM%TYPE,   
	NERROR                  OUT T_ERR_INTERFACE.NERROR%TYPE,
    SERRORDESC              OUT VARCHAR2 
	) AUTHID CURRENT_USER AS
  NUSER_AUX		            USER_CASHNUM.NUSER%TYPE; 
BEGIN
 
     -- Borrar solo la ejecuci�n sobre la misma llave; si no existe, limpiar tabla de reporte
   DELETE FROM TIMETMP.TMP_INT511 WHERE SKEY = NS_INSCONTROLINGRESO511.SKEY;
   IF SQL%ROWCOUNT = 0 THEN
      DELETE FROM TIMETMP.TMP_INT511;
   END IF;
   --DELETE TRACE WHERE NUSERCODE = 15;
   COMMIT;
    
    
    
    --- CODIGO DE CAJERO (NCASHNUM) --- 
	NUSER_AUX := 0;
    IF NVL(NCASHNUM,0) > 0 THEN
        BEGIN
            SELECT NVL(UC.NUSER,0)
                INTO NUSER_AUX
            FROM USER_CASHNUM UC
            WHERE UC.NCASHNUM=NCASHNUM
            AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NUSER_AUX := 0; -- O el valor que desees si no existe el cajero            
        END;
    END IF;
        
    
    INSERT INTO TMP_INT511 (
                              SKEY ,
                              SCERTYPE ,
                              NBRANCH ,     --- COD. RAMO
                              NPRODUCT ,    --- COD. PRODUCTO
                              NPOLICY  ,    --- NRO. POLIZA
                              SDESPAYFREQ , --- DESC. FRECUENCIA DE PAGO
                              NRECEIPT  ,
                              SDESCOMPANY , --- NOMBRE COMPAÑIA
                              SDESNITCOMPANY , --- NIT COMPAÑIA
                              SDESBRANCHT , --- LINEA DE NEGOCIO          
                              SDESSELLCHANNEL , --- DESC. CANAL VENTA
                              SDESBRANCH , --- RAMO
                              SDESPRODUCT , --- DESC. PRODUCTO  
                              SDESWAY_PAY ,--- DESC. CANAL COBRO ASIGNADO  
                              NOFFICE  ,   --- COD. REGIONAL POLIZA
                              SDESOFFICE , --- DESC. REGIONAL POLIZA
							  NOFFICE_TRAN, --- COD. REGIONAL TRANSACCION
                              SDESOFFICE_TRAN, --- REGIONAL TRANSACCION
                              SCLIENT_C  , --- COD. CAJERO
                              SCLIENAME_C  , --- NOMBRE CAJERO
                              SDESSPAY_FORM  , --- DESC. FORMA COBRO REALIZADO
                              DCOLLECT  ,   		--- FECHA DE COBRO ****
                              SCLIENT_BILL  , --- CLIENTE
                              SDESTRATYPEI  ,--- DESC. TIPO DE CUOTA
                              NPERIOD  ,		--- NRO. CUOTA
                              DLIMITDATE ,			--- FECHA VENCIMIENTO
                              SDECBILLNUM , --- DESC. TIPO DE DOCUMENTO
                              NBILLNUM  ,	--- NRO. FACTURA O RECIBO
                              SDESMOVTYPE ,--- DESC. FORMA DE COBRO REALIZADO
                              NBORDEREAUX  ,	--- NRO. RELACION 
                              SDESCONCEPT  ,--- CONCEPTO
                              SDESPAYFREQ_AUX , --- PERIODICIDAD
                              SDESBANK	,--- DESC. BANCO
                              SACC_NUMBER, -- NRO. CUENTA
                              SDEP_NUMBER  ,	--- COD. TRANSACCION
                              SDOCNUMBE	,	--- NRO. DE CHEQUE
                              DDOC_DATE	,   --- FECHA DEPOSITO *****
                              SDESCARDADMIN	,--- DESC. ADMINISTRADORA DE TARJETA
                              SCARD	,	--- NRO. DE TARJETA
                              SCURRENCY	, -- MONEDA POLIZA
                              NPREMIUM_MO ,  -- IMPORTE POR COBRAR MONEDA ORIGEN
                              NPREMIUM_LO ,  -- IMPORTE POR COBRAR MONEDA LOCAL
                              NAMOUNT_MO  ,  -- IMPORTE RECIBIDO MONEDA ORIGEN
                              NAMOUNT_LO ,  -- IMPORTE RECIBIDO MONEDA LOCAL
                              NBALANCE_MO ,  -- SALDO A FAVOR MONEDA ORIGEN
                              NBALANCE_LO ,  -- SALDO A FAVOR MONEDA LOCAL
                              NBALANCE_AUX_MO ,  -- REGULARIZACION DE SALDO MONEDA ORIGEN
                              NBALANCE_AUX_LO ,  -- REGULARIZACION DE SALDO MONEDA LOCAL
                              NEXCHANGE	,	--- TIPO DE CAMBIO
                              NINTERTYP	,		--- COD. TIPO INTERMEDIARIO
                              SDESINTERTYP ,	--- DESC. TIPO INTERMEDIARIO
                              NINTERMED	,		--- COD.  INTERMEDIARIO
                              SDESINTERMED,     --- DESC. INTERMEDIARIO
                              NTYPE ,		--- NTYPE
                              NCURRENCY_TRA	,     --- COD. MONEDA TRANSACCION
                              SCURRENCY_TRA	, --- MONEDA TRANSACCION
                              SDESSTATUS_PRE , --- ESTADO DE RECIBO
                              DBILLDATE	, 			--- FECHA FACTURA RECIBO
                              NBILLNUM_OLD ,	--- NRO. FACTURA ANTERIOR
                              SCURRENCY_OLD,	 --- MONEDA TRANSACCION ANTERIOR 
                              NCERTIF,          --- NRO. CERTIFICADO
                              SCOLINVOT,        --- TIPO FACTURA COLECTIVO
                              STYPDIS_PAYPERCEN, --- TIPO DISTRIBUCION
                              NAMOUNT_REAL
                              
                    )
WITH cteEmpresa AS (
        SELECT NVL(TRIM(CD.SCLINUMDOCU), '1028483024') AS NIT_EMPRESA
          ,TRIM(REAGENERALPKG.REANAMECLI(CD.SCLIENT)) AS NOMBRE_EMPRESA
          , 1 Id
        FROM COMPANY CM
        INNER JOIN  CLIDOCUMENTS CD ON CM.SCLIENT = CD.SCLIENT
        WHERE CM.NCOMPANY = REAGENERALPKG.REAOPT_SYSTEM_COMPANY
) 
,cteMonedaPoliza AS(
        SELECT 
             cpol.NBRANCH,cpol.NPRODUCT, cpol.NPOLICY, cpol.NCURRENCY
            ,ROW_NUMBER() OVER(PARTITION BY  cpol.NBRANCH,cpol.NPRODUCT, cpol.NPOLICY ORDER BY DNULLDATE) as rn
        FROM CURREN_POL cpol 
        WHERE cpol.dnulldate IS NULL AND CPOL.SCERTYPE=2
) 
--- cteFormaPago, cte que busca las formas de pago por cada nbordereaux (por cada relacion de pago)
,cteFormaPago as (
     SELECT CF.nbordereaux,CM.Ncurrency
       ,T11.sdescript as MonedaTransaccion
       ,T78.sdescript as FormaCobroRealizado
       ,NVL(CM.NAMOUNT,0) As ImporteRecibido 
       ,CM.NORI_CURR AS   CodMonedaOrigen
       ,CASE WHEN MON.NCURRENCY = CM.Ncurrency
                       THEN NVL(CM.NAMOUNT,0)
                       ELSE CASE WHEN  CM.Ncurrency = 1
                                 THEN NVL(CM.NAMOUNT,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(CM.NAMOUNT,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END as ImporteRecibidoMO  
       ,CASE WHEN  CM.Ncurrency = 1
                                 THEN CM.NAMOUNT
                                 ELSE NVL(CM.NAMOUNT,0) * NVL(tblTipoCambio.TC,0)
                            END as ImporteRecibidoLO
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
                                --AND CF.NCASHNUM = CM.NCASHNUM  --- para evitar los duplicados que provienen de Sintesis
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
          AND CF.STYPE NOT IN (2)
    
    UNION ALL

    SELECT CF2.nbordereaux,BM.Ncurrency
        ,T11.sdescript as MonedaTransaccion
        ,T296.sdescript as FormaCobroRealizado
        ,NVL(BM.NCASH_AMOUN,0) As ImporteRecibido 
        ,BM.NORI_CURR AS   CodMonedaOrigen
        ,CASE WHEN MON.NCURRENCY = BM.Ncurrency
                       THEN NVL(BM.NCASH_AMOUN ,0)
                       ELSE CASE WHEN  BM.Ncurrency = 1
                                 THEN NVL(BM.NCASH_AMOUN ,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(BM.NCASH_AMOUN ,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END as ImporteRecibidoMO 
        ,CASE WHEN  BM.Ncurrency = 1
                                 THEN BM.NCASH_AMOUN
                                 ELSE NVL(BM.NCASH_AMOUN,0) * NVL(tblTipoCambio.TC,0)
                            END as ImporteRecibidoLO   
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
                                --AND CF2.NCASHNUM = BM.NCASHNUM --- para evitar los duplicados que provienen de Sintesis
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
           AND CF2.STYPE NOT IN (2)

    ---// PAGOS POR CUENTA CORRIENTE // ----- 
    UNION ALL 
    SELECT CF.nbordereaux,CM.Ncurrency
       ,T11.sdescript as MonedaTransaccion
       ,'Cargo cta.cte. cliente' as FormaCobroRealizado
       ,ABS(NVL(CM.NAMOUNT,0)) As ImporteRecibido 
       ,CM.NCURRENCY AS   CodMonedaOrigen
       ,ABS(CASE WHEN MON.NCURRENCY = CM.Ncurrency
                       THEN NVL(CM.NAMOUNT,0)
                       ELSE CASE WHEN  CM.Ncurrency = 1
                                 THEN NVL(CM.NAMOUNT,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(CM.NAMOUNT,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END) as ImporteRecibidoMO  
       ,ABS(CASE WHEN  CM.Ncurrency = 1
                                 THEN CM.NAMOUNT
                                 ELSE NVL(CM.NAMOUNT,0) * NVL(tblTipoCambio.TC,0)
                  END) as ImporteRecibidoLO
        , NULL As NroCheque
        , NULL As FechaDeposito
        , NULL As AdministradoraTarjeta
        , NULL NroTarjeta
        , NULL As Banco
        , NULL as NroCuenta
        , NULL As CodigoTransaccion
        --,CM.*
    FROM COLFORMREF CF
    INNER JOIN MOVE_ACC CM ON CF.nbordereaux= CM.nbordereaux
    INNER JOIN cteMonedaPoliza MON ON CF.NBRANCH= MON.NBRANCH AND CF.NPRODUCT = MON.NPRODUCT
                                         AND CF.NPOLICY = MON.NPOLICY
                                         AND MON.RN=1
    LEFT JOIN TABLE11 T11 On  CM.Ncurrency = T11.ncodigint
        
    OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY , CF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
    WHERE CM.nbordereaux IS NOT NULL  
          AND CF.STYPE NOT IN (2)
          AND CM.NTYPE_MOVE=17

    ---// PAGOS ADICIONALES // -----       
    UNION ALL 
    SELECT CF.nbordereaux,CM.Ncurrency
       ,T11.sdescript as MonedaTransaccion
       ,T78.sdescript as FormaCobroRealizado
       ,NVL(CM.NAMOUNT,0) As ImporteRecibido 
       ,CM.NORI_CURR AS   CodMonedaOrigen
       ,CASE WHEN MON.NCURRENCY = CM.Ncurrency
                       THEN NVL(CM.NAMOUNT,0)
                       ELSE CASE WHEN  CM.Ncurrency = 1
                                 THEN NVL(CM.NAMOUNT,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(CM.NAMOUNT,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END as ImporteRecibidoMO  
       ,CASE WHEN  CM.Ncurrency = 1
                                 THEN CM.NAMOUNT
                                 ELSE NVL(CM.NAMOUNT,0) * NVL(tblTipoCambio.TC,0)
                            END as ImporteRecibidoLO
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
    INNER JOIN RELCONCEPTS RCON ON CF.NBORDEREAUX = RCON.NBORDEREAUX
    INNER JOIN cteMonedaPoliza MON ON  RCON.NPOLICY = MON.NPOLICY
                                         AND MON.RN=1
    LEFT JOIN TABLE11 T11 On  CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type= T78.nmov_type
    OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(MON.NCURRENCY , CF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
    WHERE CM.nbordereaux IS NOT NULL  
          AND CF.STYPE NOT IN (2)          
    UNION ALL

    SELECT CF2.nbordereaux,BM.Ncurrency
        ,T11.sdescript as MonedaTransaccion
        ,T296.sdescript as FormaCobroRealizado
        ,NVL(BM.NCASH_AMOUN,0) As ImporteRecibido 
        ,BM.NORI_CURR AS   CodMonedaOrigen
        ,CASE WHEN MON.NCURRENCY = BM.Ncurrency
                       THEN NVL(BM.NCASH_AMOUN ,0)
                       ELSE CASE WHEN  BM.Ncurrency = 1
                                 THEN NVL(BM.NCASH_AMOUN ,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(BM.NCASH_AMOUN ,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END as ImporteRecibidoMO 
        ,CASE WHEN  BM.Ncurrency = 1
                                 THEN BM.NCASH_AMOUN
                                 ELSE NVL(BM.NCASH_AMOUN,0) * NVL(tblTipoCambio.TC,0)
                            END as ImporteRecibidoLO   
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
    INNER JOIN RELCONCEPTS RCON ON CF2.NBORDEREAUX = RCON.NBORDEREAUX
    INNER JOIN cteMonedaPoliza MON ON RCON.NPOLICY = MON.NPOLICY
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
           AND CF2.STYPE NOT IN (2)
           
) 
---cteFacturas_EnRelacion, se agrupan las facturas que participan en la relacion
,cteFacturas_EnRelacion as (
   SELECT CF1.Nbordereaux
        , LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum,PO_AUX.nreceipt)), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY F1.NBillnum) As FacturasEnRelacion
        , MAX(DECODE(NVL(F1.NBILLNUM,0),0,'Recibo', DECODE(NVL(tblFA.NBILLNUM,0),0,'Factura','Factura Anticipada'))) As TipoDocumento 
        , MAX(NVL(tblCambioDeFactura.FechaCambioFact,NULL)) As FechaFacturaAnterior
        , MAX(NVL(tblCambioDeFactura.NroFactAnterior,NULL)) As NroFacturaAnterior
    FROM COLFORMREF CF1
    INNER JOIN PREMIUM_MO PO_AUX  ON CF1.Nbordereaux = PO_AUX.Nbordereaux
    LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux AND F1.Nbillstat not in (2)
    OUTER APPLY (
         SELECT PO_AUX2.NBILLNUM 
         FROM PREMIUM_MO  PO_AUX2 
         WHERE PO_AUX2.nreceipt = PO_AUX.nreceipt 
                AND PO_AUX2.NBILLNUM= PO_AUX.NBILLNUM 
                AND PO_AUX2.NTYPE IN (42)                   
                AND NVL(PO_AUX2.NNULLCODE,0)=0
    )tblFA
    OUTER APPLY (
        SELECT B1.NBILLNUM As NroFactAnterior
               ,B1.dcompdate as FechaCambioFact
        FROM BILLS B1
        WHERE B1.NBordereaux=CF1.Nbordereaux
        AND B1.Nbillstat= 2 -- anulado
        AND B1.Nnullcode= 11 -- Cambio de Factura
    )tblCambioDeFactura
    WHERE NVL(PO_AUX.NNULLCODE,0)=0 
    --AND F1.Nbillstat not in (2) -- Anulado 
    --and CF1.Nbordereaux=226
    GROUP BY CF1.Nbordereaux
    
    UNION ALL
   ---// PAGOS ADICIONALES // -----
    SELECT CF1.Nbordereaux
        , LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum,'')), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY F1.NBillnum) As FacturasEnRelacion
        , MAX(DECODE(NVL(F1.NBILLNUM,0),0,'Recibo', 'Factura')) As TipoDocumento 
        , NULL As FechaFacturaAnterior
        , NULL As NroFacturaAnterior
    FROM COLFORMREF CF1
    INNER JOIN RELCONCEPTS CON ON CF1.NBORDEREAUX = CON.NBORDEREAUX
    LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux
    WHERE F1.Nbillstat not in (2) -- Anulado 
    GROUP BY CF1.Nbordereaux
) 
---cteRecibos_EnRelacion, se agrupan los recibos que participan en la relacion
,cteRecibos_EnRelacion as (
   SELECT CF1.Nbordereaux
        , LISTAGG(DISTINCT TO_CHAR(NVL(PO_AUX.Nreceipt,'')), ', ' ON OVERFLOW TRUNCATE) WITHIN GROUP(ORDER BY PO_AUX.Nreceipt) As RecibosEnRelacion        
        , count(PO_AUX.Nreceipt) cantRecibos
    FROM COLFORMREF CF1
    INNER JOIN PREMIUM_MO PO_AUX  ON CF1.Nbordereaux = PO_AUX.Nbordereaux    
    WHERE NVL(PO_AUX.NNULLCODE,0)=0     
    GROUP BY CF1.Nbordereaux
)  
--cteDatosRecibo, busca a los recibos a los cuales afecta la relacion de pago.
, cteDatosRecibo as(
   SELECT CF3.Nbordereaux 
            , TRIM(P.Nreceipt) As Nreceipt  
            , TRIM(P.NPeriod) As NroCuota           
            , P.dlimitdate AS FechaVencimiento
            , ROUND(NVL(P.npremium,0),2) ImporteCuota
            , DECODE(NVL(PO.NBILLNUM,0),0,TRIM (cteFRel.FacturasEnRelacion), TRIM(PO.NBILLNUM))  As NroFactura
            , NVL(cteFRel.FechaFacturaAnterior,NULL) As FechaFacturaAnterior
            , NVL(cteFRel.NroFacturaAnterior,0) As NroFacturaAnterior
            , UCash.NCASHNUM As NCASHNUM
            , INITCAP(LOWER(RTRIM(CliCaja.scliename))) as Cajero
            , EstRec.sdescript as EstadoRecibo
            , CASE P.NTRATYPEI
                   WHEN 1 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END as TipoCuota
            , TRIM(MPag.sdescript)  As CanalCobroRealizado            
            , To_char(TRIM(P.NPeriod)) NPeriodo
            , P.Ntype Ntype
            , TRIM(cteFRel.TipoDocumento) As TipoDocumento  
            , TRIM(cteRRel.RecibosEnRelacion) as RecibosEnRelacion
            , TRIM (cteFRel.FacturasEnRelacion) as   FacturasEnRelacion                    
   FROM COLFORMREF CF3
   INNER JOIN PREMIUM_MO PO ON CF3.Nbordereaux = PO.Nbordereaux
   INNER JOIN PREMIUM P  ON PO.SCERTYPE= P.SCERTYPE
                         AND PO.NBRANCH= P.NBRANCH
                         AND PO.NPRODUCT= P.NPRODUCT
                         AND PO.NRECEIPT= P.NRECEIPT
                         AND PO.NDIGIT= P.NDIGIT
                         AND PO.NPAYNUMBE= P.NPAYNUMBE
    INNER JOIN cteRecibos_EnRelacion cteRRel on CF3.Nbordereaux = cteRRel.Nbordereaux
    LEFT JOIN cteFacturas_EnRelacion cteFRel on CF3.Nbordereaux = cteFRel.Nbordereaux
    INNER JOIN TABLE19 EstRec ON P.nstatus_pre= EstRec.nstatus_pre
    INNER JOIN TABLE24 TCuo ON P.NTRATYPEI= TCuo.NTRATYPEI                     
    --LEFT JOIN BILLS fact ON CF3.NBordereaux = fact.NBordereaux                             
    INNER JOIN USER_CASHNUM UCash ON CF3.NCASHNUM= UCash.NCASHNUM
    INNER JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
    INNER JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient        
    LEFT JOIN TABLE5002 MPag ON P.nway_pay= MPag.nway_pay
    LEFT JOIN TABLE6 Tipo ON PO.Ntype= tipo.ntype_tran

    WHERE 
    PO.Ntype IN (2,13,14,21,39,40) --42 FACT. ANTICIPADA; 3= devolucion de prima --> Se quitan
    AND P.nstatus_pre in (2,5,6,7)    
    AND NVL(CF3.nnullcode,0)=0  
    AND CF3.STYPE NOT IN (2)
    
   UNION ALL

    SELECT CF2.Nbordereaux 
        , TRIM(PRE.Nreceipt) As Nreceipt  
        , TRIM(FDRA.Ndraft) As NroCuota           
        , FDRA.dlimitdate AS FechaVencimiento
        , ROUND(FDRA.namount,2) ImporteCuota
        , TRIM(fact.NBILLNUM) As NroFactura
        , NVL(fact.DISSUEDAT,NULL) As FechaFacturaAnterior
        , NVL(fact.NPREVBILL,0) As NroFacturaAnterior
        , UCash.NCASHNUM As NCASHNUM
        , INITCAP(LOWER(RTRIM(CliCaja.scliename))) as Cajero
        , EstRec.sdescript as EstadoRecibo
        , CASE PRE.NTRATYPEI
               WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
               WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
               WHEN 3 THEN 'Anexo'
               WHEN 4 THEN 'Anexo de resicion de contrato'
               WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
               WHEN 12 THEN 'Anexo de rehabilitacion'
               ELSE TRIM(TCuo.sdescript)
          END as TipoCuota            
        , To_char(TRIM(PRE.NPeriod)) NPeriodo
        , TRIM(MPag.sdescript)  As CanalCobroRealizado 
        , PRE.Ntype Ntype       
        , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo', DECODE(NVL(tblFA.NBILLNUM,0),0,'Factura','Factura Anticipada')) As TipoDocumento
        , TRIM(PRE.Nreceipt) as RecibosEnRelacion
        , TRIM (fact.NBILLNUM) as   FacturasEnRelacion           
    FROM  COLFORMREF CF2
    INNER JOIN FINANC_DRA FDRA ON CF2.NBordereaux = FDRA.NBordereaux
    INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat
                                     AND FDRA.NDRAFT= DRA_HIS.NDRAFT
                                     AND DRA_HIS.Ntype IN (2)
    INNER JOIN PREMIUM PRE ON FDRA.ncontrat = Pre.ncontrat
    INNER JOIN TABLE19 EstRec ON Pre.nstatus_pre= EstRec.nstatus_pre
    INNER JOIN TABLE24 TCuo ON Pre.NTRATYPEI= TCuo.NTRATYPEI                             
    LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux                                 
    INNER JOIN USER_CASHNUM UCash ON CF2.NCASHNUM= UCash.NCASHNUM
    INNER JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
    INNER JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient
    LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay   
    OUTER APPLY (
         SELECT DRA_HIS2.NBILLNUM 
         FROM DRAFT_HIST  DRA_HIS2 
         WHERE FDRA.ncontrat= DRA_HIS2.ncontrat
               AND FDRA.NDRAFT= DRA_HIS2.NDRAFT
               AND DRA_HIS.Ntype IN (42)             
    )tblFA         
    WHERE PRE.nstatus_pre in (8)        
    AND CF2.STYPE NOT IN (2)  --- SE QUITA EGRESO-DEVOLUCION DE PRIMA  
    AND fact.Nbillstat not in (2) -- Anulado    
    
    ---// PAGOS ADICIONALES // -----    
    UNION ALL
    
    SELECT CF3.Nbordereaux 
            , '0' As Nreceipt  
            , TRIM(RCON.NTRANSAC) As NroCuota            
            , RCON.DVALDATE AS FechaVencimiento
            , ROUND(NVL(RCON.NAMOUNT,0),2) ImporteCuota
            , TRIM(fact.NBILLNUM)  As NroFactura
            , NVL(cteFRel.FechaFacturaAnterior,NULL) As FechaFacturaAnterior
            , NVL(cteFRel.NroFacturaAnterior,0) As NroFacturaAnterior
            , UCash.NCASHNUM As NCASHNUM
            , INITCAP(LOWER(RTRIM(CliCaja.scliename))) as Cajero
            , CASE WHEN CF3.SSTATUS = 1 THEN 'Pagado' ELSE 'Inactivo' END as EstadoRecibo
            , TRIM(TCuo.SDESCRIPT) as TipoCuota
            , TRIM(CPag.SDESCRIPT)  As CanalCobroRealizado 
            , To_char(TRIM(RCON.NTRANSAC)) NPeriodo                       
            , 1 Ntype
            , TRIM(cteFRel.TipoDocumento) As TipoDocumento   
            , TRIM(cteRRel.RecibosEnRelacion) as RecibosEnRelacion
            , TRIM (cteFRel.FacturasEnRelacion) as   FacturasEnRelacion                    
   FROM COLFORMREF CF3
    INNER JOIN RELCONCEPTS RCON ON CF3.Nbordereaux = RCON.Nbordereaux  
    LEFT JOIN cteRecibos_EnRelacion cteRRel on CF3.Nbordereaux = cteRRel.Nbordereaux
    LEFT JOIN cteFacturas_EnRelacion cteFRel on CF3.Nbordereaux = cteFRel.Nbordereaux
    --INNER JOIN TABLE19 EstRec ON P.nstatus_pre= EstRec.nstatus_pre
    INNER JOIN TABLE22 TCuo ON RCON.NCONCEPT= TCuo.NCONCEPT                     
    INNER JOIN BILLS fact ON CF3.NBordereaux = fact.NBordereaux                             
    INNER JOIN USER_CASHNUM UCash ON CF3.NCASHNUM= UCash.NCASHNUM
    INNER JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
    INNER JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient        
    LEFT JOIN TABLE5554 CPag ON CF3.NINPUTTYP= CPag.NINPUTTYP
   WHERE 
    NVL(CF3.nnullcode,0)=0  
    AND CF3.STYPE NOT IN (2)   
) 
--cteContadorFPago, contador para poder verificar si tiene 1 o varias formas de pago
,cteContadorFPago AS (
    SELECT ctefc.NBordereaux
    ,count(ctefc.nbordereaux) as cantFPago
    FROM cteFormaPago ctefc
    group by ctefc.nbordereaux
)
--cteContadorRecibos, contador para verificar si la relacion de pago afecta a 1 o varios recibos
,cteContadorRecibos AS (
   SELECT cterc.NBordereaux
    ,count(cterc.nbordereaux) as cantRec    
    FROM cteDatosRecibo cterc
    group by cterc.nbordereaux
)
--cteContadorGeneral, agrupa los contadores de formas de pago y recibos en un solo cte
,cteContadorGeneral as(
select  cref.NBordereaux, cfp.cantFPago, cre.cantRec
from COLFORMREF cref
left join cteContadorFPago cfp on cref.NBordereaux = cfp.NBordereaux
left join cteContadorRecibos cre on cref.NBordereaux = cre.NBordereaux
where NVL(cref.NNULLCODE,0)=0 
)
-- cteDatosReciboAgrupado, se agrupa si la relacion de pago afecta a varios recibos, caso contrario se muestra detalle del pago individual.
, cteDatosReciboAgrupado AS(
    SELECT cterc.NBordereaux, cterc.NReceipt, cterc.NroCuota,cterc.FechaVencimiento, cterc.ImporteCuota
            , cterc.NroFactura, cterc.FechaFacturaAnterior, cterc.NroFacturaAnterior, cterc.NCashnum, cterc.Cajero
            , cterc.EstadoRecibo, cterc.TipoCuota, cterc.CanalCobroRealizado, cterc.Nperiodo, cterc.Ntype
            , cterc.TipoDocumento
            , cterc.NReceipt as RecibosEnRelacion 
            , cterc.NroFactura as FacturasEnRelacion 
            , cteFormaPago.FormaCobroRealizado 
            , cteFormaPago.Banco 
            , cteFormaPago.NroCuenta
            , cteFormaPago.CodigoTransaccion
            , cteFormaPago.NroCheque
            , cteFormaPago.FechaDeposito
            , cteFormaPago.AdministradoraTarjeta
            , cteFormaPago.NroTarjeta
            , tdoc.Namount as ImporteRecibidoMO   
            , (tdoc.Namount * nexchange) as ImporteRecibidoML  
            , cteFormaPago.ncurrency as CodMonedaTransaccion
            , cteFormaPago.MonedaTransaccion 
            , cteFormaPago.ImporteRecibido as ImporteTotalRecibido
            ,CASE WHEN  ABS(ROUND(cterc.ImporteCuota,2)  - ROUND(tdoc.Namount,2)) > 0.5
                    THEN  ABS(ROUND(cterc.ImporteCuota,2)  - ROUND(tdoc.Namount,2))
                    ELSE 0 END as SaldoFavorMO         
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormaPago on cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadorGeneral cteaux on cterc.NBordereaux = cteaux.NBordereaux
    INNER JOIN TRELDOC tdoc on   cterc.NBordereaux = tdoc.NBordereaux and cterc.NReceipt = tdoc.NReceipt
    WHERE  (cteaux.cantFPago = 1 and  cteaux.cantRec >= 1)
           OR  (cteaux.cantFPago > 1 and  cteaux.cantRec = 1) 
    
    UNION ALL
    
    SELECT cterc.NBordereaux
           , LISTAGG(DISTINCT TRIM(cterc.NReceipt), ', ') WITHIN GROUP(ORDER BY cterc.NReceipt) As Nreceipt 
           , LISTAGG(DISTINCT TRIM(cterc.NroCuota), ', ') WITHIN GROUP(ORDER BY cterc.NroCuota) As NroCuota 
           , MAX(cterc.FechaVencimiento) as FechaVencimiento
           , SUM(cterc.ImporteCuota) as ImporteCuota
           , LISTAGG(DISTINCT TRIM(cterc.NroFactura), ', ') WITHIN GROUP(ORDER BY cterc.NroFactura) As NroFactura
           , MAX(cterc.FechaFacturaAnterior) As FechaFacturaAnterior
           , MAX(cterc.NroFacturaAnterior) As NroFacturaAnterior
           , MAX(cterc.NCashnum) As NCashnum
           , MAX(cterc.Cajero) As Cajero
           , MAX(cterc.EstadoRecibo) As EstadoRecibo
           , MAX(cterc.TipoCuota) As TipoCuota
           , MAX(cterc.CanalCobroRealizado) As CanalCobroRealizado
           , MAX(cterc.Nperiodo) As Nperiodo
           , MAX(cterc.Ntype) As Ntype
           , MAX(cterc.TipoDocumento) As TipoDocumento
           , MAX(cterc.RecibosEnRelacion) as RecibosEnRelacion 
           , MAX(cterc.FacturasEnRelacion) as RecibosEnRelacion
           , cteFormaPago.FormaCobroRealizado  as FormaCobroRealizado
           , MAX(cteFormaPago.Banco ) as Banco
           , MAX(cteFormaPago.NroCuenta) as NroCuenta
            , MAX(cteFormaPago.CodigoTransaccion) as CodigoTransaccion
            , MAX(cteFormaPago.NroCheque) as NroCheque
            , MAX(cteFormaPago.FechaDeposito  ) as FechaDeposito
           , MAX(cteFormaPago.AdministradoraTarjeta) as AdministradoraTarjeta
           , MAX(cteFormaPago.NroTarjeta) as  NroTarjeta
           , MAX(cteFormaPago.ImporteRecibidoMO) as ImporteRecibidoMO   
           , MAX(cteFormaPago.ImporteRecibidoLO) as ImporteRecibidoML
           , MAX(cteFormaPago.ncurrency) as CodMonedaTransaccion
           , MAX(cteFormaPago.MonedaTransaccion)  as MonedaTransaccion
           , MAX(cteFormaPago.ImporteRecibido) as ImporteTotalRecibido
           , 0 as SaldoFavorMO
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormaPago on cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadorGeneral cteaux on cterc.NBordereaux = cteaux.NBordereaux
    WHERE cteaux.cantFPago > 1 and  cteaux.cantRec > 1 
    GROUP BY cterc.NBordereaux,cteFormaPago.FormaCobroRealizado
    ---// PAGOS ADICIONALES // -----
    UNION ALL
    SELECT cterc.NBordereaux, cterc.NReceipt, cterc.NroCuota,cterc.FechaVencimiento, cterc.ImporteCuota
            , cterc.NroFactura, cterc.FechaFacturaAnterior, cterc.NroFacturaAnterior, cterc.NCashnum, cterc.Cajero
            , cterc.EstadoRecibo, cterc.TipoCuota, cterc.CanalCobroRealizado, cterc.Nperiodo, cterc.Ntype
            , cterc.TipoDocumento
            , cterc.NReceipt as RecibosEnRelacion 
            , cterc.NroFactura as FacturasEnRelacion 
            , cteFormaPago.FormaCobroRealizado 
            , cteFormaPago.Banco 
            , cteFormaPago.NroCuenta
            , cteFormaPago.CodigoTransaccion
            , cteFormaPago.NroCheque
            , cteFormaPago.FechaDeposito
            , cteFormaPago.AdministradoraTarjeta
            , cteFormaPago.NroTarjeta
            , cteFormaPago.ImporteRecibidoMO as ImporteRecibidoMO   
            , cteFormaPago.ImporteRecibidoLO as ImporteRecibidoML  
            , cteFormaPago.ncurrency as CodMonedaTransaccion
            , cteFormaPago.MonedaTransaccion 
            , cteFormaPago.ImporteRecibido as ImporteTotalRecibido
            , 0  as SaldoFavorMO         
    FROM cteDatosRecibo cterc
    INNER JOIN cteFormaPago on cterc.NBordereaux = cteFormaPago.NBordereaux
    INNER JOIN cteContadorGeneral cteaux on cterc.NBordereaux = cteaux.NBordereaux
    INNER JOIN RELCONCEPTS RCon on   cterc.NBordereaux = RCon.NBordereaux
    WHERE  (cteaux.cantFPago = 1 and  cteaux.cantRec >= 1)
           OR  (cteaux.cantFPago > 1 and  cteaux.cantRec = 1)     
    
)
SELECT 
              NS_INSCONTROLINGRESO511.SKEY SKEY
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , TO_CHAR(VPOL.npolicy) AS NPOLICY
            , Vpol.FrecuenciaPago
            , TO_CHAR(cteRCob.RecibosEnRelacion) AS NRECEIPT
            , cteEmpresa.NOMBRE_EMPRESA As NombreEmpresa
            , TO_CHAR(cteEmpresa.NIT_EMPRESA) AS NitEmpresa
            , VPOL.LineaNegocio
            , VPOL.CanalVenta
            , VPOL.Ramo
            , TO_CHAR(VPOL.nproduct) || '-' ||VPOL.Producto as Producto
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
            , TO_CHAR(cteRCob.NroCuota) AS NroCuota
            , cteRCob.FechaVencimiento
            , cteRCob.TipoDocumento
            , TO_CHAR(cteRCob.FacturasEnRelacion) As NroFactura
            , cteRCob.FormaCobroRealizado 
            , TO_CHAR(CREF.NBordereaux) As NroRelacionCompensacion
            , 'Producto:'|| VPOL.Producto ||' | Nro. Poliza:' || To_char(TRIM(VPOL.NroPoliza))|| ' | Tipo Cuota:' || to_char(cteRCob.TipoCuota)  || ' | Nro. Cuota: ' || To_char(TRIM(cteRCob.NroCuota)) As Concepto
            , Vpol.FrecuenciaPago as Perioricidad
            , cteRCob.Banco 
            , cteRCob.NroCuenta
            , cteRCob.CodigoTransaccion
            , cteRCob.NroCheque
            , cteRCob.FechaDeposito
            , cteRCob.AdministradoraTarjeta
            , cteRCob.NroTarjeta
            , VPOL.MonedaPoliza
            , ROUND(cteRCob.ImporteCuota,2) As ImportePrimaPorCobrarMO
            , ROUND(cteRCob.ImporteCuota  * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
            , ROUND(cteRCob.ImporteRecibidoMO,2)  AS  ImporteRecibidoMO
            , ROUND(cteRCob.ImporteRecibidoML ,2)   AS  ImporteRecibidoML  
            , ROUND(cteRCob.SaldoFavorMO ,2)   AS  SaldoFavorMO           
            , ROUND(cteRCob.SaldoFavorMO ,2) * NVL(tblTipoCambio.TC,0)  AS SaldoFavorML       
            , 0 As RegularizacionSaldoMO
            , 0 As RegularizacionSaldoML
            , tblTipoCambio.TC as TipoCambio
            , VPol.CodTipoIntermediario
            , VPOL.TipoIntermediario As TipoIntermediario
            , VPol.CodIntermediario
            , VPOL.Intermediario As Intermediario
            , cteRCob.Ntype
            , cteRCob.CodMonedaTransaccion
            , cteRCob.MonedaTransaccion
            , cteRCob.EstadoRecibo
            , CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.FechaFacturaAnterior ELSE NULL END As FechaFacturaRecibo
            , TO_CHAR(CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.NroFacturaAnterior ELSE NULL END) AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , TO_CHAR(CREF.NCERTIF) As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
            , cteRCob.ImporteTotalRecibido as ImporteTotalRecibido
        FROM COLFORMREF CREF                      
        INNER JOIN cteDatosReciboAgrupado cteRCob ON CREF.NBordereaux = cteRCob.NBordereaux 
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON 
              CREF.NBRANCH= VPOL.NBRANCH
             AND CREF.NPRODUCT= VPOL.NPRODUCT
             AND CREF.NPolicy= VPOL.NPolicy
        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
        INNER JOIN cteEmpresa ON cteEmpresa.Id=1
        WHERE NVL(CREF.nnullcode,0)=0               		                                     		             
        --parametros>                  
        AND  CREF.DCollect BETWEEN NS_INSCONTROLINGRESO511.DINIDATE AND NS_INSCONTROLINGRESO511.DENDDATE			
        AND nvl(CREF.noffice,0) = CASE WHEN NVL(NS_INSCONTROLINGRESO511.NOFFICE,0)=0 THEN nvl(CREF.noffice,0)  ELSE NS_INSCONTROLINGRESO511.NOFFICE END 
        AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NS_INSCONTROLINGRESO511.NINTERTYP=0 
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP IS NULL
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP = 999
                                             THEN NVL(VPol.CodTipoIntermediario,0)ELSE NS_INSCONTROLINGRESO511.NINTERTYP END 
        AND NVL(VPol.CodIntermediario,0) = CASE WHEN NS_INSCONTROLINGRESO511.NINTERMED=0 
                                                 OR NS_INSCONTROLINGRESO511.NINTERMED IS NULL
                                            THEN NVL(VPol.CodIntermediario,0)  ELSE NS_INSCONTROLINGRESO511.NINTERMED END 			
        AND NVL(cteRCob.NCASHNUM,0) = CASE WHEN  NVL(NS_INSCONTROLINGRESO511.NCASHNUM,0) = 0 THEN NVL(cteRCob.NCASHNUM,0) ELSE NS_INSCONTROLINGRESO511.NCASHNUM  END
        
    ---// PAGOS ADICIONALES // -----
    UNION ALL
    
        SELECT 
              NS_INSCONTROLINGRESO511.SKEY SKEY
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , TO_CHAR(VPOL.npolicy) AS NPOLICY
            , Vpol.FrecuenciaPago
            , TO_CHAR(cteRCob.RecibosEnRelacion) AS NRECEIPT
            , cteEmpresa.NOMBRE_EMPRESA As NombreEmpresa
            , TO_CHAR(cteEmpresa.NIT_EMPRESA) AS NitEmpresa
            , VPOL.LineaNegocio
            , VPOL.CanalVenta
            , VPOL.Ramo
            , TO_CHAR(VPOL.nproduct) || '-' ||VPOL.Producto as Producto
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
            , TO_CHAR(cteRCob.NroCuota) AS NroCuota
            , cteRCob.FechaVencimiento
            , cteRCob.TipoDocumento
            , TO_CHAR(cteRCob.FacturasEnRelacion) As NroFactura
            , cteRCob.FormaCobroRealizado 
            , TO_CHAR(CREF.NBordereaux) As NroRelacionCompensacion
            , 'Producto:'|| VPOL.Producto ||' | Nro. Poliza:' || To_char(TRIM(VPOL.NroPoliza))|| ' | Tipo Cuota:' || to_char(cteRCob.TipoCuota)  || ' | Nro. Cuota: ' || To_char(TRIM(cteRCob.NroCuota)) As Concepto
            , Vpol.FrecuenciaPago as Perioricidad
            , cteRCob.Banco 
            , cteRCob.NroCuenta
            , cteRCob.CodigoTransaccion
            , cteRCob.NroCheque
            , cteRCob.FechaDeposito
            , cteRCob.AdministradoraTarjeta
            , cteRCob.NroTarjeta
            , VPOL.MonedaPoliza
            , ROUND(cteRCob.ImporteCuota,2) As ImportePrimaPorCobrarMO
            , ROUND(cteRCob.ImporteCuota  * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
            , ROUND(cteRCob.ImporteRecibidoMO,2)  AS  ImporteRecibidoMO
            , ROUND(cteRCob.ImporteRecibidoML ,2)   AS  ImporteRecibidoML  
            , ROUND(cteRCob.SaldoFavorMO ,2)   AS  SaldoFavorMO           
            , ROUND(cteRCob.SaldoFavorMO ,2) * NVL(tblTipoCambio.TC,0)  AS SaldoFavorML       
            , 0 As RegularizacionSaldoMO
            , 0 As RegularizacionSaldoML
            , tblTipoCambio.TC as TipoCambio
            , VPol.CodTipoIntermediario
            , VPOL.TipoIntermediario As TipoIntermediario
            , VPol.CodIntermediario
            , VPOL.Intermediario As Intermediario
            , cteRCob.Ntype
            , cteRCob.CodMonedaTransaccion
            , cteRCob.MonedaTransaccion
            , cteRCob.EstadoRecibo
            , CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.FechaFacturaAnterior ELSE NULL END As FechaFacturaRecibo
            , TO_CHAR(CASE WHEN NVL(cteRCob.NroFacturaAnterior,0) <> 0 THEN cteRCob.NroFacturaAnterior ELSE NULL END) AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , TO_CHAR(CREF.NCERTIF) As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
            , cteRCob.ImporteTotalRecibido as ImporteTotalRecibido
        FROM COLFORMREF CREF                              
        INNER JOIN cteDatosReciboAgrupado cteRCob ON CREF.NBordereaux = cteRCob.NBordereaux 
        INNER JOIN RELCONCEPTS RCon on   CREF.NBordereaux = RCon.NBordereaux
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  RCon.NPolicy= VPOL.NPolicy
        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
        INNER JOIN cteEmpresa ON cteEmpresa.Id=1
        WHERE NVL(CREF.nnullcode,0)=0    
        --parametros>                  
        AND  CREF.DCollect BETWEEN NS_INSCONTROLINGRESO511.DINIDATE AND NS_INSCONTROLINGRESO511.DENDDATE			
        AND nvl(CREF.noffice,0) = CASE WHEN NVL(NS_INSCONTROLINGRESO511.NOFFICE,0)=0 THEN nvl(CREF.noffice,0)  ELSE NS_INSCONTROLINGRESO511.NOFFICE END 
        AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NS_INSCONTROLINGRESO511.NINTERTYP=0 
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP IS NULL
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP = 999
                                             THEN NVL(VPol.CodTipoIntermediario,0)ELSE NS_INSCONTROLINGRESO511.NINTERTYP END 
        AND NVL(VPol.CodIntermediario,0) = CASE WHEN NS_INSCONTROLINGRESO511.NINTERMED=0 
                                                 OR NS_INSCONTROLINGRESO511.NINTERMED IS NULL
                                            THEN NVL(VPol.CodIntermediario,0)  ELSE NS_INSCONTROLINGRESO511.NINTERMED END 			
        AND NVL(cteRCob.NCASHNUM,0) = CASE WHEN  NVL(NS_INSCONTROLINGRESO511.NCASHNUM,0) = 0 THEN NVL(cteRCob.NCASHNUM,0) ELSE NS_INSCONTROLINGRESO511.NCASHNUM  END;
    
        
        		
      COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NERROR := SQLCODE;
        SERRORDESC := SQLERRM;
        CRETRACE2('ERR TMP_INT511', 593, SERRORDESC);  
        
        RAISE;    
END NS_INSCONTROLINGRESO511;

