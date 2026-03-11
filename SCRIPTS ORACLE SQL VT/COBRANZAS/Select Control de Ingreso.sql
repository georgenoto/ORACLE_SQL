SELECT 
                  VPol.SCertype
                , VPol.nbranch
                , VPol.nproduct
                , VPol.npolicy
                , pre.Nreceipt
                , 'Nacional Seguros Vida y Salud S.A' As NombreEmpresa
                , '145776027' AS NitEmpresa
                , VPol.LineaNegocio
                , VPol.CanalVenta
                , VPol.Ramo
                , VPol.Producto
                , TRIM(VPol.CanalCobroAsignado) AS CanalCobroAsignado
                , VPol.CodRegionalPoliza
                , VPol.RegionalPoliza 
                , TRIM(suc.sdescript) as RegionalCobro
                , INITCAP(LOWER(RTRIM(CliCaja.sCliename))) As Cajero
                , TRIM(MPag.sdescript) as CanalCobroRealizado
                , to_date(PRE_MO.DLEDGERDAT,'DD-MM-YYYY') AS FechaCobro
                , vpol.contratante Cliente  
                , VPol.NroPoliza 
                , TRIM(TCuo.sdescript) as TipoCuota
                , CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE cuo.Ndraft  END AS NroCuota
                , CASE  WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE cuo.dlimitdate  END AS VencimientoDeCuota
                , DECODE(NVL(PRE_MO.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento
                , NVL(PRE_MO.NBILLNUM,0) As NroFactura              
                , FCob.sdescript as FormaCobroRealizado
                , NULL As NroRelacionCompensacion
                , To_char(TRIM(VPol.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPol.NroPoliza)) || ' ' || To_char(TRIM(CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE cuo.Ndraft  END)) As Concepto
                , Vpol.FrecuenciaPago as Perioricidad
                                        
                 , bco.sdescript As Banco
                , mcash.nvoucher As CodigoTransaccion
                , mcash.sdocnumbe As NroCheque
                , mcash.deffecdate As FechaDeposito
                , '' As AdministradoraTarjeta
                , '' NroTarjeta
                , VPol.MonedaPoliza        
                , CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END As ImportePrimaPorCobrarMO
                , (CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END) * NVL(PRE_MO.NEXCHANGE,0) As ImportePrimaPorCobrarML
                , NVL(PRE_MO.NAMOUNT,0) as ImporteRecibidoMO
                , NVL(PRE_MO.NAMOUNT,0) * NVL(PRE_MO.NEXCHANGE,0) as ImporteRecibidoML
                , 0 As SaldoFavorMO
                , 0 As SaldoFavorML
                , 0 As RegularizacionSaldoMO
                , 0 As RegularizacionSaldoML
                , NVL(PRE_MO.NEXCHANGE,0) TipoCambio
                , VPol.TipoIntermediario As TipoIntermediario
                , VPol.Intermediario As Intermediario
                , pre.Ntype
               -- , pre.nbalance As SaldoPendientePrima
                , pre.ncurrency as CodMonedaTransaccion
                , mon.sdescript  as MonedaTransaccion                        
                , EstRec.sdescript as EstadoRecibo
                , NULL as FechaFacturaRecibo
                , 0 AS NroFacturaAnterior
                , '' AS MonedaOriginalAnterior
                
                                           
--                , VPol.MonedaPoliza                
--                , EstRec.nstatus_pre As IdEstadoCuota
--                , EstRec.sdescript as EstadoCuota                                
--                , 1 As CuotaPrevista
--                , 1 As CuotaCobrada
--                , CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END AS MontoPrevistoMO 
--                , (CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END) * NVL(PRE_MO.NEXCHANGE,0) As MontoPrevistoML
--                , NVL(PRE_MO.NAMOUNT,0) As PrimaCobradaMO
--                , NVL(PRE_MO.NAMOUNT,0) * NVL(PRE_MO.NEXCHANGE,0) As PrimaCobradaML
--                , pre.ncurrency as CodMonedaTransaccion
--                , mon.sdescript  as MonedaTransaccion 
--                , NVL(PRE_MO.NEXCHANGE,0) TipoCambio
--                , VPol.DiaDeCobro As FechaPrevista                                               
--                ,PRE_MO.NTYPE --As PRE_MO.NTYPE
--                ,tipo.sdescript As TipoMovimiento  
--                , VPol.TipoIntermediario
--                , VPol.Intermediario
                
                FROM PREMIUM PRE
                LEFT JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE AND PRE.NBRANCH= PRE_MO.NBRANCH
                         AND PRE.NPRODUCT= PRE_MO.NPRODUCT AND PRE.NRECEIPT= PRE_MO.NRECEIPT AND PRE.NDIGIT= PRE_MO.NDIGIT 
                         AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE                
                         AND PRE_MO.Ntype IN (2,3,13,14,21,39,40,42) --Abono,Financiamiento, Cargo a Cuenta Corriente
                LEFT JOIN Financ_dra Cuo On Pre.ncontrat= Cuo.ncontrat
                
                INNER JOIN NS_View_DatosPolizas VPol ON  PRE.SCERTYPE= VPol.SCERTYPE AND PRE.NBRANCH= VPol.NBRANCH
                         AND PRE.NPRODUCT= VPol.NPRODUCT AND PRE.NPolicy= VPol.NPolicy        
                INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
                INNER JOIN Table11 Mon On pre.ncurrency = mon.ncodigint
                INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
                INNER JOIN Table9 Suc ON pre.noffice = suc.noffice        
                LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
                LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
                LEFT JOIN Table6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
                LEFT JOIN Table182 FCob on PRE_MO.SPAY_FORM= FCob.SPAY_FORM
                LEFT JOIN USER_CASHNUM UCash ON PRE_MO.NCASHNUM= UCash.NCASHNUM
                LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
                LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient               
                
                 LEFT JOIN CASH_MOV mcash ON pre_mo.nbordereaux= mcash.nbordereaux
                 LEFT JOIN TABLE7 bco ON mcash.nbank_code = bco.Nbank_code
                 
--                LEFT JOIN Bank_mov BMov On PRE_MO.Nbordereaux=BMov.Nbordereaux
--                LEFT JOIN BANK_ACC BAcc On BMOv.NACC_BANK= BAcc.NACC_BANK
--                LEFT JOIN TABLE7   Bco on BAcc.NBANK_CODE= Bco.NBANK_CODE
                
               WHERE   pre.nstatus_pre in (2,5,6,7)