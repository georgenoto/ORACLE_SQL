CREATE OR REPLACE PROCEDURE INSUDB.NS_INSASEGURADOSTODOS512
/*-------------------------------------------------------------------------------*/
/* NOMBRE    : NS_INSASEGURADOSTODOS512*/
/* OBJETIVO  : OBTENER INFORMACIÓN LOS ASEGURADOS DE LAS POLIZAS                 */
/* PARAMETROS: 1 -  DINIDATE     : FECHA DE EMISION DESDE                     */
/*             2 -  DENDDATE   	: FECHA DE EMISION HASTA                     */
/*             3 -  NOFFICE   	: CODIGO DE REGIONAL DE LA POLIZA            */
/*-------------------------------------------------------------------------------*/
   (SKEY                	T_INTERFACE.SKEY%TYPE,
	NSHEET              	MASTERSHEET.NSHEET%TYPE,
	NUSERCODE           	MASTERSHEET.NUSERCODE%TYPE,
    DINIDATE	    		DATE,
    DENDDATE	    		DATE,
    NOFFICE     			TABLE9.NOFFICE%TYPE,
	NERROR                  OUT T_ERR_INTERFACE.NERROR%TYPE,
    SERRORDESC              OUT VARCHAR2 
	) AUTHID CURRENT_USER AS

