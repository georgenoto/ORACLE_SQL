CREATE OR REPLACE NONEDITIONABLE  VIEW NS_View_DatosGeneralesPoliza
AS
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
			, CanCobro.nway_pay AS IdCanalCobroAsignado
            , TRIM(CanCobro.sDescript) AS CanalCobroAsignado 
            , FPag.npayfreq As CodFrecuenciaPago
            , TRIM(FPag.sDescript) AS FrecuenciaPago
            
            , TInte.NINTERTYP As CodTipoIntermediario
            , TRIM(TInte.sDescript) As TipoIntermediario
            , Inte.NINTERMED As CodIntermediario
            , INITCAP(LOWER(RTRIM(CliInte.sCliename))) As Intermediario           
            , cert.Nbill_day AS DiadeCobro                                                        
            , TPol.sdescript As TipoPoliza
            , TRIM(Prod.sshort_des) AS ProductoAbreviado
            ,CASE pol.SPOLITYPE WHEN '1' THEN 'Póliza Individual' ELSE pol.SCOLINVOT||' - '||REAGENERALPKG.REACODIGINT('TABLE50','SCOLINVOT',pol.SCOLINVOT) END AS TipoFacturaColectivo
            ,TRIM(pol.STYPDIS_PAYPERCEN||' - '||REAGENERALPKG.REACODIGINT('TABLE9235','STYPDIS_PAYPERCEN',pol.STYPDIS_PAYPERCEN)) AS TipoDistribucion
			
			FROM POLICY pol            
            INNER JOIN Certificat cert On Pol.scertype= Cert.scertype and Pol.Nbranch= Cert.NBranch 
                       and Pol.NProduct= Cert.NProduct and Pol.NPolicy = Cert.NPolicy and cert.ncertif=0            
                            
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
             --AND pol.npolicy=28
            ORDER BY Pol.DISSUEDAT DESC;