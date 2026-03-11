SELECT 
          VPol.NroPoliza
        , pre.Nreceipt
        , pre.Nbranch
        , pre.Nproduct
        , pre.Ndigit
        ,  pre.Nreceipt As IdOrigen
        , 'Nacional Seguros Vida y Salud S.A' As NombreEmpresa
        , '145776027' AS NitEmpresa
                
        , VPol.Ramo
        , VPol.Producto                    
        , VPol.NroPoliza as NroPoliza
        , VPol.MonedaPoliza
        , INITCAP(LOWER(RTRIM(vpol.contratante))) As Contratante
        , VPol.RegionalPoliza
        , CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END AS MontoPrevistoMO
        , 0 As PrimaPrevistaMO
        , (NVL( CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END,0) - 0) AS DiferenciaMO
        , '' MonedaCuenta
        , '' MonedaDebito        
        , CASE  WHEN Pre.ncontrat IS NULL THEN pre.Nreceipt ELSE cuo.Ndraft  END AS NroCuotaDebitar  
        , CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END AS ImporteADebitarMO 
        , VPol.DiaDeCobro As FechaPrevista
        , deb.nbill_dayend  AS FechaSegunFormulario
        , CASE  WHEN Pre.ncontrat IS NULL THEN pre.Nreceipt ELSE cuo.Ndraft  END AS NroCuota
        , vpol.finvigenciapoliza As TerminoVigencia
        , CASE  WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE cuo.dlimitdate  END AS VencimientoDeCuota 
        , deb.dbankauth FechaIngreso
        , '' Observación
        , FPag.sdescript As Periodicidad
        , bancdeb.sdescript BancoDebito
        , INITCAP(LOWER(RTRIM(CliDeb.sCliename))) As TitularCuenta
        , deb.sbankauth Codigo
        , deb.scredi_card  NroCuenta
        , TipTarj.sdescript TipoTarjeta
        
        
              
        , VPol.LineaNegocio
        , VPol.CanalVenta        
        , TRIM(VPol.CanalCobroAsignado) AS CanalCobroAsignado        
        , TRIM(suc.sdescript) as RegionalCobro
        , INITCAP(LOWER(RTRIM(CliCaja.sCliename))) As Cajero        
        , TRIM(MPag.sdescript) as CanalCobroRealizado               
        , to_date(PRE_MO.DLEDGERDAT,'DD-MM-YYYY') AS FechaCobro
        , vpol.codcontratante As CodClienteContratante
              
        
        , TRIM(TCuo.sdescript) as TipoCuota
        
        
                
        , DECODE(NVL(PRE_MO.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
        , NVL(PRE_MO.NBILLNUM,0) As NroFactura
        , FCob.sdescript as FormaCobroRealizado    
        , 0 As NroRelacionCompensacion
        , To_char(TRIM(MPag.sdescript)) || '- Poliza :'|| To_char(TRIM(VPol.NroPoliza)) || ' ' || To_char(TRIM(pre.nperiod)) As Concepto
        
        , NVL(Bco.sdescript,'') Banco
        , '' AS NroCuenta
        , NVL(BMov.NVOUCHER,'') As CodigoTransaccion        
        , cast(NVL(BMov.DREALDEP,'01/01/1900') As DATE) As FechaDeposito
        , NVL(BMov.SDOCNUMBE,'') As NroCheque
        , '' As AdministradoraTarjeta
        , '' NroTarjeta
                
        
        , NVL(pre.npremium,0) * NVL(PRE_MO.NEXCHANGE,0) As ImportePrimaPorCobrarML
        , NVL(PRE_MO.NAMOUNT,0) as ImporteRecibidoMO
        , NVL(PRE_MO.NAMOUNT,0) * NVL(PRE_MO.NEXCHANGE,0) as ImporteRecibidoML
        , 0 As SaldoFavorMO
        , 0 As SaldoFavorML
        , 0 As RegularizacionSaldoMO
        , 0 As RegularizacionSaldoML
        , NVL(PRE_MO.NEXCHANGE,0) TipoCambio
        --,TInte.sDescript As TipoIntermediario
        --,INITCAP(LOWER(RTRIM(CliInte.sCliename))) As Intermediario
        , Vpol.TipoIntermediario
        , Vpol.Intermediario
        , pre.Ntype
       -- , pre.nbalance As SaldoPendientePrima
        , pre.ncurrency as CodMonedaTransaccion
        , mon.sdescript  as MonedaTransaccion 
        , EstRec.nstatus_pre As IdEstadoRecibo
        , EstRec.sdescript as EstadoRecibo
        , cast('01/01/1900' AS DATE) as FechaFacturaRecibo
        , 0 AS NroFacturaAnterior
        , '' AS MonedaOriginalAnterior
        , PRE_MO.NTYPE --As PRE_MO.NTYPE
        , tipo.sdescript As TipoMovimiento  
                    
        FROM PREMIUM PRE
        LEFT JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE AND PRE.NBRANCH= PRE_MO.NBRANCH
                 AND PRE.NPRODUCT= PRE_MO.NPRODUCT AND PRE.NRECEIPT= PRE_MO.NRECEIPT AND PRE.NDIGIT= PRE_MO.NDIGIT 
                 AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE
                 --AND PRE_MO.Ntype IN (2,3,4,5,10,12,14,39,40,42) --Abono,Financiamiento, Cargo a Cuenta Corriente
        LEFT JOIN Financ_dra Cuo On Pre.ncontrat= Cuo.ncontrat
        
        INNER JOIN NS_View_DatosPolizas VPol ON  PRE.SCERTYPE= VPol.SCERTYPE AND PRE.NBRANCH= VPol.NBRANCH
                 AND PRE.NPRODUCT= VPol.NPRODUCT AND PRE.NPolicy= VPol.NPolicy        
        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN Table11 Mon On pre.ncurrency = mon.ncodigint
        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
        INNER JOIN Table9 Suc ON pre.noffice = suc.noffice
        
        LEFT JOIN DIR_DEBIT deb On VPol.SCERTYPE= deb.SCERTYPE AND VPol.NBRANCH= deb.NBRANCH
                 AND VPol.NPRODUCT= deb.NPRODUCT AND VPol.NPolicy= deb.NPolicy 
        LEFT JOIN Table7 BancDeb ON deb.NBANKEXT= bancdeb.nbank_code
        LEFT JOIN Client CliDeb ON deb.sclient = CliDeb.sclient 
        LEFT JOIN Table183 TipTarj On deb.NTYP_CRECARD= TipTarj.ncard_type
        
        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
        LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq
               
        LEFT JOIN COLLECTOR EncCob ON pre.ncollecto= EncCob.ncollector
        LEFT JOIN Client CliEnc ON EncCob.sclient = CliEnc.sclient        
                         
        LEFT JOIN USER_CASHNUM UCash ON PRE_MO.NCASHNUM= UCash.NCASHNUM
        LEFT JOIN USERS UsrCaja ON UCash.NUSERCODE= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient        
        LEFT JOIN BILLS Fact ON PRE_MO.NBillnum= Fact.NBillnum        
        LEFT JOIN Bank_mov BMov On PRE_MO.Nbordereaux=BMov.Nbordereaux
        LEFT JOIN BANK_ACC BAcc On BMOv.NACC_BANK= BAcc.NACC_BANK
        LEFT JOIN Table6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran  
        LEFT JOIN TABLE7   Bco ON BAcc.NBANK_CODE= Bco.NBANK_CODE
        LEFT JOIN Table182 FCob ON PRE_MO.SPAY_FORM= FCob.SPAY_FORM
        
       WHERE vpol.idcanalcobroasignado IN (1,2)
        AND pre.nstatus_pre in (1,4,8)
        AND pre.NPolicy=1604--1599--1604--1607 
        --pre.SCERTYPE  = '2' --- Poliza
        --and PRe.nstatus_pre IN (2,5)-- Recaudado, domiciliado cobrado 
		--And pre.Ntype in (1) -- 1)COBRO  2)DEVOLUCION
        ORDER BY PRE_MO.DLEDGERDAT desc