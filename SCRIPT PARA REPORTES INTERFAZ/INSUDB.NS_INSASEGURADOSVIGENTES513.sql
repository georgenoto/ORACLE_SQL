CREATE OR REPLACE PROCEDURE INSUDB.NS_INSASEGURADOSVIGENTES513
/*-------------------------------------------------------------------------------*/
/* NOMBRE    : NS_INSASEGURADOSVIGENTES513*/
/* OBJETIVO  : OBTENER INFORMACI�N LOS ASEGURADOS VIGENTES DE TODAS LAS POLIZAS ACTIVAS A UNA FECHA DADA        */
/* PARAMETROS: 1 -  DFECHA_HASTA            : FECHA LIMITE DE EMISION D POLIZAS                                 */
/*             2 -  NCOD_REGIONALPOLIZA   	: COD RREGIONAL DONDE SE EMITI� LA POLIZA                           */
/*             3 -  NCOD_RAMO   	        : COD RAMO DE LA POLIZA                                         */
/*             4 -  NCOD_PRODUCTO   	    : COD PRODUCTO DE LA POLIZA                                         */
/*             5 -  NCOD_TIPOINTERMEDIARIO  : COD TIPO INTERMEDIARIO DE LA POLIZA                               */
/*             6 -  NCOD_INTERMEDIARIO   	: COD INTERMEDIARIO DE LA POLIZA                                    */
/* SOURCESAFE INFORMATION                                                                                       */
/*     $Author: NSB- GEORGE NOTO $                                                                                    */
/*     $Date: 11/03/26  $                                                                                       */
/*     $Revision:  $                                                                                            */

/*-------------------------------------------------------------------------------*/
   (SKEY                	            T_INTERFACE.SKEY%TYPE,
	NSHEET              	            MASTERSHEET.NSHEET%TYPE,
	NUSERCODE           	            MASTERSHEET.NUSERCODE%TYPE,
    DFECHA_HASTA	    		        DATE,
    NCOD_REGIONALPOLIZA    			    TABLE9.NOFFICE%TYPE,
    NCOD_RAMO                           POLICY.NBRANCH%TYPE,
    NCOD_PRODUCTO                       POLICY.NPRODUCT%TYPE,
    NCOD_TIPOINTERMEDIARIO     	        INTERM_TYP.NINTERTYP%TYPE,
    NCOD_INTERMEDIARIO	    	        INTERMEDIA.NINTERMED%TYPE,
	NERROR                              OUT T_ERR_INTERFACE.NERROR%TYPE,
    SERRORDESC                          OUT VARCHAR2 
	) AUTHID CURRENT_USER AS

BEGIN

   -- Borrar solo la ejecución sobre la misma llave; si no existe, limpiar tabla de reporte
   DELETE FROM TIMETMP.TMP_INT513 WHERE SKEY = NS_INSASEGURADOSVIGENTES513.SKEY;
   IF SQL%ROWCOUNT = 0 THEN
      DELETE FROM TIMETMP.TMP_INT513;
   END IF;
   --DELETE TRACE WHERE NUSERCODE = 15;
   COMMIT;

