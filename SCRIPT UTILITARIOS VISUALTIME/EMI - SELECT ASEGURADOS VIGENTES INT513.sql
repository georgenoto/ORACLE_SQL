WITH cteCoberturas AS (
        -- CTE para detalles de cobertura, sin cambios
        SELECT
            COB.npolicy,
            COB.scertype,
            COB.nbranch,
            COB.nproduct,
            COB.ncertif,
            COB.sclient,  
            -- Solución alfabética: Si existe el caso, se concatena. Si no, devuelve 'NO'
            NVL(MAX(CASE WHEN TLCOB.NCOVERGEN = 92250 THEN ('SI - HASTA ' || COB.NCAPITAL) END), 'NO') AS TieneMaternidad,
            
            MAX(CASE WHEN TLCOB.NCOVERGEN = 92000 AND BENEF.NBENEFCATEG = 11 AND BENEF.SBENEFCATEG_CODE = 'TA0001' THEN NVL(BENEF.npercen_hospital, 0) ELSE 0 END) AS porcentajehospitalario,
            MAX(CASE WHEN TLCOB.NCOVERGEN = 92000 AND BENEF.NBENEFCATEG = 11 AND BENEF.SBENEFCATEG_CODE = 'TA0002' THEN NVL(BENEF.npercen_Ambulatory, 0) ELSE 0 END) AS porcentajeambulatorio,
            MAX(CASE WHEN TLCOB.NCOVERGEN = 92000 AND BENEF.NBENEFCATEG = 5 AND BENEF.SBENEFCATEG_CODE = '2310101' THEN NVL(BENEF.npercen_Ambulatory, 0) ELSE 0 END) AS PorcAmbulatorioMedicamentos,
            
            -- Se usa NVL fuera del MAX para evitar que 'NO' le gane a 'SI'
            NVL(MAX(CASE WHEN TLCOB.NCOVERGEN IN (92190, 92191) THEN 'SI' END), 'NO') AS TieneOdontologia,
            MAX(CASE WHEN TLCOB.NCOVERGEN IN (92190, 92191) THEN BENEF.NAMOUNT_COPAY END) AS coaseguroodontologico,
            MAX(CASE WHEN TLCOB.NCOVERGEN IN (92190, 92191) THEN CLI.SCLIENAME END) AS clinicaodontologica,
            
            NVL(MAX(CASE WHEN TLCOB.NCOVERGEN = 92200 THEN 'SI' END), 'NO') AS SeguroAlViajero,
            NVL(MAX(CASE WHEN TLCOB.NCOVERGEN = 92180 THEN CLI.SCLIENAME END), 'NO') AS EmergenciaMedicas,
            NVL(MAX(CASE WHEN TLCOB.NCOVERGEN = 92220 THEN 'SI' END), 'NO') AS MuerteAccidental,
            NVL(MAX(CASE WHEN TLCOB.NCOVERGEN = 92230 THEN 'SI' END), 'NO') AS Sepelio,
            
            --MAX(NVL(BENEF.NDED_TYPE, '0')) AS NDEDUCIBLE,
            MAX('N/A') AS NDEDUCIBLE, 
            MAX(CASE WHEN TLCOB.NCOVERGEN = 92000 THEN COB.NCAPITAL ELSE 0 END) AS CapitalAsegurado,
            MAX(CASE WHEN TLCOB.NCOVERGEN = 92000 THEN COB.DANTIDATE END) AS FechaAntiguedad,
            MAX(CASE WHEN TLCOB.NCOVERGEN = 92000 THEN COB.NANTI_AMOUNT END) AS CapitalAntiguedad
        FROM COVER COB
        INNER JOIN LIFE_COVER LCOB     ON COB.NBRANCH = LCOB.NBRANCH 
                                        AND COB.NPRODUCT = LCOB.NPRODUCT 
                                        AND COB.NCOVER = LCOB.NCOVER 
                                        AND COB.NMODULEC = LCOB.NMODULEC 
                                        AND LCOB.DNULLDATE IS NULL
        INNER JOIN TAB_LIFCOV TLCOB    ON LCOB.NCOVERGEN = TLCOB.NCOVERGEN
        LEFT JOIN TAB_MEDBENEFITS BENEF  ON COB.NBRANCH = BENEF.NBRANCH 
                                            AND COB.NPRODUCT = BENEF.NPRODUCT 
                                            AND COB.NPOLICY = BENEF.NPOLICY 
                                            AND COB.NCERTIF = BENEF.NCERTIF
                                            --AND COB.NMODULEC = BENEF.NMODULEC 
                                            AND COB.NCOVER = BENEF.NCOVER 
                                            AND COB.SCLIENT = BENEF.SCLIENT 
                                            AND BENEF.DNULLDATE IS NULL
        LEFT JOIN LEND_AGREE_PRES LAGRE     ON COB.NBRANCH = LAGRE.NBRANCH 
                                            AND COB.NPRODUCT = LAGRE.NPRODUCT 
                                            AND COB.NPOLICY = LAGRE.NPOLICY
                                            --AND COB.NMODULEC = LAGRE.NMODULEC 
                                            AND COB.SCLIENT = LAGRE.SCLIENT  
                                            AND COB.NCOVER = LAGRE.NCOVER
                                            AND LAGRE.DNULLDATE IS NULL
        LEFT JOIN AGREEMENT AGRE     ON LAGRE.NCOD_AGREE = AGRE.NCOD_AGREE
        LEFT JOIN CLIENT CLI     ON AGRE.SCLIENT = CLI.SCLIENT
        WHERE COB.DNULLDATE IS NULL
        AND COB.SCERTYPE = 2
        AND TLCOB.NCOVERGEN IN (92000, 92180, 92190, 92191, 92200, 92220, 92230, 92250)
        --AND COB.NPOLICY = 30
        GROUP BY
            COB.npolicy,
            COB.scertype,
            COB.nbranch,
            COB.nproduct,            
            COB.ncertif,
            COB.sclient
    ),cteBeneficios as(
            SELECT               
                 M.NPRODUCT, M.NMODULEC, M.NPOLICY, M.NCERTIF, M.SCLIENT,
                 MAX(CASE WHEN TL.NCOVERGEN IN (92000) AND M.NBENEFCATEG = 11 AND M.SBENEFCATEG_CODE = 'TA0001' THEN NVL(M.NPERCEN_HOSPITAL,0) ELSE 0 END) AS porcentajehospitalario,
                 MAX(CASE WHEN TL.NCOVERGEN IN (92000) AND M.NBENEFCATEG = 11 AND M.SBENEFCATEG_CODE = 'TA0002' THEN NVL(M.NPERCEN_AMBULATORY,0) ELSE 0 END) AS porcentajeambulatorio,
                 MAX(CASE WHEN TL.NCOVERGEN IN (92000) AND M.NBENEFCATEG = 8 AND M.SBENEFCATEG_CODE = '23' THEN NVL(M.NPERCEN_AMBULATORY,0) ELSE 0 END) AS PorcAmbulatorioMedicamentos,                                             
                 MAX(CASE WHEN TL.NCOVERGEN IN (92000) AND M.NBENEFCATEG = 9 AND M.SBENEFCATEG_CODE = '1010' THEN NVL(M.NAMOUNT_COPAY,0) ELSE 0 END) AS Consulta_Coaseguro  
            FROM TAB_MEDBENEFITS M
            INNER JOIN LIFE_COVER LC ON M.NBRANCH= LC.NBRANCH AND M.NCOVER = LC.NCOVER AND M.NPRODUCT = LC.NPRODUCT AND M.NMODULEC= LC.NMODULEC
            INNER JOIN TAB_LIFCOV TL ON LC.NCOVERGEN = TL.NCOVERGEN
            LEFT JOIN TABLE269 T269 ON M.NDED_TYPE= T269.NDED_TYPE
            LEFT JOIN TABLE52 T52 ON M.SCAREN_TYPE = T52.SCAREN_TYPE
            WHERE M.DNULLDATE IS NULL
              AND TL.NCOVERGEN IN (92000)
              AND M.SCERTYPE = 2
              GROUP BY M.NPRODUCT, M.NMODULEC, M.NPOLICY, M.NCERTIF, M.SCLIENT            
    ) ,
    cteEmails AS (
        -- CTE para obtener el primer correo electrOnico por cliente y pOliza
        SELECT
            adrs.sclient,
            adrs.scertype,
            adrs.npolicy,
            adrs.se_mail AS EmailAsegurado,
            ROW_NUMBER() OVER(PARTITION BY adrs.sclient, adrs.scertype, adrs.npolicy ORDER BY adrs.deffecdate DESC) as rn
        FROM ADDRESS adrs
        WHERE adrs.dnulldate IS NULL
    ),
    cteDocCliente AS (
        -- CTE para obtener el primer documento por cliente
        SELECT
            cliDoc.sclient,
            cliDoc.ntypclientdoc AS codTipoDocumento,
            cliDoc.sclinumdocu AS nroDocumento,
            tdoc.sshort_des AS tipoDocumentoCorto,
            cliDoc.sidcompl AS Complemento,
            ROW_NUMBER() OVER(PARTITION BY cliDoc.sclient ORDER BY clidoc.ntypclientdoc) as rn
        FROM CLIDOCUMENTS cliDoc
        INNER JOIN FORMATVALUES tdoc ON cliDoc.ntypclientdoc = tdoc.ntypclientdoc
        WHERE tdoc.NCLASSTYPDOC=2
    ),
    cteOtroSeguro AS (
        -- CTE para encontrar si un cliente tiene otras pOlizas activas
        SELECT
            RAUX.SCLIENT,
            PRODAUX.nproduct,
            SUBSTR('SI,' || TRIM(PRODAUX.SDESCRIPT), 1, 199) AS SDESCRIPT,
            ROW_NUMBER() OVER(PARTITION BY RAUX.SCLIENT ORDER BY PAUX.NPolicy) as rn
       FROM POLICY PAUX
       INNER JOIN CERTIFICAT CAUX ON PAUX.scertype= CAUX.scertype and PAUX.Nbranch= CAUX.NBranch
                           and PAUX.NProduct= CAUX.NProduct and PAUX.NPolicy = CAUX.NPolicy
       INNER JOIN ROLES RAUX ON CAUX.Scertype=RAUX.Scertype and CAUX.NBranch=RAUX.NBranch
                            and CAUX.Nproduct=RAUX.Nproduct and CAUX.NPolicy=RAUX.NPolicy
                            and CAUX.ncertif= RAUX.ncertif
                            AND RAUX.NROLE NOT IN (1,13,25,87)
       INNER JOIN prodmaster PRODAUX On PAUX.NBranch= PRODAUX.NBranch and PAUX.NProduct = PRODAUX.NProduct
       WHERE PAUX.SCERTYPE = '2'
       AND PAUX.SSTATUS_POL IN (1,4,5) --TABLE181
       AND SYSDATE BETWEEN PAUX.DSTARTDATE AND PAUX.DEXPIRDAT
       AND (RAUX.DNULLDATE IS NULL OR RAUX.DNULLDATE < SYSDATE)
    ), TasaCambioDolar AS (    
    SELECT   COALESCE(e.NEXCHANGE, 0) as TC_DOLAR,
             e.DEFFECDATE,   
             ROW_NUMBER() OVER(ORDER BY e.DEFFECDATE DESC)  as rn       
    FROM  EXCHANGE e 
    WHERE e.NCURRENCY = 2 -- Moneda dólar.
           AND e.DEFFECDATE <= SYSDATE
           AND (e.DNULLDATE IS NULL OR e.DNULLDATE > SYSDATE) 
    ),
    ctePrimerPoliza AS (
        -- CTE para encontrar si un cliente tiene otras pOlizas activas
        SELECT
            RAUX.SCLIENT,
            PAUX.NPolicy As NroPoliza,           
            PAUX.DSTARTDATE As InicioVigencia,
            ROW_NUMBER() OVER(PARTITION BY RAUX.SCLIENT ORDER BY PAUX.NPolicy ASC) as rn
       FROM POLICY PAUX
       INNER JOIN CERTIFICAT CAUX ON PAUX.scertype= CAUX.scertype and PAUX.Nbranch= CAUX.NBranch
                           and PAUX.NProduct= CAUX.NProduct and PAUX.NPolicy = CAUX.NPolicy
       INNER JOIN ROLES RAUX ON CAUX.Scertype=RAUX.Scertype and CAUX.NBranch=RAUX.NBranch
                            and CAUX.Nproduct=RAUX.Nproduct and CAUX.NPolicy=RAUX.NPolicy
                            and CAUX.ncertif= RAUX.ncertif
                            AND RAUX.NROLE NOT IN (1,13,25,87)
       INNER JOIN prodmaster PRODAUX On PAUX.NBranch= PRODAUX.NBranch and PAUX.NProduct = PRODAUX.NProduct
       WHERE PAUX.SCERTYPE = '2'
       and PAUX.SSTATUS_POL NOT IN (2,3,7,8)       
    ), cteInfoEspecial as(
       SELECT  evaRol.SCERTYPE, evaRol.NBRANCH, evaRol.NPRODUCT, evaRol.NPOLICY, evaRol.NCERTIF, evaRol.NROLE, evaRol.SCLIENT
               ,SUBSTR(TRIM(T9216.SDESCRIPT) || ' ' || TO_CHAR(evaRol.NNOTENUM), 1, 299) AS InfoEspecial
               ,ROW_NUMBER() OVER(PARTITION BY evaRol.NPOLICY, evaRol.SCLIENT ORDER BY evaRol.NPOLICY ASC) as rn
       FROM MEDICAL_EVAL_ROL evaRol
       INNER JOIN TABLE9216 T9216 ON evaRol.NMEDICALSTAT= T9216.NMEDICALSTAT 
       WHERE evaRol.NMEDICALSTAT NOT IN (1) 
       AND evaRol.NROLE NOT IN (1,13,25,87)
    ),cteExclusionesCarencia as (
            SELECT excl.scertype,excl.NBranch,excl.NProduct,excl.NPolicy,excl.sclient 
                ,SUBSTR(
                    RTRIM(
                        XMLAGG(
                            XMLELEMENT(E,
                                CASE WHEN excl.STYPE_EXC=1 THEN
                                    TRIM(desExc.sdescript) || ' ' || TRIM(excl.sdescript) || ', '
                                END
                            )
                            ORDER BY excl.NPolicy,excl.sclient
                        ).EXTRACT('//text()').getClobVal()
                    , ', ')
                , 1, 200) AS Exclusiones
                ,SUBSTR(
                    RTRIM(
                        XMLAGG(
                            XMLELEMENT(E,
                                CASE WHEN excl.STYPE_EXC=2 THEN
                                    CASE WHEN excl.DINIT_DATE IS NOT NULL AND excl.DEND_DATE IS NOT NULL THEN
                                        TRIM(desExc.sdescript) || ' Desde: ' || TO_CHAR(NVL(excl.DINIT_DATE, SYSDATE), 'DD-MM-YYYY') || ' Hasta: ' || TO_CHAR(NVL(excl.DEND_DATE, SYSDATE), 'DD-MM-YYYY') || ' ' || TRIM(excl.sdescript)
                                    WHEN excl.DINIT_DATE IS NOT NULL AND excl.DEND_DATE IS NULL THEN
                                        TRIM(desExc.sdescript) || ' Desde: ' || TO_CHAR(NVL(excl.DINIT_DATE, SYSDATE), 'DD-MM-YYYY') || ' ' || TRIM(excl.sdescript)
                                    ELSE
                                        TRIM(desExc.sdescript) || ' ' || TRIM(excl.sdescript)
                                    END || ', '
                                END
                            )
                            ORDER BY excl.NPolicy,excl.sclient
                        ).EXTRACT('//text()').getClobVal()
                    , ', ')
                , 1, 200) AS CarenciasParticulares
                FROM TAB_AM_EXC excl 
                LEFT JOIN TAB_AM_ILL desExc On excl.SILLNESS= desExc.SILLNESS    
                WHERE  excl.DNULLDATE IS NULL
                GROUP BY excl.scertype, excl.NBranch, excl.NProduct, excl.NPolicy, excl.sclient
    ), cteAmpliacionVigencia AS (
      SELECT  HIS.NBRANCH, HIS.NPRODUCT, HIS.NPOLICY, HIS.NMOVEMENT, HIS.DEFFECDATE
        FROM POLICY_HIS HIS
        WHERE HIS.SCERTYPE=2 AND NTYPE_AMEND=9224 AND DNULLDATE IS NULL
    )
    SELECT

        ROW_NUMBER() OVER(ORDER BY vpol.CodRegionalPoliza,vpol.NPOLICY, cert.NCERTIF,rolAse.NCOVERPOS) AS NRO_TOTAL_ASEGURADO
        ,ROW_NUMBER() OVER(PARTITION BY vpol.NPOLICY ORDER BY cert.NCERTIF,rolAse.NCOVERPOS) AS NRO_TOTAL_ASEGURADOXCUENTA
        ,SUBSTR(UPPER(REGEXP_REPLACE(TRIM(vpol.producto), '[.,-]', '')),1,199) PRODUCTO
        ,SUBSTR(UPPER(SUBSTR(TRIM(VPOL.nproduct),1,100)) || ' ' || UPPER(SUBSTR(TRIM(vpol.ProductoAbreviado),1,90)),1,199) AS DESCRIPCION_ABREVIADA
        ,SUBSTR(UPPER(TRIM(vpol.tipopoliza)),1,99) As TIPO_POLIZA
        ,TO_CHAR(vpol.fechaemision , 'DD-MM-YYYY') AS FECHA_EMISION_POLIZA
        ,SUBSTR(UPPER(TRIM(vpol.RegionalPoliza)),1,199) AS REGIONALPOLIZA
        ,VPOL.npolicy AS NRO_POLIZA
        ,cert.ncertif AS NRO_CERTIFICADO
        ,CASE WHEN vpol.CodMonedaPoliza = 1 THEN nvl(cd.CapitalAsegurado,0) ELSE NULL END CAPITAL_ASEGURADO_BS
        ,CASE WHEN vpol.CodMonedaPoliza = 2 THEN nvl(cd.CapitalAsegurado,0) ELSE NULL END CAPITAL_ASEGURADO_SUS
        ,CASE WHEN vpol.CodMonedaPoliza = 1 THEN nvl(cd.NDEDUCIBLE,0) ELSE NULL END DEDUCIBLE_BS
        ,CASE WHEN vpol.CodMonedaPoliza = 2 THEN nvl(cd.NDEDUCIBLE,0) ELSE NULL END DEDUCIBLE_SUS
        ,SUBSTR(UPPER(TRIM(ambgeo.sdescript)),1,199) AS AMBITO_GEOGRAFICO
        --,SUBSTR(UPPER(TRIM(sisate.sdescript)),1,299) As TIPO_RED_MEDICA
        ,CASE WHEN vpol.NPRODUCT IN (2,3) THEN 'SEGUNDA RED' ELSE 'PRIMERA RED' END AS TIPO_RED_MEDICA
        ,SUBSTR(UPPER(TRIM(TP_CONT.sshort_des)),1,199) AS TIPO_PERSONA_CONTRATANTE
        ,SUBSTR(UPPER(REGEXP_REPLACE(TRIM(vpol.contratante), '[.,]', '')),1,499) CONTRATANTE
        ,SUBSTR(UPPER(TRIM(cresi.sdescript)),1,199) AS CIUDAD_RESIDENCIA_ASEGURADO
        ,TO_CHAR(tblPP.InicioVigencia , 'DD-MM-YYYY')  as  FECHA_INGRESO        
        ,TO_CHAR(cd.FechaAntiguedad , 'DD-MM-YYYY') AS FECHA_ANTIGUEDAD
        ,cd.CapitalAntiguedad as VALOR_ASEGURADO_ANTIGUEDAD
        ,TO_CHAR(rolAse.deffecdate , 'DD-MM-YYYY')  as FECHA_INCLUSION_ASEGURADO 
        ,TO_CHAR(rolAse.dnulldate , 'DD-MM-YYYY')  as FECHA_EXCLUSION_ASEGURADO       
        ,TO_CHAR(vpol.iniciovigenciapoliza , 'DD-MM-YYYY')  AS INICIO_VIGENCIA_POLIZA
        ,TO_CHAR(vpol.finvigenciapoliza , 'DD-MM-YYYY')  AS TERMINO_VIGENCIA_POLIZA
        ,(CASE WHEN TO_CHAR( NVL(vpol.finvigenciapoliza, SYSDATE), 'YYYYMMDD') < TO_CHAR(SYSDATE , 'YYYYMMDD') 
            THEN 'VENCIDA'
            ELSE    CASE WHEN rolAse.nstatusrol=1 
                             THEN 
                                    CASE WHEN rolAse.Dnulldate IS NULL 
                                    THEN  CASE WHEN CAmp.NPolicy IS NULL  THEN  UPPER(TRIM(ease.sdescript)) ELSE   'VIGENTE CON AMPLIACION DE VIGENCIA '  END
                                    ELSE 'EXCLUIDO' END  
                           ELSE UPPER(TRIM(ease.sdescript)) END 
          END)   as ESTADO_ASEGURADO
        ,SUBSTR(UPPER(TRIM(REGEXP_REPLACE(aseg.sfirstname, '[.,]'))), 1, 800) AS NOMBRE_ASEGURADO
        ,SUBSTR(UPPER(TRIM(REGEXP_REPLACE(aseg.slastname || ' ' || aseg.slastname2, '[.,]'))), 1, 840) AS APELLIDOS_ASEGURADO      
        ,UPPER(TRIM(sexo.sdescript)) As GENERO
        ,CASE crol.nrole WHEN 22  THEN DECODE(sexo.SSEXCLIEN,1, 'HIJA', 'HIJO')
                        WHEN 24  THEN DECODE(sexo.SSEXCLIEN,1, 'HERMANA', 'HERMANO')
                        WHEN 32  THEN DECODE(sexo.SSEXCLIEN,1, 'SOBRINA', 'SOBRINO')
                        WHEN 33  THEN DECODE(sexo.SSEXCLIEN,1, 'TIA', 'TIO')
                        WHEN 67  THEN DECODE(sexo.SSEXCLIEN,1, 'NIETA', 'NIETO')
                        WHEN 68  THEN DECODE(sexo.SSEXCLIEN,1, 'ABUELA', 'ABUELO')
                        ELSE UPPER(TRIM(crol.sdescript))
                        END RELACION
        ,SUBSTR(UPPER(TRIM(tblDocumento.tipoDocumentoCorto)),1,199) TIPO_DOCUMENTO
        ,tblDocumento.nrodocumento AS NRO_DOCUMENTO
        ,UPPER(TRIM(tblDocumento.Complemento)) AS COMPLEMENTO      
        ,SUBSTR(UPPER(TRIM(NVL(LUGNAC.sdescript,'BOLIVIA'))),1,199) AS LUGAR_NAC_ASEGURADO                
        ,TO_CHAR(rolAse.dbirthdate , 'DD-MM-YYYY') As FECHA_NACIMIENTO                     
        ,trunc(months_between(sysdate,rolAse.dbirthdate)/12) EDAD       
        ,aseg.sclient AS COD_ASEGURADO
        ,DBMS_LOB.SUBSTR(EXCL.Exclusiones, 950, 1) EXCLUSIONES_PARTICULARES
        ,DBMS_LOB.SUBSTR(EXCL.CarenciasParticulares, 950, 1) CARENCIAS_PARTICULARES
        --,SUBSTR(UPPER(TRIM(EXCL.Exclusiones)),1,299) EXCLUSIONES_PARTICULARES
        --,SUBSTR(UPPER(TRIM(EXCL.CarenciasParticulares)),1,299) CARENCIAS_PARTICULARES        
        ,SUBSTR(UPPER(TRIM(tblInfo.InfoEspecial)),1,299) AS INFORMACION_ESPECIAL 
        ,NVL(UPPER(tblOtroSeguro.SDESCRIPT),'NO') As OTRO_SEGURO
        ,NVL(UPPER(cd.TieneMaternidad),'NO') AS COB_MATERNIDAD
        ,NVL(tblBene.porcentajeambulatorio,0) AS PORC_AMBULATORIA
        ,NVL(tblBene.porcentajehospitalario,0) AS PORC_HOSPITALARIA        
        ,NVL(tblBene.PorcAmbulatorioMedicamentos,0) AS PORC_MEDICAMENTOS_AMBULATORIOS
        ,NVL(UPPER(cd.TieneOdontologia),'NO') AS COB_ADICIONAL_ODONTOLOGICA
