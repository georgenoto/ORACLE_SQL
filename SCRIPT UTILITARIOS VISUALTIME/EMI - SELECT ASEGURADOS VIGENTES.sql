WITH CoverDetails AS (
    SELECT
        COB.npolicy,
        COB.scertype,
        COB.nbranch,
        COB.nproduct,
        COB.ncertif,
        COB.sclient,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92250) THEN 'SI' ELSE 'NO' END) AS TieneMaternidad,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92000) AND BENEF.NBENEFCATEG = 11 AND BENEF.SBENEFCATEG_CODE = 'TA0001' THEN NVL(BENEF.npercen_hospital,0) ELSE 0 END) AS porcentajehospitalario,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92000) AND BENEF.NBENEFCATEG = 11 AND BENEF.SBENEFCATEG_CODE = 'TA0002' THEN NVL(BENEF.npercen_Ambulatory,0) ELSE 0 END) AS porcentajeambulatorio,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92000) AND BENEF.NBENEFCATEG = 5 AND BENEF.SBENEFCATEG_CODE = '2310101' THEN NVL(BENEF.npercen_Ambulatory,0) ELSE 0 END) AS PorcAmbulatorioMedicamentos,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92190, 92191) THEN 'SI' ELSE 'NO' END) AS TieneOdontologia,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92190, 92191) THEN BENEF.NAMOUNT_COPAY ELSE NULL END) AS coaseguroodontologico,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92190, 92191) THEN CLI.scliename ELSE NULL END) AS clinicaodontologica,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92200) THEN 'SI' ELSE 'NO' END) AS SeguroAlViajero,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92180) THEN CLI.scliename ELSE 'NO CUENTA CON ESTE SERVICIO' END) AS EmergenciaMedicas,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92220) THEN 'SI' ELSE 'NO' END) AS MuerteAccidental,
        MAX(CASE WHEN TLCOB.NCOVERGEN IN (92230) THEN 'SI' ELSE 'NO' END) AS Sepelio
    FROM COVER COB
    INNER JOIN LIFE_COVER LCOB ON COB.NBRANCH = LCOB.NBRANCH AND COB.NPRODUCT = LCOB.NPRODUCT AND COB.NCOVER = LCOB.NCOVER AND COB.NMODULEC = LCOB.NMODULEC AND LCOB.DNULLDATE IS NULL
    INNER JOIN TAB_LIFCOV TLCOB ON LCOB.NCOVERGEN = TLCOB.NCOVERGEN
    LEFT JOIN TAB_MEDBENEFITS BENEF
        ON COB.NBRANCH = BENEF.NBRANCH AND COB.NPRODUCT = BENEF.NPRODUCT AND COB.NPOLICY = BENEF.NPOLICY AND COB.NCERTIF = BENEF.NCERTIF
        AND COB.NMODULEC = BENEF.NMODULEC AND COB.NCOVER = BENEF.NCOVER AND COB.SCLIENT = BENEF.SCLIENT AND BENEF.DNULLDATE IS NULL
    LEFT JOIN LEND_AGREE_PRES LAGRE
        ON COB.scertype = LAGRE.scertype AND COB.nbranch = LAGRE.nbranch AND COB.nproduct = LAGRE.nproduct AND COB.npolicy = LAGRE.npolicy
        AND COB.nmodulec = LAGRE.nmodulec AND COB.sclient = LAGRE.sclient AND COB.ngroup_insu = LAGRE.ngroup AND COB.NCOVER = LAGRE.NCOVER
        AND LAGRE.dnulldate IS NULL
    LEFT JOIN AGREEMENT AGRE ON LAGRE.ncod_agree = AGRE.ncod_agree
    LEFT JOIN CLIENT CLI ON AGRE.sclient = CLI.sclient
    WHERE COB.dnulldate IS NULL
      AND TLCOB.NCOVERGEN IN (92250, 92000, 92190, 92191, 92200, 92180, 92220, 92230)
    GROUP BY
        COB.npolicy,
        COB.scertype,
        COB.nbranch,
        COB.nproduct,
        COB.ncertif,
        COB.sclient
)
SELECT
    1,
    VPOL.nbranch,
    vPol.SCERTYPE,
    row_number() over (ORDER BY vpol.nropoliza, cert.ncertif) as NroTotalAsegurado,
    row_number() over (PARTITION BY vpol.nropoliza ORDER BY vpol.nropoliza) as NroAseguradoPorCuenta,
    VPOL.nproduct,
    vpol.producto,
    '' AS Plan,
    vpol.tipopoliza As TipoPoliza,
    vpol.TipoFacturaColectivo,
    vpol.TipoDistribucion,
    VPOL.npolicy,
    vpol.codMonedaPoliza,
    vpol.MonedaPoliza,
    vpol.fechaemision,
    vpol.iniciovigenciapoliza,
    vpol.finvigenciapoliza,
    vpol.codestadopoliza,
    vpol.estadopoliza,
    vpol.CodRegionalPoliza,
    vpol.RegionalPoliza,
    vpol.codtipointermediario,
    vpol.TipoIntermediario,
    vpol.codintermediario,
    vpol.intermediario,
    vpol.capitalmo As CapitalAseguradoMO,
    vpol.capitalml As CapitalAseguradoLO,
    0 as NDEDUCIBLE_MO,
    0 as NDEDUCIBLE_LO,
    TRIM(ambgeo.sdescript) As AmbitoGeografico,
    TRIM(sisate.sdescript) As SistemaAtencion,
    vpol.contratante,
    cert.ncertif AS NroCertificado,
    aseg.sclient CodigoAsegurado,
    INITCAP(LOWER(RTRIM(aseg.sfirstname))) AS NombreAsegurado,
    INITCAP(LOWER(RTRIM(aseg.slastname))) || ' ' || INITCAP(LOWER(RTRIM(aseg.slastname2))) As ApellidosAsegurado,
    CASE WHEN rolAse.nstatusrol=1 THEN
        CASE WHEN rolAse.Dnulldate is null THEN TRIM(ease.sdescript) ELSE 'Excluido' END
    ELSE TRIM(ease.sdescript) END as EstadoAsegurado,
    TRIM(sexo.sdescript) As Genero,
    TRIM(crol.sdescript) As Relacion,
    TPer.sdescript TipoPersona,
    tblDocumento.tipoDocumentoCorto,
    tblDocumento.nrodocumento,
    tblDocumento.Complemento,
    rolAse.dbirthdate As FechaNacimiento,
    trunc(months_between(sysdate,rolAse.dbirthdate)/12) Edad,
    TRIM(cresi.sdescript) as CiudadResidencia,
    rolAse.deffecdate as FechaIngreso,
    rolAse.dnulldate as FechaEgreso,
    NULL AS FechaAntiguedad,
    0 as CapitalAntiguedad,
    tblCorreo.EmailAsegurado,
    TRIM(desExc.sdescript) as Exclusiones,
    NVL(tblOtroSeguro.SDESCRIPT,'NO') As OtroSeguro,
    NVL(cd.TieneMaternidad,'NO') AS TieneMaternidad,
    NVL(cd.porcentajehospitalario,0) AS porcentajehospitalario,
    NVL(cd.porcentajeambulatorio,0) AS porcentajeambulatorio,
    NVL(cd.PorcAmbulatorioMedicamentos,0) AS PorcAmbulatorioMedicamentos,
    NVL(cd.TieneOdontologia,'NO') AS TieneOdontologia,
    cd.coaseguroodontologico,
    cd.clinicaodontologica,
    NVL(cd.SeguroAlViajero,'NO') AS SeguroAlViajero,
    NVL(cd.EmergenciaMedicas,'NO') AS EmergenciaMedicas,
    NVL(cd.MuerteAccidental,'NO') AS MuerteAccidental,
    NVL(cd.Sepelio,'NO') AS Sepelio,
    null as FechaFinCredencial,
    '' As Condiciones,
    '' As Observaciones
