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
 
    DELETE  FROM TMP_INT511;
    --WHERE SKEY = NS_INSCONTROLINGRESO511.SKEY;
     
    DELETE TRACE WHERE NUSERCODE = 15;
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
                              STYPDIS_PAYPERCEN --- TIPO DISTRIBUCION
                              
                    )
-------------------------------------------------------------------------------------
---- PAGOS ORIGINALES Y ANTICIPADOS UNIFICADOS
-------------------------------------------------------------------------------------
WITH ctePago as (
     SELECT CF.nbordereaux,CM.Ncurrency
       ,T11.sdescript as MonedaTransaccion
       ,T78.sdescript as FormaCobroRealizado
       ,NVL(CM.NAMOUNT,0) As ImporteRecibido 
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
    LEFT JOIN TABLE11 T11 On  CM.Ncurrency = T11.ncodigint
    LEFT JOIN TABLE7 T7 ON CM.nbank_code = T7.Nbank_code
    LEFT JOIN TABLE78 T78 ON CM.nmov_type= T78.nmov_type
    WHERE CM.nbordereaux IS NOT NULL 

    UNION ALL

    SELECT CF2.nbordereaux,BM.Ncurrency
        ,T11.sdescript as MonedaTransaccion
        ,T296.sdescript as FormaCobroRealizado
        ,NVL(BM.NCASH_AMOUN,0) As ImporteRecibido       
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
    INNER JOIN TABLE11 T11 On  BM.Ncurrency = T11.ncodigint
    LEFT JOIN BANK_ACC BA On BM.NACC_BANK= BA.NACC_BANK
    LEFT JOIN TABLE7 T7 on BA.NBANK_CODE= T7.NBANK_CODE
    LEFT JOIN TABLE296 T296 ON BM.NTYPE_MOV= T296.NTYPE_MOV
    WHERE  BM.nbordereaux IS NOT NULL
) 
SELECT
              NS_INSCONTROLINGRESO511.SKEY 
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , VPOL.npolicy
            , Vpol.FrecuenciaPago
            , pre.Nreceipt
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
            , UCash.NCASHNUM CodCajero
            , INITCAP(LOWER(RTRIM(CliCaja.scliename))) Cajero
            , TRIM(MPag.sdescript) as CanalCobroRealizado
            , CREF.DCollect AS FechaCobro
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
            , pre.NPeriod  AS NroCuota
            , pre.dlimitdate AS VencimientoDeCuota
            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
            , CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE_MO.NRECEIPT END As NroFactura
            , ctePago.FormaCobroRealizado as FormaCobroRealizado
            , CREF.NBordereaux As NroRelacionCompensacion
            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :' || To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(pre.NPeriod)) As Concepto
            , Vpol.FrecuenciaPago as Perioricidad
            , ctePago.Banco 
            , ctePago.NroCuenta
            , ctePago.CodigoTransaccion
            , ctePago.NroCheque
            , ctePago.FechaDeposito
            , ctePago.AdministradoraTarjeta
            , ctePago.NroTarjeta
            , VPOL.MonedaPoliza
            , ROUND(NVL(pre.npremium,0),2) As ImportePrimaPorCobrarMO
            , ROUND(NVL(pre.npremium,0) * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
            , ROUND(
                  CASE WHEN Vpol.codMonedaPoliza = ctePago.Ncurrency
                       THEN NVL(ctePago.ImporteRecibido,0)
                       ELSE CASE WHEN  ctePago.Ncurrency = 1
                                 THEN NVL(ctePago.ImporteRecibido,0) / NVL(tblTipoCambio.TC,0)
                                 ELSE NVL(ctePago.ImporteRecibido,0) * NVL(tblTipoCambio.TC,0)
                            END
                  END,2) as ImporteRecibidoMO            
            , ROUND(
                  CASE WHEN ctePago.Ncurrency = 1
                       THEN NVL(ctePago.ImporteRecibido,0)
                       ELSE NVL(ctePago.ImporteRecibido,0) * NVL(tblTipoCambio.TC,0)
                  END,2) as ImporteRecibidoML
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
            , ctePago.ncurrency as CodMonedaTransaccion
            , ctePago.MonedaTransaccion
            , EstRec.sdescript as EstadoRecibo
            , CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.DISSUEDAT ELSE NULL END As FechaFacturaRecibo
            , CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.NPREVBILL ELSE NULL END AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , CREF.NCERTIF As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
        FROM PREMIUM PRE
        INNER JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE
             AND PRE.NBRANCH= PRE_MO.NBRANCH
             AND PRE.NPRODUCT= PRE_MO.NPRODUCT
             AND PRE.NRECEIPT= PRE_MO.NRECEIPT
             AND PRE.NDIGIT= PRE_MO.NDIGIT
             AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE
             AND PRE_MO.Ntype IN (2,3,13,14,21,39,40,42)
        INNER JOIN COLFORMREF CREF On pre_mo.NBordereaux= CREF.NBordereaux
             and NVL(CREF.nnullcode,0)=0
        INNER JOIN ctePago on CREF.NBordereaux = ctePago.NBordereaux
        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON PRE.SCERTYPE= VPOL.SCERTYPE
             AND PRE.NBRANCH= VPOL.NBRANCH
             AND PRE.NPRODUCT= VPOL.NPRODUCT
             AND PRE.NPolicy= VPOL.NPolicy
                
        LEFT JOIN BILLS fact ON CREF.NBordereaux = fact.NBordereaux and pre_mo.nbillnum= fact.nbillnum
        LEFT JOIN USER_CASHNUM UCash ON CREF.NCASHNUM= UCash.NCASHNUM
        LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient
        
        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI
        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice
        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay
        LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran
        

        OUTER APPLY (
            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
            FROM dual
        ) tblTipoCambio
        WHERE VPOL.codFrecuenciaPago <> 8
          AND pre.nstatus_pre in (2,5,6,7)               
        -- AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  		        
        
        --parametros>                  
        AND  CREF.DCollect BETWEEN NS_INSCONTROLINGRESO511.DINIDATE AND NS_INSCONTROLINGRESO511.DENDDATE			
        AND pre.noffice = CASE WHEN NVL(NS_INSCONTROLINGRESO511.NOFFICE,0)=0 THEN VPol.CodRegionalPoliza ELSE NS_INSCONTROLINGRESO511.NOFFICE END 
        AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NS_INSCONTROLINGRESO511.NINTERTYP=0 
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP IS NULL
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP = 999
                                             THEN NVL(VPol.CodTipoIntermediario,0)ELSE NS_INSCONTROLINGRESO511.NINTERTYP END 
        AND NVL(VPol.CodIntermediario,0) = CASE WHEN NS_INSCONTROLINGRESO511.NINTERMED=0 
                                                 OR NS_INSCONTROLINGRESO511.NINTERMED IS NULL
                                            THEN NVL(VPol.CodIntermediario,0)  ELSE NS_INSCONTROLINGRESO511.NINTERMED END 			
        AND NVL(UCash.NCASHNUM,0) = CASE WHEN  NVL(NS_INSCONTROLINGRESO511.NCASHNUM,0) = 0 THEN NVL(UCash.NCASHNUM,0) ELSE NS_INSCONTROLINGRESO511.NCASHNUM  END

				
-------------------------------------------------------------------------------------
---- PAGOS FINANCIADOS
-------------------------------------------------------------------------------------   
UNION ALL

 SELECT
          NS_INSCONTROLINGRESO511.SKEY 
        , VPOL.SCertype
        , VPOL.nbranch
        , VPOL.nproduct
        , VPOL.npolicy
        , Vpol.FrecuenciaPago
        , pre.Nreceipt
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
        , UCash.NCASHNUM CodCajero
        , INITCAP(LOWER(RTRIM(CliCaja.scliename))) Cajero
        , ctePago.FormaCobroRealizado as CanalCobroRealizado
        , CREF.DCollect AS FechaCobro
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
        , CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft END AS NroCuota
        , CASE WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate END AS VencimientoDeCuota
        , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
        , CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE.NRECEIPT END As NroFactura
        , ctePago.FormaCobroRealizado as FormaCobroRealizado
        , CREF.NBordereaux As NroRelacionCompensacion
        , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :' || To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft END)) As Concepto
        , Vpol.FrecuenciaPago as Perioricidad
        , ctePago.Banco 
        , ctePago.NroCuenta
        , ctePago.CodigoTransaccion
        , ctePago.NroCheque
        , ctePago.FechaDeposito
        , ctePago.AdministradoraTarjeta
        , ctePago.NroTarjeta
        , VPOL.MonedaPoliza
        , ROUND(CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount END,2) As ImportePrimaPorCobrarMO
        , ROUND((CASE WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount END) * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
        , ROUND(
              CASE WHEN Vpol.codMonedaPoliza = ctePago.Ncurrency
                   THEN NVL(ctePago.ImporteRecibido,0)
                   ELSE CASE WHEN  ctePago.Ncurrency = 1
                             THEN NVL(ctePago.ImporteRecibido,0) / NVL(tblTipoCambio.TC,0)
                             ELSE NVL(ctePago.ImporteRecibido,0) * NVL(tblTipoCambio.TC,0)
                        END
              END,2) as ImporteRecibidoMO            
        , ROUND(
              CASE WHEN ctePago.Ncurrency = 1
                   THEN NVL(ctePago.ImporteRecibido,0)
                   ELSE NVL(ctePago.ImporteRecibido,0) * NVL(tblTipoCambio.TC,0)
              END,2) as ImporteRecibidoML
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
        , ctePago.ncurrency as CodMonedaTransaccion
        , ctePago.MonedaTransaccion
        , EstRec.sdescript as EstadoRecibo
        , CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.DISSUEDAT ELSE NULL END As FechaFacturaRecibo
        , CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.NPREVBILL ELSE NULL END AS NroFacturaAnterior
        , '' AS MonedaOriginalAnterior
        , CREF.NCERTIF As NroCertificado
        , VPOL.TipoFacturaColectivo
        , VPOL.TipoDistribucion
    FROM PREMIUM PRE
    INNER JOIN Financ_dra FDRA On Pre.ncontrat= FDRA.ncontrat
    INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat
                                     AND FDRA.NDRAFT= DRA_HIS.NDRAFT
                                     AND DRA_HIS.Ntype IN (2)
    INNER JOIN COLFORMREF CREF On FDRA.NBordereaux= CREF.NBordereaux
    INNER JOIN ctePago on CREF.NBordereaux = ctePago.NBordereaux
    INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON PRE.SCERTYPE= VPOL.SCERTYPE
         AND PRE.NBRANCH= VPOL.NBRANCH
         AND PRE.NPRODUCT= VPOL.NPRODUCT
         AND PRE.NPolicy= VPOL.NPolicy
    INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
    INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI
    INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice    
    LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux
    LEFT JOIN USER_CASHNUM UCash ON CREF.NCASHNUM= UCash.NCASHNUM
    LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
    LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient                        
    OUTER APPLY (
        SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
        FROM dual
    ) tblTipoCambio
    --LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay
    --LEFT JOIN TABLE182 FCob on DRA_HIS.SPAY_FORM= FCob.SPAY_FORM
    WHERE VPOL.codFrecuenciaPago = 8
      AND pre.nstatus_pre in (8)                      		
    --   AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  
    --parametros>                  
        AND  CREF.DCollect BETWEEN NS_INSCONTROLINGRESO511.DINIDATE AND NS_INSCONTROLINGRESO511.DENDDATE			
        AND pre.noffice = CASE WHEN NVL(NS_INSCONTROLINGRESO511.NOFFICE,0)=0 THEN VPol.CodRegionalPoliza ELSE NS_INSCONTROLINGRESO511.NOFFICE END 
        AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NS_INSCONTROLINGRESO511.NINTERTYP=0 
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP IS NULL
                                                        OR NS_INSCONTROLINGRESO511.NINTERTYP = 999
                                             THEN NVL(VPol.CodTipoIntermediario,0)ELSE NS_INSCONTROLINGRESO511.NINTERTYP END 
        AND NVL(VPol.CodIntermediario,0) = CASE WHEN NS_INSCONTROLINGRESO511.NINTERMED=0 
                                                 OR NS_INSCONTROLINGRESO511.NINTERMED IS NULL
                                            THEN NVL(VPol.CodIntermediario,0)  ELSE NS_INSCONTROLINGRESO511.NINTERMED END 			
        AND NVL(UCash.NCASHNUM,0) = CASE WHEN  NVL(NS_INSCONTROLINGRESO511.NCASHNUM,0) = 0 THEN NVL(UCash.NCASHNUM,0) ELSE NS_INSCONTROLINGRESO511.NCASHNUM  END	
    
                    
-------------------------------------------------------------------------------------
---- PAGOS ANTICIPADA NORMAL
-------------------------------------------------------------------------------------   
UNION ALL        
        
        SELECT
              NS_INSCONTROLINGRESO511.SKEY 
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , VPOL.npolicy
            , Vpol.FrecuenciaPago
            , pre.Nreceipt
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
            , pre.NPeriod AS NroCuota
            , pre.dlimitdate AS VencimientoDeCuota
            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
            , CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE_MO.NRECEIPT END As NroFactura
            , 'Facturacion Anticipada' as FormaCobroRealizado
            , pre_mo.NBordereaux As NroRelacionCompensacion
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
            , PRE_MO.NBILLNUM_OLD AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , fact.NCERTIF As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
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

    --PARAMETROS>                  
    AND  PRE_MO.Dcompdate BETWEEN NS_INSCONTROLINGRESO511.DINIDATE AND NS_INSCONTROLINGRESO511.DENDDATE			
    AND pre.noffice = CASE WHEN NVL(NS_INSCONTROLINGRESO511.NOFFICE,0)=0 THEN VPol.CodRegionalPoliza ELSE NS_INSCONTROLINGRESO511.NOFFICE END 
    AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NS_INSCONTROLINGRESO511.NINTERTYP=0 
                                                    OR NS_INSCONTROLINGRESO511.NINTERTYP IS NULL
                                                    OR NS_INSCONTROLINGRESO511.NINTERTYP = 999
                                         THEN NVL(VPol.CodTipoIntermediario,0)ELSE NS_INSCONTROLINGRESO511.NINTERTYP END 
    AND NVL(VPol.CodIntermediario,0) = CASE WHEN NS_INSCONTROLINGRESO511.NINTERMED=0 
                                             OR NS_INSCONTROLINGRESO511.NINTERMED IS NULL
                                        THEN NVL(VPol.CodIntermediario,0)  ELSE NS_INSCONTROLINGRESO511.NINTERMED END 			                       
    --AND NVL(UCash.NCASHNUM,0) = CASE WHEN  NVL(NS_INSCONTROLINGRESO511.NCASHNUM,0) = 0 THEN NVL(UCash.NCASHNUM,0) ELSE NS_INSCONTROLINGRESO511.NCASHNUM  END
    
	-------------------------------------------------------------------------------------
---- PAGOS ANTICIPADA FINANCIADA
-------------------------------------------------------------------------------------   
UNION ALL
        SELECT
              NS_INSCONTROLINGRESO511.SKEY 
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , VPOL.npolicy
            , Vpol.FrecuenciaPago
            , pre.Nreceipt
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
            , CASE WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft END AS NroCuota
            , CASE WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate END AS VencimientoDeCuota
            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
            , CASE WHEN NVL(fact.NBILLNUM,0) <> 0 THEN fact.NBILLNUM ELSE PRE.NRECEIPT END As NroFactura
            , 'Facturaci�n Anticipada' as FormaCobroRealizado
            , FDRA.NBordereaux As NroRelacionCompensacion
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
            , 0 AS NroFacturaAnterior
            , '' AS MonedaOriginalAnterior
            , fact.NCERTIF As NroCertificado
            , VPOL.TipoFacturaColectivo
            , VPOL.TipoDistribucion
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
					
    --AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  
    
    --PARAMETROS>                  
    AND DRA_HIS.dcompdate BETWEEN NS_INSCONTROLINGRESO511.DINIDATE AND NS_INSCONTROLINGRESO511.DENDDATE			
    AND pre.noffice = CASE WHEN NVL(NS_INSCONTROLINGRESO511.NOFFICE,0)=0 THEN VPol.CodRegionalPoliza ELSE NS_INSCONTROLINGRESO511.NOFFICE END 
    AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NS_INSCONTROLINGRESO511.NINTERTYP=0 
                                                    OR NS_INSCONTROLINGRESO511.NINTERTYP IS NULL
                                                    OR NS_INSCONTROLINGRESO511.NINTERTYP = 999
                                         THEN NVL(VPol.CodTipoIntermediario,0)ELSE NS_INSCONTROLINGRESO511.NINTERTYP END 
    AND NVL(VPol.CodIntermediario,0) = CASE WHEN NS_INSCONTROLINGRESO511.NINTERMED=0 
                                             OR NS_INSCONTROLINGRESO511.NINTERMED IS NULL
                                        THEN NVL(VPol.CodIntermediario,0)  ELSE NS_INSCONTROLINGRESO511.NINTERMED END 			                       
    --AND NVL(UCash.NCASHNUM,0) = CASE WHEN  NVL(NS_INSCONTROLINGRESO511.NCASHNUM,0) = 0 THEN NVL(UCash.NCASHNUM,0) ELSE NS_INSCONTROLINGRESO511.NCASHNUM  END

    ORDER BY NroPoliza, FechaCobro;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NERROR := SQLCODE;
        SERRORDESC := SQLERRM;
        CRETRACE2('ERR TMP_INT511', 593, SERRORDESC);  
        
        RAISE;    
END NS_INSCONTROLINGRESO511;