BEGIN

   DELETE  FROM TMP_INT512;
    --WHERE SKEY = NS_INSASEGURADOSTODOS512.SKEY;
     
    DELETE TRACE WHERE NUSERCODE = 15;
    COMMIT;


    INSERT INTO TMP_INT512 (
          SKEY,
          SCERTYPE,
          NBRANCH,     --- COD. RAMO
          NPRODUCT,    --- COD. PRODUCTO
          NPOLICY,    --- NRO. POLIZA
          SDESPRODUCT, --- DESC. PRODUCTO
          SCURRENCY, -- MONEDA POLIZA
          STYPPOLICY, -- TIPO POLIZA
          SCOLINVOT,	--- TIPO FACTURA COLECTIVO
          STYPDIS_PAYPERCEN,	     --- TIPO DISTRIBUCION   
          SGEOGRAPHAREA,    ---AMBITO GEOGGRAFICO
          SATTENSYSTEM,    ---SISTEMA ATENCION
          NSTATUSVA,        --- COD ESTADO POIZA
          SSTATUSVA,       --- ESTADO POLIZA
          DSTARTDATE,               --- INICIO DE VIGENCIA
          DEXPIRDAT,               --- TERMINO DE VIGENCIA  
          SCLIENT_CONTRACTOR, --- COD. CONTRATANTE
          SCLIENAME_CONTRACTOR, --- NOMBRE CONTRATANTE
          DISSUEDAT,               --- FECHA EMISION
          NOFFICE,     --- COD. REGIONAL POLIZA
          SDESOFFICE, --- DESC. REGIONAL POLIZA  
          NCERTIF,             --- NRO. DE CERTIFICADO
          SCLIENT_INSURED, --- COD. ASEGURADO
          SFIRSTNAME_INSURED, --- NOMBRE ASEGURADO
          SLASTNAME_INSURED, --- PRIMER APELLIDO ASEGURADO
          SLASTNAME2_INSURED, --- SEGUNDO APELLIDO ASEGURADO
          SCLIENTNAME_INSURED, --- NOMBRE COMPLETO ASEGURADO
          SSEXCLIENT_INSURED, --- SEXO DEL ASEGURADO
          SROLE_INSURED, --- ROL DEL ASEGURADO
          DBIRTHDATE,               --- FECHA DE NACIMIENTO
          NAGE,           --- EDAD ASEGURADO
          SPERSONTYPE, --- TIPO DE PERSONA
          NTYPCLIENTDOC,         --- COD TIPO DE DOCUMENTO
          SCLINUMDOC,       --- NRO DE DOCUMENTO
          SIDCOMPLE,       --- COMPLEMENTO
          SSTATE_INSURED,       --- ESTADO ASEGURADO
          SCITY_RESIDENCE,       --- CIUDAD DE RESIDENCIA
          SCOUNTRY_RESIDENCE,       --- PAIS DE RESIDENCIA
          DEFFECDATE,                   --- FECHA INGRESO ASEGURADO
          DNULLDATE,                   --- FECHA EGRESO ASEGURADO
          SMAIL_INSURED,     --- EMAIL ASEGURADO
          DCREATE_INSURED,                   --- FECHA CREACION USUARIO
          SUSERNAME_CREATEINSURED,     --- USUARIO QUE CREO AL ASEGURADO
          DUPDATE_INSURED,                   --- FECHA CREACION USUARIO
          SUSERNAME_UPDATEINSURED,     --- USUARIO QUE MODIFICO AL ASEGURADO
          NINTERTYP,		--- COD. TIPO INTERMEDIARIO
          SDESINTERTYP,	--- DESC. TIPO INTERMEDIARIO
          NINTERMED,		--- COD.  INTERMEDIARIO
          SDESINTERMED,--- NOMBRE INTERMEDIARIO
          SSTATUSVA_CERTIF  --- ESTADO DEL CERTIFICADO
        )
        select  
              NS_INSASEGURADOSTODOS512.SKEY
            , VPOL.SCertype
            , VPOL.nbranch
            , VPOL.nproduct
            , VPOL.npolicy                       
            , vpol.producto            
            , vpol.MonedaPoliza
            , vpol.tipopoliza As TipoPoliza 
            , vpol.TipoFacturaColectivo
            , vpol.TipoDistribucion
            --, Vpol.FrecuenciaPago
            , TRIM(ambgeo.sdescript) As AmbitoGeografico
            , TRIM(sisate.sdescript) As SistemaAtencion           
            , vpol.codestadopoliza
            ,(CASE WHEN TO_CHAR( NVL(vpol.finvigenciapoliza, SYSDATE), 'YYYYMMDD') < TO_CHAR(NS_INSASEGURADOSTODOS512.DENDDATE , 'YYYYMMDD') 
                THEN 'Vencida' 
                ELSE vpol.estadopoliza  
               END) as estadopoliza
            --, vpol.estadopoliza
            , vpol.iniciovigenciapoliza As InicioVigenciaPoliza
            , vpol.finvigenciapoliza As FinVigenciaPoliza
            , vpol.codContratante
            , vpol.contratante
            , vpol.fechaemision
            , vpol.CodRegionalPoliza
            , vpol.RegionalPoliza
            , rolase.ncertif AS NroCertificado
            , aseg.sclient CodigoAsegurado
            , INITCAP(LOWER(RTRIM(aseg.sfirstname))) AS NombreAsegurado
            , INITCAP(LOWER(RTRIM(aseg.slastname ))) As PrimerApellido
            , INITCAP(LOWER(RTRIM(aseg.slastname2 ))) AS SegundoApellido
            , INITCAP(LOWER(RTRIM(aseg.sCliename))) AS Asegurado
            , TRIM(sexo.sdescript) As Genero
            , TRIM(crol.sdescript) As Relacion   
            , rolAse.dbirthdate As FechaNacimiento
            , trunc(months_between(sysdate,rolAse.dbirthdate)/12) Edad
            , TPer.sdescript TipoPersona    
            , tblDocumento.codtipodocumento
            , tblDocumento.nrodocumento
            , tblDocumento.Complemento  
            ,(CASE WHEN TO_CHAR( NVL(vpol.finvigenciapoliza, SYSDATE), 'YYYYMMDD') < TO_CHAR(NS_INSASEGURADOSTODOS512.DENDDATE , 'YYYYMMDD') 
                THEN 'Vencida'
                ELSE    CASE WHEN rolAse.nstatusrol=1 
                           THEN CASE WHEN rolAse.Dnulldate is null THEN TRIM(ease.sdescript) ELSE 'Excluido' END  
                           ELSE TRIM(ease.sdescript) END 
               END)   as EstadoAsegurado
            , TRIM(cresi.sdescript) as CiudadResidencia
            , TRIM(pres.sdescript) as PaisResidencia
            , rolAse.deffecdate as FechaIngreso
            , rolAse.dnulldate as FechaEgreso  
            , tblCorreo.EmailAsegurado
            , aseg.dinpdate As FechaCreacionUsuario
            , clicre.scliename As UsuarioCreacion
            , aseg.dcompdate As FechaModificacion
            , clicre.scliename As UsuarioModificacion
            , vpol.codtipointermediario
            , vpol.TipoIntermediario
            , vpol.codintermediario
            , vpol.intermediario
            , ECert.sdescript As EstadoCertificado  
                           
            FROM NS_View_DatosGeneralesPoliza vpol
            INNER JOIN Certificat cert On vpol.scertype= Cert.scertype and vpol.Nbranch= Cert.NBranch 
                                   and vpol.NProduct= Cert.NProduct and vpol.NPolicy = Cert.NPolicy       
            INNER JOIN ROLES rolAse ON  Cert.Scertype=rolAse.Scertype and Cert.NBranch=rolAse.NBranch 
                                        and Cert.Nproduct=rolAse.Nproduct and Cert.NPolicy=rolAse.NPolicy
                                        and cert.ncertif= rolAse.ncertif
                                        AND rolAse.NROLE      NOT IN (1,13,25,87,91)--AND rolAse.NROLE       IN  (2, 23, 22, 21, 24, 27, 60, 30, 29, 28)
            INNER JOIN Client aseg on rolAse.sclient = aseg.sclient
            OUTER APPLY (
                select adrs.se_mail EmailAsegurado
                from ADDRESS adrs 
                WHERE adrs.sclient= aseg.sclient and adrs.scertype= vpol.scertype and adrs.npolicy= vpol.npolicy
                and adrs.dnulldate is null
                FETCH FIRST 1 ROW ONLY
            )tblCorreo
            INNER JOIN MODUL_INSURED planaseg On  Cert.scertype= planaseg.scertype and Cert.Nbranch= planaseg.NBranch 
                                   and Cert.NProduct= planaseg.NProduct and Cert.NPolicy = planaseg.NPolicy
                                   and cert.ncertif= planaseg.ncertif
                                   and aseg.sclient = planaseg.sclient 
            INNER JOIN MODULES mdlo  ON planaseg.scertype= mdlo.scertype and planaseg.Nbranch= mdlo.NBranch 
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
            LEFT JOIN TABLE181 ECert On cert.SSTATUSVA = ECert.SSTATUSVA
            CROSS APPLY(
                select clidoc.ntypclientdoc codTipoDocumento, clidoc.sclinumdocu nroDocumento, tdoc.sshort_des tipoDocumentoCorto
                , clidoc.sidcompl Complemento
                from CLIDOCUMENTS cliDoc 
                inner join FORMATVALUES tdoc on clidoc.ntypclientdoc = tdoc.ntypclientdoc
                where cliDoc.sclient=rolAse.sclient
                FETCH FIRST 1 ROWS ONLY
            ) tblDocumento
        
            LEFT JOIN USERS usrCre ON aseg.NUSERCODE= usrCre.NUSERCODE
            LEFT JOIN CLIENT cliCre On usrCre.SClient= cliCre.SClient  
            
            --LEFT JOIN USERS usrMod ON rolAse.NUSERCODE= usrMod.NUSERCODE
            --LEFT JOIN CLIENT cliMod On usrMod.SClient= cliMod.SClient  
                        
        WHERE    vPol.SCERTYPE =   '2'  
        AND CERT.SSTATUSVA NOT IN (2,3,7,8) -- SE QUITAR LOS CERTIFICADOS QUE NO ESTAN ACTIVOS 
        --AND VPOL.NROPOLIZA in (1054,1016)
        --parametros>                              
        AND TO_CHAR(vpol.fechaemision , 'YYYYMMDD') BETWEEN  TO_CHAR(NS_INSASEGURADOSTODOS512.DINIDATE , 'YYYYMMDD')  AND TO_CHAR(NS_INSASEGURADOSTODOS512.DENDDATE, 'YYYYMMDD') 
        --AND TO_DATE(TO_CHAR(vpol.fechaemision, 'DD-MM-YYYY'))  BETWEEN NS_INSASEGURADOSTODOS512.DINIDATE AND NS_INSASEGURADOSTODOS512.DENDDATE 
        AND vpol.CodRegionalPoliza = CASE WHEN NVL(NS_INSASEGURADOSTODOS512.NOFFICE,0)=0 THEN vpol.CodRegionalPoliza ELSE NS_INSASEGURADOSTODOS512.NOFFICE END;
           


COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NERROR := SQLCODE;
        SERRORDESC := SQLERRM;
        CRETRACE2('ERR TMP_INT512', 593, SERRORDESC);  
        
        RAISE;    
END NS_INSASEGURADOSTODOS512;