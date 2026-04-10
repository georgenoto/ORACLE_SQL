-------------------------------------------------------------------------------------
					---- POLIZAS MENSUALES, TRIMESTRALES Y ANUALES ---> CAJAS
					-------------------------------------------------------------------------------------
                    SELECT 
                              511 skey
                             , VPOL.SCertype
							, VPOL.nbranch
							, VPOL.nproduct
							, VPOL.npolicy
							, Vpol.FrecuenciaPago
							, pre.Nreceipt               
							--, tblFactura.NidTransaction
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
							--, PRE_MO.Dstatdate AS FechaCobro
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
							, CASE  WHEN NVL(fact.NBILLNUM,0)<> 0 THEN  fact.NBILLNUM ELSE PRE_MO.NRECEIPT END As NroFactura             
							--, fcob.sdescript as FormaCobroRealizado
							, Fpag2.sdescript   as FormaCobroRealizado
							, CREF.NBordereaux As NroRelacionCompensacion
							, To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(pre.NPeriod)) As Concepto
							, Vpol.FrecuenciaPago as Perioricidad                 
							,  bco.sdescript  As Banco
                            , '' As NroCuenta
							,  ''  As CodigoTransaccion  
							,  CASE mcash.nmov_type WHEN 2 THEN TO_CHAR(mcash.sdocnumbe) ELSE '' END  As NroCheque --2:= cheque
							, CASE mcash.nmov_type 
								WHEN 2 THEN mcash.ddoc_date  -- Cheque
								WHEN 27 THEN mcash.ddoc_date  -- Voucher ATC
								WHEN 57 THEN mcash.ddoc_date  -- Voucher Linkser								
								ELSE NULL END As FechaDeposito
							, CASE mcash.nmov_type 
								WHEN 27 THEN TO_CHAR(Fpag2.sshort_des)  -- Voucher ATC
								WHEN 57 THEN TO_CHAR(Fpag2.sshort_des)  -- Voucher Linkser								
								ELSE '' END As AdministradoraTarjeta
							, CASE mcash.nmov_type 
								WHEN 27 THEN TO_CHAR(mcash.sdocnumbe)  -- Voucher ATC
								WHEN 57 THEN TO_CHAR(mcash.sdocnumbe)  -- Voucher Linkser								
								ELSE '' END NroTarjeta
							, VPOL.MonedaPoliza        
							, ROUND(NVL(pre.npremium,0),2) As ImportePrimaPorCobrarMO
							, ROUND(NVL(pre.npremium,0) * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
							, ROUND(CASE WHEN  Vpol.codMonedaPoliza= mcash.Ncurrency 
									THEN  NVL(mcash.NAMOUNT,0) 
									ELSE  CASE WHEN mcash.Ncurrency= 1 THEN  (NVL(mcash.NAMOUNT,0) /  NVL(tblTipoCambio.TC,0)) ELSE (NVL(mcash.NAMOUNT,0) *  NVL(tblTipoCambio.TC,0)) END
									END,2) as ImporteRecibidoMO
							, ROUND(CASE WHEN mcash.Ncurrency= 1 THEN NVL(mcash.NAMOUNT,0) ELSE NVL(mcash.NAMOUNT,0) * NVL(tblTipoCambio.TC,0) END,2) as ImporteRecibidoML
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
						   -- , pre.nbalance As SaldoPendientePrima
							, pre.ncurrency as CodMonedaTransaccion
							, mon.sdescript  as MonedaTransaccion                        
							, EstRec.sdescript as EstadoRecibo
							, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.DISSUEDAT ELSE  NULL END As FechaFacturaRecibo
							, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.NPREVBILL ELSE NULL END  AS NroFacturaAnterior
							, '' AS MonedaOriginalAnterior    
                            , CREF.NCERTIF As NroCertificado
                            , VPOL.TipoFacturaColectivo
                            , VPOL.TipoDistribucion
									
						FROM PREMIUM PRE
						INNER JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE AND PRE.NBRANCH= PRE_MO.NBRANCH
								 AND PRE.NPRODUCT= PRE_MO.NPRODUCT AND PRE.NRECEIPT= PRE_MO.NRECEIPT AND PRE.NDIGIT= PRE_MO.NDIGIT 
								 AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE                
								 AND PRE_MO.Ntype IN (2,3,13,14,21,39,40,42) --Abono,Financiamiento, Cargo a Cuenta Corriente
						INNER JOIN COLFORMREF CREF On pre_mo.NBordereaux= CREF.NBordereaux
														and NVL(CREF.nnullcode,0)=0  -- filtra aquellos pagos que no han sido revertidos o anulados
																	
						LEFT JOIN BILLS fact ON CREF.NBordereaux = fact.NBordereaux and pre_mo.nbillnum= fact.nbillnum
						--- CAJERO                           
						LEFT JOIN USER_CASHNUM UCash ON CREF.NCASHNUM= UCash.NCASHNUM
						LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
						LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient              
											  
						INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  PRE.SCERTYPE= VPOL.SCERTYPE AND PRE.NBRANCH= VPOL.NBRANCH
															 AND PRE.NPRODUCT= VPOL.NPRODUCT AND PRE.NPolicy= VPOL.NPolicy                        
						INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
						
						INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
						INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice        
						LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
						--LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
						LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
						LEFT JOIN TABLE182 FCob on PRE_MO.SPAY_FORM= FCob.SPAY_FORM
																   
						--- MOV. EN CAJA - ENTRADA DE DINERO - DEPOSITO EN CAJA - CHEQUE
						 INNER JOIN CASH_MOV mcash ON CREF.nbordereaux= mcash.nbordereaux
						 INNER JOIN TABLE11 Mon On mcash.ncurrency = mon.ncodigint
						 LEFT JOIN TABLE7 bco ON mcash.nbank_code = bco.Nbank_code
						 LEFT JOIN TABLE78 Fpag2 ON mcash.nmov_type= fpag2.nmov_type						 
						--- TIPO CAMBIO
						OUTER APPLY (
							SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
							FROM dual
						) tblTipoCambio
                        
                       WHERE VPOL.codFrecuenciaPago <> 8 -- CON FINANCIAMIENTO   
                        AND pre.nstatus_pre in (2,5,6,7)
                        
                        -- AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  		
                        
					-------------------------------------------------------------------------------------
					---- POLIZAS MENSUALES, TRIMESTRALES Y ANUALES ---> BANCOS 
					-------------------------------------------------------------------------------------
                    UNION ALL
					
					SELECT 
                            511 skey                            
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
                            --, PRE_MO.Dstatdate AS FechaCobro
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
                            , CASE  WHEN NVL(fact.NBILLNUM,0)<> 0 THEN  fact.NBILLNUM ELSE PRE_MO.NRECEIPT END As NroFactura             
                            --, fcob.sdescript as FormaCobroRealizado
                            ,  Fpag3.sdescript  as FormaCobroRealizado
                            , CREF.NBordereaux As NroRelacionCompensacion
                            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(pre.NPeriod)) As Concepto
                            , Vpol.FrecuenciaPago as Perioricidad                
                            , Bco2.sdescript  As Banco
                            , CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BAcc.SACC_NUMBER)) As NroCuenta
                            , TO_CHAR(BMov.sdep_number)  As CodigoTransaccion
                            , TO_CHAR('')  As NroCheque
                            ,  BMov.ddoc_date As FechaDeposito
                            , '' As AdministradoraTarjeta
                            , '' NroTarjeta
                            , VPOL.MonedaPoliza        
                            , ROUND(NVL(pre.npremium,0),2) As ImportePrimaPorCobrarMO
                            , ROUND(NVL(pre.npremium,0) * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
                            , ROUND(CASE WHEN  Vpol.codMonedaPoliza= BMov.Ncurrency 
                                    THEN  NVL(BMov.NCASH_AMOUN,0) 
                                    ELSE  CASE WHEN BMov.Ncurrency= 1 THEN  (NVL(BMov.NCASH_AMOUN,0) /  NVL(tblTipoCambio.TC,0)) ELSE (NVL(BMov.NCASH_AMOUN,0) *  NVL(tblTipoCambio.TC,0)) END
                                    END,2) as ImporteRecibidoMO
                            , ROUND(CASE WHEN BMov.Ncurrency= 1 THEN NVL(BMov.NCASH_AMOUN,0) ELSE NVL(BMov.NCASH_AMOUN,0) * NVL(tblTipoCambio.TC,0) END,2) as ImporteRecibidoML
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
                           -- , pre.nbalance As SaldoPendientePrima
                            , pre.ncurrency as CodMonedaTransaccion
                            , mon.sdescript  as MonedaTransaccion                        
                            , EstRec.sdescript as EstadoRecibo
                            , CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.DISSUEDAT ELSE  NULL END As FechaFacturaRecibo
							, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.NPREVBILL ELSE NULL END  AS NroFacturaAnterior
                            , '' AS MonedaOriginalAnterior 
                            , CREF.NCERTIF As NroCertificado
                            , VPOL.TipoFacturaColectivo
                            , VPOL.TipoDistribucion
                                    
                        FROM PREMIUM PRE
                        INNER JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE AND PRE.NBRANCH= PRE_MO.NBRANCH
                                 AND PRE.NPRODUCT= PRE_MO.NPRODUCT AND PRE.NRECEIPT= PRE_MO.NRECEIPT AND PRE.NDIGIT= PRE_MO.NDIGIT 
                                 AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE                
                                 AND PRE_MO.Ntype IN (2,3,13,14,21,39,40,42) --Abono,Financiamiento, Cargo a Cuenta Corriente
                        INNER JOIN COLFORMREF CREF On pre_mo.NBordereaux= CREF.NBordereaux
                                                        and NVL(CREF.nnullcode,0)=0  -- filtra aquellos pagos que no han sido revertidos o anulados
                                                                    
                        LEFT JOIN BILLS fact ON CREF.NBordereaux = fact.NBordereaux and pre_mo.nbillnum= fact.nbillnum
                        --- CAJERO                           
                        LEFT JOIN USER_CASHNUM UCash ON CREF.NCASHNUM= UCash.NCASHNUM
                        LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
                        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient              
                                              
                        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  PRE.SCERTYPE= VPOL.SCERTYPE AND PRE.NBRANCH= VPOL.NBRANCH
                                                             AND PRE.NPRODUCT= VPOL.NPRODUCT AND PRE.NPolicy= VPOL.NPolicy                        
                        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
                        
                        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
                        INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice        
                        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
                        --LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
                        LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
                        LEFT JOIN TABLE182 FCob on PRE_MO.SPAY_FORM= FCob.SPAY_FORM
                                                                                                       
                         -- PARA TRANSFERENCIA BANCARIA
                        INNER JOIN Bank_mov BMov On CREF.Nbordereaux=BMov.Nbordereaux
						INNER JOIN TABLE11 Mon On BMov.ncurrency = mon.ncodigint
                        LEFT JOIN BANK_ACC BAcc On BMOv.NACC_BANK= BAcc.NACC_BANK
                        LEFT JOIN TABLE7   Bco2 on BAcc.NBANK_CODE= Bco2.NBANK_CODE
                        LEFT JOIN TABLE296 Fpag3 ON BMOV.NTYPE_MOV= fpag3.NTYPE_MOV
                        
                        --- TIPO CAMBIO
                        OUTER APPLY (
                            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
                            FROM dual
                        ) tblTipoCambio
                        
                       WHERE VPOL.codFrecuenciaPago <> 8 -- CON FINANCIAMIENTO   
                        AND pre.nstatus_pre in (2,5,6,7)
                       		
                    --   AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  
                    
                    

                    -------------------------------------------------------------------------------------
					---- POLIZAS FINANCIADAS --> PAGO EN CAJA
					-------------------------------------------------------------------------------------
					UNION ALL
						SELECT 
							  511 skey            
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
							, CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft  END AS NroCuota
							, CASE  WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate  END AS VencimientoDeCuota
							, DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento             
							, CASE  WHEN NVL(fact.NBILLNUM,0)<> 0 THEN  fact.NBILLNUM ELSE PRE.NRECEIPT END As NroFactura             
							--, Fpag3.sdescript as FormaCobroRealizado
							, Fpag2.sdescript   as FormaCobroRealizado
							, CREF.NBordereaux As NroRelacionCompensacion
							, To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft  END)) As Concepto
							, Vpol.FrecuenciaPago as Perioricidad                 
							,  bco.sdescript  As Banco
                            ,  '' As NroCuenta
							,  ''  As CodigoTransaccion  --2:= cheque
							,  CASE mcash.nmov_type WHEN 2 THEN TO_CHAR(mcash.sdocnumbe) ELSE '' END  As NroCheque
							--,  mcash.ddoc_date  As FechaDeposito
							, CASE mcash.nmov_type 
								WHEN 2 THEN mcash.ddoc_date  -- Cheque
								WHEN 27 THEN mcash.ddoc_date  -- Voucher ATC
								WHEN 57 THEN mcash.ddoc_date  -- Voucher Linkser								
								ELSE null END As FechaDeposito
							, CASE mcash.nmov_type 
								WHEN 27 THEN TO_CHAR(Fpag2.sshort_des)  -- Voucher ATC
								WHEN 57 THEN TO_CHAR(Fpag2.sshort_des)  -- Voucher Linkser								
								ELSE '' END As AdministradoraTarjeta
							, CASE mcash.nmov_type 
								WHEN 27 THEN TO_CHAR(mcash.sdocnumbe)  -- Voucher ATC
								WHEN 57 THEN TO_CHAR(mcash.sdocnumbe)  -- Voucher Linkser								
								ELSE '' END NroTarjeta
							, VPOL.MonedaPoliza        
							,ROUND( CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount  END,2) As ImportePrimaPorCobrarMO
							,ROUND( (CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount  END) * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
							
							, ROUND(CASE WHEN  Vpol.codMonedaPoliza= DRA_HIS.Ncurrency 
										THEN  NVL(DRA_HIS.NAMOUNT,0) 
										ELSE  CASE WHEN DRA_HIS.Ncurrency= 1 THEN  (NVL(DRA_HIS.NAMOUNT,0) /  NVL(tblTipoCambio.TC,0)) ELSE (NVL(DRA_HIS.NAMOUNT,0) *  NVL(tblTipoCambio.TC,0)) END
										END,2) as ImporteRecibidoMO
							, ROUND(CASE WHEN DRA_HIS.Ncurrency= 1 THEN NVL(DRA_HIS.NAMOUNT,0) ELSE NVL(DRA_HIS.NAMOUNT,0) * NVL(tblTipoCambio.TC,0) END,2) as ImporteRecibidoML           
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
							, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.DISSUEDAT ELSE  NULL END As FechaFacturaRecibo
							, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.NPREVBILL ELSE NULL END  AS NroFacturaAnterior
							, '' AS MonedaOriginalAnterior
                            , CREF.NCERTIF As NroCertificado
                            , VPOL.TipoFacturaColectivo
                            , VPOL.TipoDistribucion
									
						FROM PREMIUM PRE 

						--- Polizas en cuotas, con financiamiento
						INNER JOIN Financ_dra FDRA On Pre.ncontrat= FDRA.ncontrat
						INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat AND FDRA.NDRAFT= DRA_HIS.NDRAFT 
													  AND DRA_HIS.Ntype IN (2)  -- 2 Cobro , 3 Rev_cobro   
						--INNER JOIN TRELDOC TDOC ON FDRA.NBordereaux= TDOC.NBordereaux and FDRA.NDRAFT= TDOC.NDRAFT
						INNER JOIN COLFORMREF CREF On FDRA.NBordereaux= CREF.NBordereaux

						LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux 
						--- CAJERO
						LEFT JOIN USER_CASHNUM UCash ON CREF.NCASHNUM= UCash.NCASHNUM
						LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
						LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient                              
												
						INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  PRE.SCERTYPE= VPOL.SCERTYPE AND PRE.NBRANCH= VPOL.NBRANCH
																			AND PRE.NPRODUCT= VPOL.NPRODUCT AND PRE.NPolicy= VPOL.NPolicy        
						INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre						
						INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
						INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice        
						LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
						--LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
						--LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
						LEFT JOIN TABLE182 FCob on DRA_HIS.SPAY_FORM= FCob.SPAY_FORM								 
						
						--- MOV. EN CAJA - ENTRADA DE DINERO - DEPOSITO EN CAJA - CHEQUE
						 INNER JOIN CASH_MOV mcash ON FDRA.nbordereaux= mcash.nbordereaux
						 INNER JOIN TABLE11 Mon On mcash.Ncurrency = mon.ncodigint	
						 LEFT JOIN TABLE7 bco ON mcash.nbank_code = bco.Nbank_code
						 LEFT JOIN TABLE78 Fpag2 ON mcash.nmov_type= fpag2.nmov_type
						                          
						--- TIPO CAMBIO
						OUTER APPLY (
							SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
							FROM dual
						) tblTipoCambio

						WHERE   VPOL.codFrecuenciaPago= 8 -- CON FINANCIAMIENTO
						and pre.nstatus_pre in (8)
						
                        --AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  

                       
			-------------------------------------------------------------------------------------
			---- POLIZAS FINANCIADAS ---> BANCOS
			-------------------------------------------------------------------------------------
			UNION ALL

				SELECT 
						  511 skey						
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
						, CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft  END AS NroCuota
						, CASE  WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate  END AS VencimientoDeCuota
						, DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento             
						, CASE  WHEN NVL(fact.NBILLNUM,0)<> 0 THEN  fact.NBILLNUM ELSE PRE.NRECEIPT END As NroFactura             
						, Fpag3.sdescript   as FormaCobroRealizado
						, CREF.NBordereaux As NroRelacionCompensacion
						, To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft  END)) As Concepto
						, Vpol.FrecuenciaPago as Perioricidad
						--fpag2.nmov_type= 3 Transferencia bancaria                 
						,  Bco2.sdescript   As Banco
                        , CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BAcc.SACC_NUMBER)) As NroCuenta
						,  TO_CHAR(BMOV.sdep_number)  As CodigoTransaccion
						,  TO_CHAR('')  As NroCheque
						,  BMov.ddoc_date  As FechaDeposito
						, '' As AdministradoraTarjeta
						, '' NroTarjeta
						, VPOL.MonedaPoliza        
						, ROUND(CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount  END,2) As ImportePrimaPorCobrarMO
						, ROUND((CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount  END) * NVL(tblTipoCambio.TC,0),2) As ImportePrimaPorCobrarML
						, ROUND(CASE WHEN  Vpol.codMonedaPoliza= DRA_HIS.Ncurrency 
												THEN  NVL(DRA_HIS.NAMOUNT,0) 
												ELSE  CASE WHEN DRA_HIS.Ncurrency= 1 THEN  (NVL(DRA_HIS.NAMOUNT,0) /  NVL(tblTipoCambio.TC,0)) ELSE (NVL(DRA_HIS.NAMOUNT,0) *  NVL(tblTipoCambio.TC,0)) END
												END,2) as ImporteRecibidoMO
										, ROUND(CASE WHEN DRA_HIS.Ncurrency= 1 THEN NVL(DRA_HIS.NAMOUNT,0) ELSE NVL(DRA_HIS.NAMOUNT,0) * NVL(tblTipoCambio.TC,0) END,2) as ImporteRecibidoML
					   
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
					   -- , pre.nbalance As SaldoPendientePrima
						, pre.ncurrency as CodMonedaTransaccion
						, mon.sdescript  as MonedaTransaccion                        
						, EstRec.sdescript as EstadoRecibo
						, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.DISSUEDAT ELSE  NULL END As FechaFacturaRecibo
						, CASE WHEN NVL(fact.NPREVBILL,0) <> 0 THEN fact.NPREVBILL ELSE NULL END  AS NroFacturaAnterior
						, '' AS MonedaOriginalAnterior
                        , CREF.NCERTIF As NroCertificado
                        , VPOL.TipoFacturaColectivo
                        , VPOL.TipoDistribucion
								
					FROM PREMIUM PRE 
					--- Polizas en cuotas, con financiamiento
					INNER JOIN Financ_dra FDRA On Pre.ncontrat= FDRA.ncontrat
					INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat AND FDRA.NDRAFT= DRA_HIS.NDRAFT 
												  AND DRA_HIS.Ntype IN (2)  -- 2 Cobro , 3 Rev_cobro           
					INNER JOIN COLFORMREF CREF On FDRA.NBordereaux= CREF.NBordereaux        
					LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux 
					--- CAJERO
					LEFT JOIN USER_CASHNUM UCash ON CREF.NCASHNUM= UCash.NCASHNUM
					LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
					LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient                              
											
					INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  PRE.SCERTYPE= VPOL.SCERTYPE AND PRE.NBRANCH= VPOL.NBRANCH
																		AND PRE.NPRODUCT= VPOL.NPRODUCT AND PRE.NPolicy= VPOL.NPolicy        
					INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre					
					INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
					INNER JOIN TABLE9 Suc ON CREF.noffice = suc.noffice        
					LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
					--LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
					--LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
					LEFT JOIN TABLE182 FCob on DRA_HIS.SPAY_FORM= FCob.SPAY_FORM
											 
					-- PARA TRANSFERENCIA BANCARIA
					INNER JOIN BANK_MOV BMOV On CREF.Nbordereaux=BMov.Nbordereaux
					INNER JOIN TABLE11 Mon On BMOV.Ncurrency = mon.ncodigint
					LEFT JOIN BANK_ACC BAcc On BMOv.NACC_BANK= BAcc.NACC_BANK
					LEFT JOIN TABLE7   Bco2 on BAcc.NBANK_CODE= Bco2.NBANK_CODE    
					LEFT JOIN TABLE296 Fpag3 ON BMOV.NTYPE_MOV= fpag3.NTYPE_MOV
					
				   --- TIPO CAMBIO
					OUTER APPLY (
						SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, CREF.DCollect) AS TC
						FROM dual
					) tblTipoCambio
					
					WHERE   VPOL.codFrecuenciaPago= 8 -- CON FINANCIAMIENTO
					and pre.nstatus_pre in (8)                 
					
                    --AND CREF.DCollect BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  
					
                    
                    -------------------------------------------------------------------------------------
                    ---- FACTURA ANTICIPADA: POLIZAS MENSUALES, ANUALES, TRIMESTRALES.
                    -------------------------------------------------------------------------------------
                        UNION ALL
                        
                        SELECT 
                             511 skey
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
                            , UsrCaja.NUSERCODE  CodCajero
                            , INITCAP(LOWER(RTRIM(CliCaja.scliename))) as Cajero
                            , TRIM(MPag.sdescript) as CanalCobroRealizado
                            , PRE_MO.Dcompdate AS FechaCobro
                            --, CREF.DCollect AS FechaCobro
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
                            , CASE  WHEN NVL(fact.NBILLNUM,0)<> 0 THEN  fact.NBILLNUM ELSE PRE_MO.NRECEIPT END As NroFactura             
                            , 'Facturación Anticipada' as FormaCobroRealizado
                            --, CASE WHEN mcash.nbordereaux IS NOT NULL THEN Fpag2.sdescript ELSE Fpag3.sdescript END  as FormaCobroRealizado
                            , pre_mo.NBordereaux As NroRelacionCompensacion
                            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(pre.NPeriod)) As Concepto
                            , Vpol.FrecuenciaPago as Perioricidad                 
                            , CASE WHEN fpag2.nmov_type= 3 then Bco2.sdescript  else bco.sdescript end As Banco
                            , '' As NroCuenta
                            , '' As CodigoTransaccion
                            , CASE WHEN fpag2.nmov_type= 3 then TO_CHAR('') else TO_CHAR(mcash.sdocnumbe) end As NroCheque
                            , CASE WHEN fpag2.nmov_type= 3 then BMov.ddoc_date else mcash.deffecdate end As FechaDeposito
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
                           -- , pre.nbalance As SaldoPendientePrima
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
                        INNER JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE AND PRE.NBRANCH= PRE_MO.NBRANCH
                                 AND PRE.NPRODUCT= PRE_MO.NPRODUCT AND PRE.NRECEIPT= PRE_MO.NRECEIPT AND PRE.NDIGIT= PRE_MO.NDIGIT 
                                 AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE                
                                 AND PRE_MO.Ntype IN (42) --Factura Anticipada            
                        --INNER JOIN COLFORMREF CREF On pre_mo.NBordereaux= CREF.NBordereaux
                        
                        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  PRE.SCERTYPE= VPOL.SCERTYPE AND PRE.NBRANCH= VPOL.NBRANCH
                                                             AND PRE.NPRODUCT= VPOL.NPRODUCT AND PRE.NPolicy= VPOL.NPolicy  
                                                
                        LEFT JOIN BILLS fact ON  pre_mo.nbillnum= fact.nbillnum
                        --- Cajero                            
                        LEFT JOIN USERS UsrCaja ON pre_mo.NUSERCODE= UsrCaja.NUSERCODE
                        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient              
                                              
                        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
                        INNER JOIN TABLE11 Mon On pre.ncurrency = mon.ncodigint
                        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
                        INNER JOIN TABLE9 Suc ON UsrCaja.noffice = suc.noffice        
                        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
                        --LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
                        LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
                        LEFT JOIN TABLE182 FCob on PRE_MO.SPAY_FORM= FCob.SPAY_FORM
                                                                   
                        --- MOV. EN CAJA - ENTRADA DE DINERO - DEPOSITO EN CAJA - CHEQUE
                         LEFT JOIN CASH_MOV mcash ON PRE_MO.nbordereaux= mcash.nbordereaux
                         LEFT JOIN TABLE7 bco ON mcash.nbank_code = bco.Nbank_code
                         LEFT JOIN TABLE78 Fpag2 ON mcash.nmov_type= fpag2.nmov_type
                         
                         -- PARA TRANSFERENCIA BANCARIA
                        LEFT JOIN Bank_mov BMov On PRE_MO.Nbordereaux=BMov.Nbordereaux
                        LEFT JOIN BANK_ACC BAcc On BMOv.NACC_BANK= BAcc.NACC_BANK
                        LEFT JOIN TABLE7   Bco2 on BAcc.NBANK_CODE= Bco2.NBANK_CODE
                        LEFT JOIN TABLE296 Fpag3 ON BMOV.NTYPE_MOV= fpag3.NTYPE_MOV
                        
                        OUTER APPLY (
                            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, PRE_MO.Dcompdate) AS TC
                            FROM dual
                        ) tblTipoCambio
                        
                       WHERE VPOL.codFrecuenciaPago <> 8 -- CON FINANCIAMIENTO   
                        AND pre.nstatus_pre in (10) --Pendiente Fact. Anticipada   
                        
                        --AND PRE_MO.Dcompdate BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  
                       
                        -------------------------------------------------------------------------------------
                    ---- FACTURA ANTICIPADA: POLIZAS FINANCIADAS
                    -------------------------------------------------------------------------------------
                      UNION ALL
                      
                    SELECT 
                              511 skey
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
                            , CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft  END AS NroCuota
                            , CASE  WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE FDRA.dlimitdate  END AS VencimientoDeCuota
                            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo','Factura') As TipoDocumento             
                            --, NVL(fact.NBILLNUM,0) As NroFactura
                            , CASE  WHEN NVL(fact.NBILLNUM,0)<> 0 THEN  fact.NBILLNUM ELSE PRE.NRECEIPT END As NroFactura             
                            , 'Facturación Anticipada' as FormaCobroRealizado
                            --, CASE WHEN mcash.nbordereaux IS NOT NULL THEN Fpag2.sdescript ELSE Fpag3.sdescript END  as FormaCobroRealizado
                            , FDRA.NBordereaux As NroRelacionCompensacion
                            , To_char(TRIM(VPOL.CanalCobroAsignado)) || '- Poliza :'|| To_char(TRIM(VPOL.NroPoliza)) || ' ' || To_char(TRIM(CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE FDRA.Ndraft  END)) As Concepto
                            , Vpol.FrecuenciaPago as Perioricidad
                                            
                            , CASE  WHEN mcash.nbordereaux IS NULL THEN  Bco2.sdescript  else bco.sdescript end As Banco
                            , CLEANSTRING(EXTENCRYPTION.DECRYPTDATA(BAcc.SACC_NUMBER)) As NroCuenta
                            , '' As CodigoTransaccion
                            , CASE  WHEN mcash.nbordereaux IS NULL THEN TO_CHAR('') else TO_CHAR(mcash.sdocnumbe) end As NroCheque
                            , CASE  WHEN mcash.nbordereaux IS NULL THEN BMov.ddoc_date else mcash.deffecdate end As FechaDeposito
                            , '' As AdministradoraTarjeta
                            , '' NroTarjeta
                            , VPOL.MonedaPoliza        
                            , CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount  END As ImportePrimaPorCobrarMO
                            , (CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE FDRA.namount  END) * NVL(tblTipoCambio.TC,0) As ImportePrimaPorCobrarML
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

                        --- Polizas en cuotas, con financiamiento
                        INNER JOIN Financ_dra FDRA On Pre.ncontrat= FDRA.ncontrat
                        INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat AND FDRA.NDRAFT= DRA_HIS.NDRAFT 
                                                      AND DRA_HIS.Ntype IN (42)  -- Facturación Anticipada            
                      
                        LEFT JOIN BILLS fact ON  FDRA.Nbillnum = fact.nbillnum 
                        --- Cajero
                        LEFT JOIN USERS UsrCaja ON FDRA.NUSERCODE= UsrCaja.NUSERCODE
                        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient                              
                                                
                        INNER JOIN NS_View_DatosGeneralesPoliza VPOL ON  PRE.SCERTYPE= VPOL.SCERTYPE AND PRE.NBRANCH= VPOL.NBRANCH
                                                                            AND PRE.NPRODUCT= VPOL.NPRODUCT AND PRE.NPolicy= VPOL.NPolicy        
                        INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
                        INNER JOIN TABLE11 Mon On pre.ncurrency = mon.ncodigint
                        INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
                        INNER JOIN TABLE9 Suc ON UsrCaja.noffice = suc.noffice        
                        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
                        --LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
                        --LEFT JOIN TABLE6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran 
                        LEFT JOIN TABLE182 FCob on DRA_HIS.SPAY_FORM= FCob.SPAY_FORM
                                     
                        --- MOV. EN CAJA - ENTRADA DE DINERO - DEPOSITO EN CAJA - CHEQUE
                         LEFT JOIN CASH_MOV mcash ON FDRA.nbordereaux= mcash.nbordereaux
                         LEFT JOIN TABLE7 bco ON mcash.nbank_code = bco.Nbank_code
                         LEFT JOIN TABLE78 Fpag2 ON mcash.nmov_type= fpag2.nmov_type
                         
                        -- PARA TRANSFERENCIA BANCARIA
                        LEFT JOIN BANK_MOV BMOV On FDRA.Nbordereaux=BMov.Nbordereaux
                        LEFT JOIN BANK_ACC BAcc On BMOv.NACC_BANK= BAcc.NACC_BANK
                        LEFT JOIN TABLE7   Bco2 on BAcc.NBANK_CODE= Bco2.NBANK_CODE    
                        LEFT JOIN TABLE296 Fpag3 ON BMOV.NTYPE_MOV= fpag3.NTYPE_MOV
                       
                        OUTER APPLY (
                            SELECT INSUDB.GETEXCHANGE(vpol.codmonedapoliza, DRA_HIS.dcompdate) AS TC
                            FROM dual
                        ) tblTipoCambio
                        
                        WHERE   VPOL.codFrecuenciaPago= 8 -- CON FINANCIAMIENTO
                        AND pre.nstatus_pre in (8)    --Financiado                                                 
                         
                        --AND DRA_HIS.dcompdate BETWEEN TO_DATE('01/02/2026', 'DD-MM-YYYY') AND TO_DATE('05/02/2026', 'DD-MM-YYYY')  

