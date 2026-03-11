---PENDIENTES

    SELECT 
                  VPol.SCertype
                , VPol.nbranch
                , VPol.nproduct
                , VPol.npolicy
                , pre.Nreceipt
                , tblCuotaCredito.NroCuota
                , VPol.CanalVenta    
                , VPol.LineaNegocio
                , VPol.Ramo
                , VPol.Producto    
                , VPol.NroPoliza
                , VPol.CodRegionalPoliza
                , VPol.RegionalPoliza 
                , VPol.MonedaPoliza
                , TRIM(TCuo.sdescript) as TipoCuota
                , EstRec.nstatus_pre As IdEstadoCuota
                , EstRec.sdescript as EstadoCuota
                , INITCAP(LOWER(RTRIM(CliCaja.sCliename))) As CobradorAsignado 
                , TRIM(VPol.CanalCobroAsignado) AS CanalCobroAsignado
                , 1 As CuotaPrevista
                , 0 As CuotaCobrada
                , tblCuotaCredito.MontoPrevisto AS MontoPrevistoMO 
                , tblCuotaCredito.MontoPrevisto * NVL(PRE_MO.NEXCHANGE,0) As MontoPrevistoML
                , 0 As PrimaCobradaMO
                , 0 As PrimaCobradaML
                --, NVL(PRE_MO.NAMOUNT,0) as ImporteRecibidoMO
                --, NVL(PRE_MO.NAMOUNT,0) * NVL(PRE_MO.NEXCHANGE,0) as ImporteRecibidoML
                , pre.ncurrency as CodMonedaTransaccion
                , mon.sdescript  as MonedaTransaccion 
                , NVL(PRE_MO.NEXCHANGE,0) TipoCambio
                , VPol.DiaDeCobro As FechaPrevista
                , tblCuotaCredito.VencimientoDeCuota   
                
                , TRIM(suc.sdescript) as RegionalCobro            
                , TRIM(MPag.sdescript) as CanalCobroRealizado               
                --, to_date(PRE_MO.DLEDGERDAT,'DD-MM-YYYY') AS FechaCobro                 
                , PRE_MO.DLEDGERDAT AS FechaCobro                 
                ,PRE_MO.NTYPE --As PRE_MO.NTYPE
                ,tipo.sdescript As TipoMovimiento  
                , VPol.TipoIntermediario
                , VPol.Intermediario
                
                FROM PREMIUM PRE
                LEFT JOIN PREMIUM_MO PRE_MO ON PRE.SCERTYPE= PRE_MO.SCERTYPE AND PRE.NBRANCH= PRE_MO.NBRANCH
                         AND PRE.NPRODUCT= PRE_MO.NPRODUCT AND PRE.NRECEIPT= PRE_MO.NRECEIPT AND PRE.NDIGIT= PRE_MO.NDIGIT 
                         AND PRE.NPAYNUMBE= PRE_MO.NPAYNUMBE
                         AND PRE_MO.Ntype IN (1) --Creación de recibo
                         --AND PRE_MO.Ntype IN (2,3,4,5,10,12,14,39,40,42) --Abono,Financiamiento, Cargo a Cuenta Corriente
                OUTER APPLY(
                            SELECT  CASE  WHEN Pre1.ncontrat IS NULL THEN pre1.dlimitdate ELSE cuo1.dlimitdate  END AS VencimientoDeCuota
                                    , CASE  WHEN Pre1.ncontrat IS NULL THEN pre1.NPeriod ELSE cuo1.Ndraft  END AS NroCuota
                                    , CASE  WHEN Pre1.ncontrat IS NULL THEN NVL(pre1.npremium,0) ELSE cuo1.namount  END AS MontoPrevisto 
                            FROM PREMIUM PRE1
                            LEFT JOIN Financ_dra Cuo1 On Pre1.ncontrat= Cuo1.ncontrat
                            WHERE PRE.NRECEIPT = Pre1.NRECEIPT and PRE.npolicy=PRE1.npolicy and PRE.scertype=PRE1.scertype  and PRE.nbranch=PRE1.nbranch and PRE.nproduct=PRE1.nproduct 
                            
                )tblCuotaCredito
                --LEFT JOIN Financ_dra Cuo On Pre.ncontrat= Cuo.ncontrat
                
                INNER JOIN NS_View_DatosPolizas VPol ON  PRE.SCERTYPE= VPol.SCERTYPE AND PRE.NBRANCH= VPol.NBRANCH
                         AND PRE.NPRODUCT= VPol.NPRODUCT AND PRE.NPolicy= VPol.NPolicy        
                INNER JOIN TABLE19 EstRec ON pre.nstatus_pre= EstRec.nstatus_pre
                INNER JOIN Table11 Mon On pre.ncurrency = mon.ncodigint
                INNER JOIN TABLE24 TCuo ON pre.NTRATYPEI= TCuo.NTRATYPEI                
                INNER JOIN Table9 Suc ON pre.noffice = suc.noffice        
                LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay 
                LEFT JOIN TABLE36 FPag ON pre.npayfreq = FPag.npayfreq         
                LEFT JOIN Table6 Tipo ON PRE_MO.Ntype= tipo.ntype_tran                 
                LEFT JOIN USER_CASHNUM UCash ON PRE_MO.NCASHNUM= UCash.NCASHNUM
                LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
                LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient               
                
               WHERE   pre.nstatus_pre in (1,4,8)
                --AND pre.NPolicy=1010--1140 
                --ORDER BY VPol.NroPoliza,PRE_MO.DLEDGERDAT desc
               --parametros>
                
                
        UNION ALL
 ---PAGADAS
        SELECT 
                  VPol.SCertype
                , VPol.nbranch
                , VPol.nproduct
                , VPol.npolicy
                , pre.Nreceipt
                , CASE  WHEN Pre.ncontrat IS NULL THEN pre.NPeriod ELSE cuo.Ndraft  END AS NroCuota
                , VPol.CanalVenta    
                , VPol.LineaNegocio
                , VPol.Ramo
                , VPol.Producto    
                , VPol.NroPoliza
                , VPol.CodRegionalPoliza
                , VPol.RegionalPoliza 
                , VPol.MonedaPoliza
                , TRIM(TCuo.sdescript) as TipoCuota
                , EstRec.nstatus_pre As IdEstadoCuota
                , EstRec.sdescript as EstadoCuota
                , INITCAP(LOWER(RTRIM(CliCaja.sCliename))) As CobradorAsignado 
                , TRIM(VPol.CanalCobroAsignado) AS CanalCobroAsignado
                , 1 As CuotaPrevista
                , 1 As CuotaCobrada
                , CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END AS MontoPrevistoMO 
                , (CASE  WHEN Pre.ncontrat IS NULL THEN NVL(pre.npremium,0) ELSE cuo.namount  END) * NVL(PRE_MO.NEXCHANGE,0) As MontoPrevistoML
                , NVL(PRE_MO.NAMOUNT,0) As PrimaCobradaMO
                , NVL(PRE_MO.NAMOUNT,0) * NVL(PRE_MO.NEXCHANGE,0) As PrimaCobradaML
                , pre.ncurrency as CodMonedaTransaccion
                , mon.sdescript  as MonedaTransaccion 
                , NVL(PRE_MO.NEXCHANGE,0) TipoCambio
                , VPol.DiaDeCobro As FechaPrevista
                , CASE  WHEN Pre.ncontrat IS NULL THEN pre.dlimitdate ELSE cuo.dlimitdate  END AS VencimientoDeCuota   
                
                , TRIM(suc.sdescript) as RegionalCobro            
                , TRIM(MPag.sdescript) as CanalCobroRealizado               
                --, to_date(PRE_MO.DLEDGERDAT,'DD-MM-YYYY') AS FechaCobro                 
                , PRE_MO.DLEDGERDAT AS FechaCobro                 
                ,PRE_MO.NTYPE --As PRE_MO.NTYPE
                ,tipo.sdescript As TipoMovimiento  
                , VPol.TipoIntermediario
                , VPol.Intermediario
                
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
                LEFT JOIN USER_CASHNUM UCash ON PRE_MO.NCASHNUM= UCash.NCASHNUM
                LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
                LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient               
                
               WHERE   pre.nstatus_pre in (2,5,6,7)
                --AND pre.NPolicy=1010--1140 
                --ORDER BY VPol.NroPoliza,PRE_MO.DLEDGERDAT desc
               