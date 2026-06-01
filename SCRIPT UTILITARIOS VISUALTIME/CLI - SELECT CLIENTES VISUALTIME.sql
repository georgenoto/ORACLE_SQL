select  
            
             aseg.sclient CodigoAsegurado
            , INITCAP(LOWER(RTRIM(aseg.sfirstname))) AS NombreAsegurado
            , INITCAP(LOWER(RTRIM(aseg.slastname ))) As PrimerApellido
            , INITCAP(LOWER(RTRIM(aseg.slastname2 ))) AS SegundoApellido
            , INITCAP(LOWER(RTRIM(aseg.sCliename))) AS Asegurado
            , TPer.sdescript TipoPersona    
            , tblDocumento.codtipodocumento
            , tblDocumento.tipoDocumentoCorto
            , tblDocumento.nrodocumento
            , tblDocumento.Complemento  
            , tblCorreo.EmailAsegurado
            , aseg.dinpdate As FechaCreacionUsuario
            , clicre.scliename As UsuarioCreacion
            , aseg.dcompdate As FechaModificacion
            , clicre.scliename As UsuarioModificacion
            
            FROM CLIENT aseg 
            OUTER APPLY (
                select adrs.se_mail EmailAsegurado
                from ADDRESS adrs 
                WHERE adrs.sclient= aseg.sclient 
                and adrs.dnulldate is null
                FETCH FIRST 1 ROW ONLY
            )tblCorreo

            LEFT JOIN table66 pres ON aseg.nresidencecountry= pres.ncountry
            LEFT JOIN Table5006 TPer On aseg.nperson_typ= tper.nperson_typ
            CROSS APPLY(
                select clidoc.ntypclientdoc codTipoDocumento, clidoc.sclinumdocu nroDocumento, tdoc.sshort_des tipoDocumentoCorto
                , clidoc.sidcompl Complemento
                from CLIDOCUMENTS cliDoc 
                inner join FORMATVALUES tdoc on clidoc.ntypclientdoc = tdoc.ntypclientdoc and cliDoc.NCLASSTYPDOC = tdoc.NCLASSTYPDOC
                where cliDoc.sclient=aseg.sclient
                FETCH FIRST 1 ROWS ONLY
            ) tblDocumento
        
            LEFT JOIN USERS usrCre ON aseg.NUSERCODE= usrCre.NUSERCODE
            LEFT JOIN CLIENT cliCre On usrCre.SClient= cliCre.SClient  
            