FROM NS_View_DatosGeneralesPoliza vpol
INNER JOIN Certificat cert On vpol.scertype= Cert.scertype and vpol.Nbranch= Cert.NBranch
                            and vpol.NProduct= Cert.NProduct and vpol.NPolicy = Cert.NPolicy
INNER JOIN ROLES rolAse ON Cert.Scertype=rolAse.Scertype and Cert.NBranch=rolAse.NBranch
                        and Cert.Nproduct=rolAse.Nproduct and Cert.NPolicy=rolAse.NPolicy
                        and cert.ncertif= rolAse.ncertif
                        AND rolAse.NROLE NOT IN (1,13,25,87)
                        and rolAse.nstatusrol = 1 -- vigentes
INNER JOIN Client aseg on rolAse.sclient = aseg.sclient
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
LEFT JOIN Table5006 TPer On aseg.nperson_typ= tper.nperson_typ
LEFT JOIN TAB_AM_EXC excl ON Cert.scertype= excl.scertype and Cert.Nbranch= excl.NBranch
                           and Cert.NProduct= excl.NProduct and Cert.NPolicy = excl.NPolicy
                           and aseg.sclient = excl.sclient
LEFT JOIN TAB_AM_ILL desExc On excl.SILLNESS= desExc.SILLNESS
-- Subquery for email, kept as APPLY since it's on a different table set
OUTER APPLY (
    select adrs.se_mail EmailAsegurado
    from ADDRESS adrs
    WHERE adrs.sclient= aseg.sclient and adrs.scertype= vpol.scertype and adrs.npolicy= vpol.npolicy
    and adrs.dnulldate is null
    FETCH FIRST 1 ROW ONLY
) tblCorreo
-- Subquery for document, kept as APPLY for same reason
CROSS APPLY(
    select clidoc.ntypclientdoc codTipoDocumento, clidoc.sclinumdocu nroDocumento, tdoc.sshort_des tipoDocumentoCorto, clidoc.sidcompl Complemento
    from CLIDOCUMENTS cliDoc
    inner join FORMATVALUES tdoc on clidoc.ntypclientdoc = tdoc.ntypclientdoc
    where cliDoc.sclient=rolAse.sclient
    FETCH FIRST 1 ROWS ONLY
) tblDocumento
-- Consolidated coverage details
OUTER APPLY (
    SELECT 
        PRODAUX.nproduct,
        'SI,' || PRODAUX.SDESCRIPT AS SDESCRIPT,
        RAUX.SCLIENT
   FROM POLICY PAUX
   INNER JOIN CERTIFICAT CAUX ON PAUX.scertype= CAUX.scertype and PAUX.Nbranch= CAUX.NBranch 
                       and PAUX.NProduct= CAUX.NProduct and PAUX.NPolicy = CAUX.NPolicy 
   INNER JOIN ROLES RAUX ON CAUX.Scertype=RAUX.Scertype and CAUX.NBranch=RAUX.NBranch
                        and CAUX.Nproduct=RAUX.Nproduct and CAUX.NPolicy=RAUX.NPolicy
                        and CAUX.ncertif= RAUX.ncertif
                        AND RAUX.NROLE NOT IN (1,13,25,87)
   INNER JOIN prodmaster PRODAUX On PAUX.NBranch= PRODAUX.NBranch and PAUX.NProduct = PRODAUX.NProduct                    
   WHERE PAUX.SCERTYPE = '2'
   AND SYSDATE BETWEEN PAUX.DSTARTDATE AND PAUX.DEXPIRDAT
   AND (RAUX.DNULLDATE IS NULL OR RAUX.DNULLDATE < SYSDATE) 
   AND  RAUX.SCLIENT = ASEG.SCLIENT and PRODAUX.nproduct <> vpol.CodProducto
   FETCH FIRST 1 ROW ONLY  
) tblOtroSeguro
LEFT JOIN CoverDetails cd ON cert.npolicy = cd.npolicy AND cert.scertype = cd.scertype AND cert.nbranch = cd.nbranch
    AND cert.nproduct = cd.nproduct AND cert.ncertif = cd.ncertif AND aseg.sclient = cd.sclient
WHERE vPol.SCERTYPE = '2' 
AND VPOL.NROPOLIZA in (1016,1152,1180)