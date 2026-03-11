--DROP VIEW NS_View_DatosPolizas
CREATE OR REPLACE NONEDITIONABLE  VIEW NS_View_DatosPolizas
AS
------------------------------------------------------------------------
--------------------- 	INDIVIDUAL -------------------------------------
SELECT       
              TRIM(tcer.sdescript) TipoCertificado 
            , Pol.SCertype
            , pol.nbranch
            , pol.nproduct
            , pol.npolicy
            , reg.noffice as CodRegionalPoliza
            , TRIM(Reg.SDESCRIPT) As RegionalPoliza                    
            , pol.NBranch As CodRamo
            , TRIM(Ram.Sdescript) AS Ramo
            , pol.NProduct AS CodProducto
            , TRIM(Prod.SDescript) AS Producto
            , GETEXCHANGE(2,Pol.DISSUEDAT) TC
            , lneg.sbrancht As CodLineaNegocio
            , TRIM(LNeg.sdescript) AS LineaNegocio
            , cven.nsellchannel AS CodCanalVenta
            , TRIM(cven.sdescript) AS CanalVenta
            , CliCont.sClient AS CodContratante
            , INITCAP(LOWER(RTRIM(CliCont.sCliename))) AS Contratante
            --, NVL(Cont.scliename,'') as Contratante
            , pol.NPolicy AS NroPoliza  
            , epol.sstatusva AS CodEstadoPoliza
            , TRIM(EPol.sdescript) AS EstadoPoliza 
            , Moneda.ncodigint AS CodMonedaPoliza
            , TRIM(moneda.sdescript) AS MonedaPoliza 
            , pol.ncapital   AS CapitalMO
            , pol.ncapital * GETEXCHANGE(2,Pol.DISSUEDAT)  As CapitalML
            , Pol.DISSUEDAT As FechaEmision
            , pol.DSTARTDATE As InicioVigenciaPoliza
            , pol.DEXPIRDAT as FinVigenciaPoliza
            , tblPolizasPrimas.PNETA_ANUAL  AS PrimaNetaMO
            , tblPolizasPrimas.PNETA_ANUAL * GETEXCHANGE(2,Pol.DISSUEDAT)  AS PrimaNetaML
            , tblPolizasPrimas.IVA_ANUAL As IVAMO
            , tblPolizasPrimas.IVA_ANUAL * GETEXCHANGE(2,Pol.DISSUEDAT) As IVAML
            , (tblpolizasprimas.PTOTAL_ANUAL * 0.03) as ITMO  -- TO DO 
            , (tblpolizasprimas.PTOTAL_ANUAL * 0.03) * GETEXCHANGE(2,Pol.DISSUEDAT)  as ITML -- TO DO
            , 0 As APSMO
            , 0 As APSML
            , tblPolizasPrimas.RECARGO_ANUAL as RecargoAdicionalMO
            , tblPolizasPrimas.RECARGO_ANUAL * GETEXCHANGE(2,Pol.DISSUEDAT) as RecargoAdicionalML
            , 0 As ServiciosSubContratandosMO
            , 0 As ServiciosSubContratandosML
            , 0 As PrimaAdicionalMO
            , 0 As PrimaAdicionalML
            , 0 As PrimaNetaDiferidaMO
            , 0 As PrimaNetaDiferidaML
            , 0 As PrimaAdicionalDiferidaMO
            , 0 As PrimaAdicionalDiferidaML
            , tblpolizasprimas.PTOTAL_ANUAL PContadoMO
            , tblpolizasprimas.PTOTAL_ANUAL * GETEXCHANGE(2,Pol.DISSUEDAT) PContadoML 
			, CanCobro.nway_pay AS IdCanalCobroAsignado
            , TRIM(CanCobro.sDescript) AS CanalCobroAsignado 
            , FPag.npayfreq As CodFrecuenciaPago
            , TRIM(FPag.sDescript) AS FrecuenciaPago
            , (0) As InteresFinancieroMO
            , (0)* GETEXCHANGE(2,Pol.DISSUEDAT) As InteresFinancieroML
            , tblpolizasprimas.PTOTAL_ANUAL PTotalMO
            , tblpolizasprimas.PTOTAL_ANUAL * GETEXCHANGE(2,Pol.DISSUEDAT) PTotalML
            , TInte.NINTERTYP As CodTipoIntermediario
            , TRIM(TInte.sDescript) As TipoIntermediario
            , Inte.NINTERMED As CodIntermediario
            , INITCAP(LOWER(RTRIM(CliInte.sCliename))) As Intermediario
            , 0 PrimaDevolverCobrarMO 
            , 0 PrimaDevolverCobrarML
            , tblPorcentajeIntermediario.porcentaje AS PorcentajeComision
            , tblPolizasPrimas.PNETA_ANUAL * (tblPorcentajeIntermediario.porcentaje/100) AS ValorComisionMO
            , ( tblPolizasPrimas.PNETA_ANUAL * GETEXCHANGE(2,Pol.DISSUEDAT)) * (tblPorcentajeIntermediario.porcentaje/100)  AS ValorComisionML
            --, nvl(Comi.NPERCENT,0) PorcentajeComision --TO-DO
            --, nvl(Comi.NAMOUNT,0)  ValorComisionMO --TO-DO
            --, nvl(Comi.NAMOUNT,0)* GETEXCHANGE(2,Pol.DISSUEDAT) ValorComisionML --TO-DO
            , cert.Nbill_day AS DiadeCobro                                                        
            , TPol.sdescript As TipoPoliza
            , TRIM(Prod.sshort_des) AS ProductoAbreviado
            
			FROM POLICY pol            
            INNER JOIN Certificat cert On Pol.scertype= Cert.scertype and Pol.Nbranch= Cert.NBranch 
                       and Pol.NProduct= Cert.NProduct and Pol.NPolicy = Cert.NPolicy and cert.ncertif=0            
            
            CROSS APPLY (                                    
                    SELECT SUM(NVL(C.NTAXAMOUNT,0)) IVA_ANUAL,
                           SUM(NVL(C.NRECAMOUNT,0)) RECARGO_ANUAL,
                           SUM(NVL(C.NDESCAMOUNT,0))DESCUENTO_ANUAL,
                           SUM(NVL(C.NPREMIUM,0)) PNETA_ANUAL,
                           SUM(NVL(C.NPREMIUM,0))+ SUM(NVL(C.NRECAMOUNT,0))+SUM(NVL(C.NTAXAMOUNT,0)) -  SUM(NVL(C.NDESCAMOUNT,0)) PTOTAL_ANUAL
                      FROM COVER C
                     WHERE C.SCERTYPE    = cert.SCERTYPE
                       AND C.NBRANCH     = cert.NBRANCH
                       AND C.NPRODUCT    = cert.NPRODUCT
                       AND C.NPOLICY     = cert.NPOLICY
                       AND C.NCERTIF     = cert.NCERTIF
                      -- AND C.DEFFECDATE <= NVL(QUEDATPOLICY.DEFFECDATE, SYSDATE)
                      -- AND (C.DNULLDATE IS NULL
                      --  OR C.DNULLDATE   > NVL(QUEDATPOLICY.DEFFECDATE, SYSDATE))                                    
                 )tblPolizasPrimas
            CROSS APPLY (
                   SELECT NVL(xpre.npercent,0) Porcentaje 
                   FROM DISC_XPREM xpre
                   INNER JOIN DISCO_EXPR D_XPre ON XPre.NDISC_CODE= D_XPre.NDISEXPRC 
                                                  AND XPre.NBranch=  D_XPre.NBranch 
                                                  AND xpre.nproduct= D_XPre.NProduct
                                                  AND D_Xpre.NDISEXPRC = 20 --Costo de Intermediacion                                                  
                   WHERE XPre.npolicy=cert.npolicy and XPre.scertype= cert.scertype  
                         and XPre.nbranch= cert.nbranch and XPre.nproduct=cert.nproduct
                         and XPre.ncertif= cert.ncertif
                         and XPre.dnulldate is null
            ) tblPorcentajeIntermediario
            INNER JOIN prodmaster Prod On Pol.NBranch= Prod.NBranch and Pol.NProduct = Prod.NProduct            
            INNER JOIN ROLES Rol ON Cert.Scertype=Rol.Scertype and Cert.NBranch=Rol.NBranch 
							and Cert.Nproduct=Rol.Nproduct and Cert.NPolicy=Rol.NPolicy
							and Rol.NRole=1 and rol.dnulldate is null
            INNER JOIN Client CliCont on Rol.sclient = CliCont.sclient		
            
            INNER JOIN Table10 Ram on pol.NBranch= Ram.NBranch 
            INNER JOIN TABLE5002 CanCobro ON cert.nway_pay= CanCobro.nway_pay
            INNER JOIN TABLE9 Reg On pol.noffice = reg.noffice
            INNER JOIN TABLE36 FPag ON cert.npayfreq = FPag.npayfreq
            INNER JOIN TABLE5532 CVen On cert.nsellchannel= cven.nsellchannel
            INNER JOIN TABLE5632 TCer On pol.scertype= tcer.scertype            
            INNER JOIN TABLE181 EPol On Pol.Sstatus_Pol= Epol.Sstatusva
            INNER JOIN TABLE17 TPol On Pol.spolitype= TPol.ncodigint
            LEFT JOIN TABLE37 LNeg On prod.sbrancht = lneg.sbrancht
            
            
            OUTER APPLY(SELECT x.ncurrency 
                        from CURREN_POL X 
                        WHERE pol.SCERTYPE=x.SCERTYPE and pol.NBRANCH=x.NBRANCH and pol.NPRODUCT=x.NPRODUCT and pol.NPOLICY=x.NPOLICY 
                        and x.dnulldate is null and rownum=1) tblMoneda
            LEFT JOIN TABLE11 Moneda on tblMoneda.ncurrency=Moneda.ncodigint
            
                        
            LEFT JOIN INTERMEDIA Inte On pol.NINTERMED = Inte.NINTERMED
            LEFT JOIN Client CliInte On Inte.sClient= CliInte.sClient
            LEFT JOIN INTERM_TYP TInte On Inte.NINTERTYP=  TInte.NINTERTYP
                       
            WHERE cert.ncertif=0             
             and Pol.SCERTYPE =   '2'                      
            ORDER BY Pol.DISSUEDAT DESC;