INSERT INTO TIMETMP.TMP_INT513
(
  SKEY,
  NCODRAMO,             ---  NBRANCH
  SCOD_TIPO_CERTIFICADO,      --   SCERTYPE
  NNRO_TOTAL_ASEGURADO,
  NNRO_TOTAL_ASEGURADOXCUENTA,
  NCOD_PRODUCTO,
  SPRODUCTO,    -- NPRODUCT
  SPLAN,
  STIPO_POLIZA,
  STIPO_FACT_COLECTIVO,	
  STIPO_DISTRIBUCION,	     
  NNRO_POLIZA,             --NPOLICY
  NCOD_MONEDA_POL,
  SMONEDA_POL,
  DFEC_EMISION_POL,
  DFEC_INIVIGENCIA_POL,
  DFEC_FINVIGENCIA_POL,
  NCOD_ESTADO_POL,
  SESTADO_POL,
  NCOD_REGIONAL_POL,
  SREGIONAL_POL,
  NCOD_TIPO_INTERMEDIARIO,		
  STIPO_INTERMEDIARIO,	
  NCOD_INTERMEDIARIO,		
  SINTERMEDIARIO,	
  NCAPITAL_ASEGURADO_MO,
  NCAPITAL_ASEGURADO_LO,
  NDEDUCIBLE_MO,
  NDEDUCIBLE_LO,  
  SAMBITO_GEOGRAFICO,
  STIPO_RED_MEDICA,  
  SCONTRATANTE,
  NNRO_CERTIFICADO,             
  NCOD_ASEGURADO  ,
  SNOMBRE_ASEG      ,
  SAPELLIDOS_ASEG ,
  SESTADO_ASEG ,
  SGENERO_ASEG ,  
  SRELACION_ASEG,
  STIPO_PERSONA_ASEG , 
  STIPO_DOCUMENTO_ASEG ,  
  SNRO_DOCUMENTO_ASEG ,
  SNRO_COMPLEMENTO_ASEG,
  DFEC_NAC_ASEG ,
  NEDAD_ASEG    ,  
  SCIUDAD_RESIDENCIA_ASEG,
  DFEC_INGRESO_ASEG,
  DFEC_EGRESO_ASEG,
  DFEC_ANTIGUEDAD_ASEG,  
  NCAPITAL_ANTIGUEDAD_ASEG,
  SCORREO_ASEG ,    
  SEXCLUSIONES_PARTICULARES,
  SOTRO_SEGURO,
  SCOB_MATERNIDAD,
  SCOB_PORC_AMBULATORIA,
  SCOB_PORC_HOSPITALARIA,
  SCOB_PORC_MED_AMBULATORIOS,
  SCOB_ADICIONAL_ODONTOLOGICA,
  SCOA_ODONTOLOGICO ,
  SCLINICA_ODONTOLOGICA ,
  SSEGURO_VIAJERO,
  SEMERGENCIA_MEDICA,
  SMUERTE_ACCIDENTAL,
  SSEPELIO,  
  DFECHAFIN_CREDENCIAL,
  SCONDICIONES_COASEGURO_CONSULTA ,  
  SOBSERVACIONES
)
    WITH cteCoberturas AS (
        -- CTE para detalles de cobertura, sin cambios
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
            MAX(CASE WHEN TLCOB.NCOVERGEN IN (92230) THEN 'SI' ELSE 'NO' END) AS Sepelio,
            MAX(NVL(BENEF.NDED_TYPE,0)) AS NDEDUCIBLE
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
    ),
    cteEmails AS (
        -- CTE para obtener el primer correo electr�nico por cliente y p�liza
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
    ),
    cteOtroSeguro AS (
        -- CTE para encontrar si un cliente tiene otras p�lizas activas
        SELECT
            RAUX.SCLIENT,
            PRODAUX.nproduct,
            'SI,' || PRODAUX.SDESCRIPT AS SDESCRIPT,
            ROW_NUMBER() OVER(PARTITION BY RAUX.SCLIENT, PRODAUX.nproduct ORDER BY PAUX.NPolicy) as rn
       FROM POLICY PAUX
       INNER JOIN CERTIFICAT CAUX ON PAUX.scertype= CAUX.scertype and PAUX.Nbranch= CAUX.NBranch
                           and PAUX.NProduct= CAUX.NProduct and PAUX.NPolicy = CAUX.NPolicy
       INNER JOIN ROLES RAUX ON CAUX.Scertype=RAUX.Scertype and CAUX.NBranch=RAUX.NBranch
                            and CAUX.Nproduct=RAUX.Nproduct and CAUX.NPolicy=RAUX.NPolicy
                            and CAUX.ncertif= RAUX.ncertif
                            AND RAUX.NROLE NOT IN (1,13,25,87)
       INNER JOIN prodmaster PRODAUX On PAUX.NBranch= PRODAUX.NBranch and PAUX.NProduct = PRODAUX.NProduct
       WHERE PAUX.SCERTYPE = '2'
       AND NS_INSASEGURADOSVIGENTES513.DFECHA_HASTA BETWEEN PAUX.DSTARTDATE AND PAUX.DEXPIRDAT
       AND (RAUX.DNULLDATE IS NULL OR RAUX.DNULLDATE < NS_INSASEGURADOSVIGENTES513.DFECHA_HASTA)
    )
    SELECT
        NS_INSASEGURADOSVIGENTES513.SKEY,
        VPOL.nbranch,
        vPol.SCERTYPE,
        COUNT(*) OVER () AS NroTotalAsegurado,
        COUNT(*) OVER (PARTITION BY vpol.npolicy) AS NroAseguradoPorCuenta,
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
        NVL(cert.NCAPITAL,0) As CapitalAseguradoMO,
        NVL(cert.NCAPITAL,0) * vpol.tc As CapitalAseguradoLO,
        NVL(cd.NDEDUCIBLE, 0) AS NDEDUCIBLE_MO,
        NVL(cd.NDEDUCIBLE, 0) * vpol.tc AS NDEDUCIBLE_LO,
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
                            and (rolAse.dnulldate is null or NS_INSASEGURADOSVIGENTES513.DFECHA_HASTA < rolAse.dnulldate)
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
    LEFT JOIN cteEmails tblCorreo ON tblCorreo.sclient = aseg.sclient AND tblCorreo.scertype = vpol.scertype AND tblCorreo.npolicy = vpol.npolicy AND tblCorreo.rn = 1
    LEFT JOIN cteDocCliente tblDocumento ON tblDocumento.sclient = rolAse.sclient AND tblDocumento.rn = 1
    LEFT JOIN cteOtroSeguro tblOtroSeguro ON tblOtroSeguro.SCLIENT = ASEG.SCLIENT AND tblOtroSeguro.nproduct <> vpol.nproduct AND tblOtroSeguro.rn = 1
    LEFT JOIN cteCoberturas cd ON cert.npolicy = cd.npolicy AND cert.scertype = cd.scertype AND cert.nbranch = cd.nbranch
        AND cert.nproduct = cd.nproduct AND cert.ncertif = cd.ncertif AND aseg.sclient = cd.sclient
    WHERE vPol.SCERTYPE = '2' 
    AND TRIM(UPPER(VPOL.ESTADOPOLIZA))= 'ACTIVA' 
    -- AND VPOL.NROPOLIZA in (1016,1152,1180)
    --parametros> 
    /* Fecha de emisión vs corte (manejo nativo DATE, evitar conversiones innecesarias) */
    AND vPol.FechaEmision <= NS_INSASEGURADOSVIGENTES513.DFECHA_HASTA
    AND VPol.CodRegionalPoliza = CASE WHEN NVL(NS_INSASEGURADOSVIGENTES513.NCOD_REGIONALPOLIZA,0)=0 
                                      THEN VPol.CodRegionalPoliza ELSE NS_INSASEGURADOSVIGENTES513.NCOD_REGIONALPOLIZA END                 
    AND vpol.codproducto = CASE WHEN NVL(NS_INSASEGURADOSVIGENTES513.NCOD_PRODUCTO,0)=0 
                                THEN VPol.codproducto ELSE NS_INSASEGURADOSVIGENTES513.NCOD_PRODUCTO END                         
    AND NVL(VPol.CodTipoIntermediario,0)=CASE WHEN NVL(NS_INSASEGURADOSVIGENTES513.NCOD_TIPOINTERMEDIARIO,0)=0 
                                              THEN VPol.CodTipoIntermediario ELSE NS_INSASEGURADOSVIGENTES513.NCOD_TIPOINTERMEDIARIO END 
    AND NVL(VPol.CodIntermediario,0) = CASE WHEN NVL(NS_INSASEGURADOSVIGENTES513.NCOD_INTERMEDIARIO,0)=0 
                                        THEN VPol.CodIntermediario  ELSE NS_INSASEGURADOSVIGENTES513.NCOD_INTERMEDIARIO END  ;                
  
 
        
COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NERROR := SQLCODE;
        SERRORDESC := SQLERRM;
        CRETRACE2('ERR TMP_INT513', 593, SERRORDESC);          
        RAISE;    
END NS_INSASEGURADOSVIGENTES513;