--        ,SUBSTR(UPPER(CASE WHEN NVL(cd.coaseguroodontologico,0) <> 0 THEN 
--                            CASE WHEN vpol.CodMonedaPoliza = 1 THEN 'Bs.- ' || TO_CHAR(cd.coaseguroodontologico) || ' COASEGURO CONSULTAS'  
--                            ELSE '$US.- ' || TO_CHAR(cd.coaseguroodontologico) || ' COASEGURO CONSULTAS'   END 
--        ELSE '' END),1,499) COASEGURO_ODONTOLOGICO
        , CASE WHEN NVL(UPPER(cd.TieneOdontologia),'NO') = 'NO' THEN NULL ELSE 'BS 70' END COASEGURO_ODONTOLOGICO
        ,SUBSTR(UPPER(REGEXP_REPLACE(TRIM(cd.clinicaodontologica), '[.,]', '')),1,499) CLINICA_ODONTOLOGICA
        ,NVL(UPPER(cd.SeguroAlViajero),'NO') AS SEGURO_VIAJERO
        ,CASE WHEN cd.EmergenciaMedicas IS NULL THEN 'NO' ELSE 'SI' END EMERGENCIA_MEDICA
        ,SUBSTR(UPPER(REGEXP_REPLACE(TRIM(NVL(cd.EmergenciaMedicas,'')), '[.,]', '')),1,499) PROVEEDOR_EMERGENCIA_MEDICA
        ,NVL(UPPER(cd.MuerteAccidental),'NO') AS MUERTE_ACCIDENTAL
        ,NVL(UPPER(cd.Sepelio),'NO') AS SEPELIO
        ,SUBSTR(UPPER(TRIM(vpol.TipoIntermediario)),1,99) TIPO_INTERMEDIARIO
        ,SUBSTR(UPPER(REGEXP_REPLACE(TRIM(vpol.intermediario), '[.,]', '')),1,299) INTERMEDIARIO
        ,UPPER(CASE WHEN NVL(tblBene.Consulta_Coaseguro,0) <> 0 THEN 
                            CASE WHEN vpol.CodMonedaPoliza = 1 THEN 'Bs.- ' || TO_CHAR(tblBene.Consulta_Coaseguro) || ' COASEGURO CONSULTAS'  
                            ELSE '$US.- ' || TO_CHAR(tblBene.Consulta_Coaseguro) || ' COASEGURO CONSULTAS'   END 
        ELSE '' END) As COND_COASEGURO_CONSULTA 
        ,SUBSTR(UPPER(TRIM(tblCorreo.EmailAsegurado)),1,299) CORREO_ASEGURADO
        --,SUBSTR(UPPER(TRIM(TPer.sdescript)),1,199) AS TIPO_PERSONA_ASEGURADO
        
        
