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
   SELECT 
    CF1.Nbordereaux
  , LISTAGG(DISTINCT TO_CHAR(NVL(F1.NBillnum, PO_AUX.nreceipt)), ', ' ON OVERFLOW TRUNCATE) 
        WITHIN GROUP(ORDER BY F1.NBillnum) AS FacturasEnRelacion
  , MAX(
        CASE 
            WHEN PO_AUX.Nbordereaux IS NOT NULL THEN
                DECODE(NVL(F1.NBILLNUM, 0), 0, 'Recibo', 
                       DECODE(NVL(tblFA.NBILLNUM, 0), 0, 'Factura', 'Factura Anticipada'))
            ELSE
                DECODE(NVL(F1.NBILLNUM, 0), 0, 'Recibo', 'Factura')
        END
    ) AS TipoDocumento 
  , MAX(tblCambioDeFactura.FechaCambioFact) AS FechaFacturaAnterior
  , MAX(tblCambioDeFactura.NroFactAnterior) AS NroFacturaAnterior

FROM COLFORMREF CF1
LEFT JOIN PREMIUM_MO PO_AUX ON CF1.Nbordereaux = PO_AUX.Nbordereaux 
                               AND NVL(PO_AUX.NNULLCODE, 0) = 0
LEFT JOIN RELCONCEPTS CON  ON CF1.NBORDEREAUX = CON.NBORDEREAUX
LEFT JOIN BILLS F1 ON CF1.Nbordereaux = F1.Nbordereaux  
                      AND F1.Nbillstat NOT IN (2)
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
         , B1.dcompdate AS FechaCambioFact
    FROM BILLS B1
    WHERE B1.NBordereaux = CF1.Nbordereaux
      AND B1.Nbillstat = 2   -- anulado
      AND B1.Nnullcode = 11  -- Cambio de Factura
) tblCambioDeFactura
WHERE  (PO_AUX.Nbordereaux IS NOT NULL OR CON.NBORDEREAUX IS NOT NULL)
   --AND CF1.Nbordereaux = 609
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
            --, RCon.NPolicy AS Npolicy_adicional  -- Campo indicador: NULL = regular, NO NULL = pago adicional
                        
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