--        VPOL.nbranch,
--        vPol.SCERTYPE,
--        SUBSTR(UPPER(VPOL.nproduct),1,20) NPRODUCT,
--        NULL AS Plan,
--        SUBSTR(UPPER(TRIM(vpol.TipoFacturaColectivo)),1,199) AS TIPOFACTURACOLECTIVO,
--        SUBSTR(UPPER(TRIM(vpol.TipoDistribucion)),1,199) AS TIPODISTRIBUCION ,

--        vpol.codMonedaPoliza,
--        UPPER(TRIM(vpol.MonedaPoliza)) AS MONEDAPOLIZA,        
--        vpol.codestadopoliza,
--        SUBSTR((CASE WHEN TO_CHAR( NVL(vpol.finvigenciapoliza, SYSDATE), 'YYYYMMDD') < TO_CHAR(SYSDATE , 'YYYYMMDD') 
--                THEN 'VENCIDA' 
--                ELSE UPPER(TRIM(vpol.estadopoliza))  
--               END),1,199) as estadopoliza,        
--        vpol.CodRegionalPoliza,        
--        vpol.codtipointermediario,        
--        vpol.codintermediario,
        --cd.coaseguroodontologico,              
--        null as FechaFinCredencial,              
--        '' As Observaciones,
--        CASE WHEN vpol.CodMonedaPoliza = 1 THEN 1 ELSE Tasa.TC_DOLAR END AS TIPO_CAMBIO,
--        UPPER(TRIM(ECert.sdescript)) As EstadoCertificado
   
    FROM NS_View_DatosGeneralesPoliza vpol
    INNER JOIN Certificat cert On vpol.scertype= Cert.scertype and vpol.Nbranch= Cert.NBranch
                                and vpol.NProduct= Cert.NProduct and vpol.NPolicy = Cert.NPolicy
    INNER JOIN ROLES rolAse ON Cert.Scertype=rolAse.Scertype and Cert.NBranch=rolAse.NBranch
                            and Cert.Nproduct=rolAse.Nproduct and Cert.NPolicy=rolAse.NPolicy
                            and cert.ncertif= rolAse.ncertif
                            AND rolAse.NROLE NOT IN (1,13,25,87,91)
                            and (rolAse.dnulldate is null or SYSDATE < rolAse.dnulldate)
    INNER JOIN Client aseg on rolAse.sclient = aseg.sclient
    INNER JOIN CLIENT CONT ON vpol.CODCONTRATANTE = CONT.SCLIENT
    INNER JOIN MODUL_INSURED planaseg On Cert.scertype= planaseg.scertype and Cert.Nbranch= planaseg.NBranch
                                       and Cert.NProduct= planaseg.NProduct and Cert.NPolicy = planaseg.NPolicy
                                       and cert.ncertif= planaseg.ncertif
                                       and aseg.sclient = planaseg.sclient
    INNER JOIN MODULES mdlo ON planaseg.scertype= mdlo.scertype and planaseg.Nbranch= mdlo.NBranch
                           and planaseg.NProduct= mdlo.NProduct and planaseg.NPolicy = mdlo.NPolicy
                           and cert.ncertif= mdlo.ncertif
                           and mdlo.nmodulec= planaseg.nmodulec
    INNER JOIN TABLE9214 ambgeo ON mdlo.NGEOGRAPHAREA= ambgeo.NGEOGRAPHAREA
    INNER JOIN TABLE9215 sisate on mdlo.NATTENSYSTEM= sisate.NATTENSYSTEM
    INNER JOIN Table12 crol on rolAse.nrole= crol.nrole
    INNER JOIN Table5561 ease on rolAse.nstatusrol= ease.nstatusrol
    LEFT JOIN table66 pres ON aseg.nresidencecountry= pres.ncountry
    LEFT JOIN table18 sexo ON rolAse.ssexclien= sexo.ssexclien
    LEFT JOIN table9 cresi On rolAse.ncity_residence= cresi.noffice
    LEFT JOIN TABLE66 LUGNAC ON aseg.NBIRTHCOUNTRY = LUGNAC.NCOUNTRY
    LEFT JOIN Table5006 TPer On aseg.nperson_typ= tper.nperson_typ
    LEFT JOIN TABLE5006 TP_CONT ON CONT.NPERSON_TYP	= TP_CONT.NPERSON_TYP
    LEFT JOIN cteEmails tblCorreo ON tblCorreo.sclient = aseg.sclient AND tblCorreo.scertype = vpol.scertype AND tblCorreo.npolicy = vpol.npolicy AND tblCorreo.rn = 1
    LEFT JOIN cteDocCliente tblDocumento ON tblDocumento.sclient = rolAse.sclient AND tblDocumento.rn = 1
    LEFT JOIN cteOtroSeguro tblOtroSeguro ON tblOtroSeguro.SCLIENT = ASEG.SCLIENT AND tblOtroSeguro.nproduct <> vpol.nproduct AND tblOtroSeguro.rn = 1
    LEFT JOIN cteCoberturas cd ON cert.npolicy = cd.npolicy AND cert.scertype = cd.scertype AND cert.nbranch = cd.nbranch
        AND cert.nproduct = cd.nproduct AND cert.ncertif = cd.ncertif AND aseg.sclient = cd.sclient   
    LEFT JOIN cteBeneficios tblBene ON  cert.NPRODUCT = tblBene.NPRODUCT and planaseg.NMODULEC = tblBene.NMODULEC   
                                        and cert.NPOLICY = tblBene.NPOLICY and cert.NCERTIF= tblBene.NCERTIF
                                        and aseg.SCLIENT= tblBene.SCLIENT    
    LEFT JOIN TasaCambioDolar Tasa ON tasa.rn=1
    LEFT JOIN ctePrimerPoliza tblPP ON aseg.sclient = tblPP.sclient AND tblPP.rn=1
    LEFT JOIN cteInfoEspecial tblInfo ON Cert.scertype= tblInfo.scertype and Cert.Nbranch= tblInfo.NBranch
                                       and Cert.NProduct= tblInfo.NProduct and Cert.NPolicy = tblInfo.NPolicy
                                       and aseg.sclient = tblInfo.sclient
                                       and tblInfo.rn=1
                                       --and cert.NRole = tblInfo.NRole
    LEFT JOIN cteExclusionesCarencia EXCL ON  Cert.scertype= excl.scertype  AND Cert.Nbranch= excl.NBranch
                                                AND Cert.NProduct=excl.NProduct AND Cert.NPolicy = excl.NPolicy
                                                AND aseg.sclient=excl.sclient                                             
    LEFT JOIN TABLE181 ECert On cert.SSTATUSVA = ECert.SSTATUSVA
    LEFT JOIN cteAmpliacionVigencia CAmp ON vpol.NBRANCH= CAmp.NBRANCH AND vpol.NProduct = CAmp.NProduct AND vpol.NPOLICY=CAmp.NPolicy  
    
    WHERE vPol.SCERTYPE = '2' 
    AND vpol.codestadopoliza NOT IN (2,3,6,7,8) -- SE QUITAN LAS POLIZAS QUE NO ESTAN ACTIVAS
    AND CERT.SSTATUSVA NOT IN (2,3,6,7,8) -- SE QUITAR LOS CERTIFICADOS QUE NO ESTAN ACTIVOS 
    AND vPol.FechaEmision <= SYSDATE
    AND TO_CHAR(SYSDATE , 'YYYYMMDD') <= TO_CHAR(vpol.FinVigenciaPoliza, 'YYYYMMDD')
    