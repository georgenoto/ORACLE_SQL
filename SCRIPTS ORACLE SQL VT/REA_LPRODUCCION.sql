create or replace PROCEDURE          "REA_LPRODUCCION" 
/*----------------------------------------------------------------------------------*/
/* NOMBRE     : REA_LPRODUCCION                                                     */
/* OBJETIVO   : MOSTRAR EL DETALLE DE LA PRODUCCIoN DE LA COMPA?iA TANTO            */
/*              PARA GENERALES COMO PARA VIDA                                       */
/* PARAMETROS : 1 - BLOCKDATAREA_LPRODUCCION : VARIABLE DE TIPO CURSOR QUE          */
/*                  CONTIENE LA INFORMACION QUE SERa RETORNADA AL REPORTE           */
/*              2 - P_COD_CIA : ES LA COMPANIA A LA QUE PERTENECE LA INFORMACION    */
/*                  QUE SERa LISTADA EN EL REPORTE.                                 */
/*              3 - P_AREA_SEGURO : ES EL aREA DE SEGUROS A LA QUE PERTENECE LA     */
/*                  INFORMACIoN QUE SERa LISTADA EN EL REPORTE                      */
/*              4 - P_PERIODO : FECHA DESDE LA CUaL SE TOMARa LA INFORMACIoN QUE    */
/*                  SE MOSTRARa EN EL REPORTE. DE FORMA PREDETERMINADA SE           */
/*                  COLOCARa EL PRIMER DiA DEL MES QUE TIENE LA FECHA DEL           */
/*                  COMPUTADOR AL MOMENTO DE LA EJECUCIoN DEL REPORTE. CABE         */
/*                  MENCIONAR QUE EL PERiODO CORRESPONDE AL MES COMPLETO DE         */
/*                  LA FECHA INGRESADA                                              */
/*                                                                                  */
/* AUTOR      : NELSON PADILLA MORENO                                               */
/* FECHA      : 15-07-2002                                                          */
/* REVISION   : 15-07-2002                                                          */
/*                                                                                  */
/*----------------------------------------------------------------------------------*/
    (BLOCKDATAREA_LPRODUCCION IN OUT PKG_LIBROS_TIMBRADOS.PKG_LPRODUCCION_CUR,
    P_COD_CIA       IN VARCHAR2,
    P_AREA_SEGURO   IN VARCHAR2,
    P_FECHA_DESDE   IN VARCHAR2,
    P_FECHA_HASTA   IN VARCHAR2) AUTHID CURRENT_USER IS

    L_PARAM            NUMBER := 1;

BEGIN
    IF (TRIM(P_COD_CIA    ) IS NOT NULL  AND
        TRIM(P_AREA_SEGURO) IS NOT NULL  AND
        TRIM(P_FECHA_DESDE) IS NOT NULL  AND
        TRIM(P_FECHA_HASTA) IS NOT NULL) THEN

       IF (TO_DATE(P_FECHA_DESDE,'DD/MM/RRRR')  <
		   TO_DATE(P_FECHA_HASTA,'DD/MM/RRRR')) THEN
             OPEN BLOCKDATAREA_LPRODUCCION  FOR
             SELECT NULL SKEY,
                    P_COD_CIA                          		   P_COD_CIA              ,        -- CODIGO DE LA EMPRESA
                    TO_CHAR(PRE.NINSUR_AREA)                   P_AREA_SEGURO          ,        -- AREA DE SEGURO
                    TO_DATE(P_FECHA_DESDE,'DD/MM/RRRR')        P_FECHA_DESDE          ,        -- FECHA DEL PERIODO DE GENERACION DEL REPORTE
                    TO_DATE(P_FECHA_HASTA,'DD/MM/RRRR')        P_FECHA_HASTA          ,        -- FECHA DEL PERIODO DE GENERACION DEL REPORTE
                    SUBSTR(TBL75.SSHORT_DES,1,30)              P_RAMO_FECU            ,   	   -- DESCRIPCION DEL RAMO FECU
                    SUBSTR(TBL10.SDESCRIPT,1,30)               P_RAMO_CIA             ,   	   -- RAMO DE LA CIA
                    TO_CHAR(PRODM.NPRODUCT)                    P_COD_PRODUCTO         ,   	   -- COD DEL PRODUCTO
                    SUBSTR(INITCAP(PRODM.SDESCRIPT),1,30)      P_PRODUCTO             ,   	   -- DESCRIPCION DEL PRODUCTO
                    TO_CHAR(PRE.NOFFICE)                       P_COD_OFICINA          ,   	   -- CODIGO DE LA OFICINA
                    SUBSTR(TBL9.SSHORT_DES,1,30)               P_OFICINA              ,   	   -- NOMBRE DE LA OFICINA
                    TO_CHAR(CERT.NPOLICY)                      P_NRO_POLIZA           ,   	   -- NUMERO DE LA POLIZA
                    TO_CHAR(CERT.NPROPONUM)                    P_NRO_PROPUESTA        ,   	   -- NUMERO DE LA PROPUESTA
                    CERT.DSTARTDATE                            P_VIG_DESDE            ,        -- FECHA DE VIGENCIA DESDE LA POLIZA
                    CERT.DEXPIRDAT                             P_VIG_HASTA            ,        -- FECHA DE VIGENCIA HASTA LA POLIZA
                    CERT.DDATE_ACCEPT                          P_FECHA_ACEPT          ,        -- FECHA DE ACEPTACION DE LA POLIZA
                    PRE.SCLIENT                                P_RUT_ASEGURADO        ,   	   -- RUT DEL ASEGURADO
                    SUBSTR(INITCAP(CLI.SCLIENAME),1,30)        P_NOM_ASEGURADO        ,   	   -- NOMBRE DEL ASEGURADO
                    INTER.SCLIENT                              P_RUT_AGENTE           ,   	   -- RUT AGENTE
                    SUBSTR(INITCAP(CLI_AGENTE.SCLIENAME),1,30) P_NOM_AGENTE           ,   	   -- NOMBRE AGENTE
                    TO_CHAR(PRE.NCURRENCY)                     P_COD_MONEDA           ,        -- CODIGO DE LA MONEDA
                    TRIM(TBL11.SSHORT_DES)                     P_GLOSA_MONEDA         ,        -- GLOSA CORTA MONEDA
					SUM(DECODE(DET. , '3', NVL(DET.NPREMIUM,0),0))       	           P_MONTO_IVA_MO,                -- MONTO IVA EN MONEDA DE ORIGEN
					SUM(DECODE(DET.STYPE_DETAI, '3', 0, NVL(DET.NPREMIUME,0)))   			   P_MONTO_PRIMA_EXENTA_MO,	    -- MTO PRIMA EXENTA EN MONEDA DE ORIGEN
					SUM(DECODE(DET.STYPE_DETAI, '3', 0, NVL(DET.NPREMIUMA,0)))   			   P_MONTO_PRIMA_NETA_MO,         -- MTO PRIMA NETA EN MONEDA DE ORIGEN
                    SUM(DET.NPREMIUM)                          P_MONTO_PRIMA_TOTAL_MO ,    	    -- MONTO PRIMA TOTAL EN MONEDA DE ORIGEN
                    SUM(DECODE(DET.STYPE_DETAI, '3', 0, NVL(DET.NPREMIUME * PRE.NEXCHANGE,0))) P_MONTO_PRIMA_EXENTA,	-- MONTO PRIMA EXENTA EN PESOS
                    SUM(DECODE(DET.STYPE_DETAI, '3', 0, NVL(DET.NPREMIUMA * PRE.NEXCHANGE,0))) P_MONTO_PRIMA_NETA,	-- MONTO PRIMA NETA EN PESOS
                    SUM(DECODE(DET.STYPE_DETAI, '3', NVL(DET.NPREMIUM * PRE.NEXCHANGE, 0),0))	   P_MONTO_IVA,          -- MONTO IVA EN PESOS
                    SUM((DET.NPREMIUM * PRE.NEXCHANGE))		   P_MONTO_PRIMA_TOTAL    ,        -- MONTO PRIMA TOTAL EN PESOS
                    SUM(PRE.NCOMAMOU)                          P_MONTO_COM_DEV_MO     ,        -- MONTO COMISION DEVENGADA EN MONEDA ORIGEN
                    SUM((PRE.NCOMAMOU * PRE.NEXCHANGE))		   P_MONTO_COM_DEV_PESOS  ,	       -- MONTO COMISION DEVENGADA EN PESOS
                    CERT.NCERTIF                               P_NRO_CERTIF,                   -- NUMERO DE CERTIFICADO
                    PRE.NRECEIPT,
                    PRE.NTRATYPEI,
                    REAGENERALPKG.REACODIGINTSH('TABLE24','NTRATYPEI',PRE.NTRATYPEI) STRATYPEI,
                    T2.NTYPE
               FROM PREMIUM      PRE       ,  PREMIUM_MO	T2,
			   		DETAIL_PRE    DET  ,
                    CERTIFICAT   CERT      ,  POLICY        POL  ,
                    CLIENT       CLI       ,  INTERMEDIA    INTER,
                    CLIENT       CLI_AGENTE,  PRODMASTER    PRODM,
                    TABLE11      TBL11     ,  TABLE9        TBL9 ,
                    TABLE10      TBL10     ,  TABLE75       TBL75
              WHERE PRE.SCERTYPE           =   '2'
                AND PRE.SSTATUSVA          NOT IN   ('2','3')
                AND PRE.NINSUR_AREA        =   TO_NUMBER(P_AREA_SEGURO)
                AND PRE.NBRANCH            >=  0
                AND PRE.NPRODUCT           >=  0
                AND PRE.NDIGIT             =   0
                AND PRE.NPAYNUMBE          >=  0
           		AND T2.SCERTYPE      	   =   PRE.SCERTYPE
           		AND T2.NBRANCH       	   =   PRE.NBRANCH
           		AND T2.NPRODUCT      	   =   PRE.NPRODUCT
           		AND T2.NRECEIPT      	   =   PRE.NRECEIPT
           		AND T2.NDIGIT        	   =   PRE.NDIGIT
           		AND T2.NPAYNUMBE     	   =   PRE.NPAYNUMBE
		   		AND T2.DLEDGERDAT 		   BETWEEN   TO_DATE(P_FECHA_DESDE,'DD-MM-RRRR') AND TO_DATE(P_FECHA_HASTA,'DD-MM-RRRR')
                AND DET.SCERTYPE           =   PRE.SCERTYPE
                AND DET.NBRANCH            =   PRE.NBRANCH
                AND DET.NPRODUCT           =   PRE.NPRODUCT
                AND DET.NRECEIPT           =   PRE.NRECEIPT
                AND DET.NDIGIT             =   PRE.NDIGIT
                AND DET.NPAYNUMBE          =   PRE.NPAYNUMBE
                AND TBL75.NBRANCH_LED      =   DET.NBRANCH_LED
                AND TBL11.NCODIGINT        =   PRE.NCURRENCY
                AND TBL9.NOFFICE           =   PRE.NOFFICE
                AND PRODM.NBRANCH          =   PRE.NBRANCH
                AND PRODM.NPRODUCT         =   PRE.NPRODUCT
                AND TBL10.NBRANCH          =   PRE.NBRANCH
                AND CERT.SCERTYPE          =   PRE.SCERTYPE
                AND CERT.NBRANCH           =   PRE.NBRANCH
                AND CERT.NPRODUCT          =   PRE.NPRODUCT
                AND CERT.NPOLICY           =   PRE.NPOLICY
                AND CERT.NCERTIF           =   PRE.NCERTIF
                AND POL.SCERTYPE           =   PRE.SCERTYPE
                AND POL.NBRANCH            =   PRE.NBRANCH
                AND POL.NPRODUCT           =   PRE.NPRODUCT
                AND POL.NPOLICY            =   PRE.NPOLICY
                AND CLI.SCLIENT            =   PRE.SCLIENT
                AND INTER.NINTERMED        =   POL.NINTERMED
                AND CLI_AGENTE.SCLIENT     =   INTER.SCLIENT
			  GROUP BY P_COD_CIA,  		     PRE.NINSUR_AREA, 		P_FECHA_DESDE,
                       P_FECHA_HASTA, 	     TBL75.SSHORT_DES, 		TBL10.SDESCRIPT,
                       PRODM.NPRODUCT, 	     PRODM.SDESCRIPT, 		PRE.NOFFICE,
                       TBL9.SSHORT_DES,      CERT.NPOLICY, 			CERT.NPROPONUM,
                       CERT.DSTARTDATE,      CERT.DEXPIRDAT, 		CERT.DDATE_ACCEPT,
                       PRE.SCLIENT, 	     CLI.SCLIENAME, 		INTER.SCLIENT,
                       CLI_AGENTE.SCLIENAME, PRE.NCURRENCY, 		TBL11.SSHORT_DES,
					   CERT.NCERTIF,         PRE.NRECEIPT,          PRE.NTRATYPEI,
                       REAGENERALPKG.REACODIGINTSH('TABLE24','NTRATYPEI',PRE.NTRATYPEI),
                       T2.NTYPE
;
       ELSE
          OPEN BLOCKDATAREA_LPRODUCCION  FOR
          SELECT NULL SKEY,
                 CARACTER P_COD_CIA,                -- CODIGO DE LA EMPRESA
                 CARACTER P_AREA_SEGURO,            -- AREA DE SEGURO
                 CARACTER P_GLOSA_CIA,              -- GLOSA DE LA EMPRESA
                 FECHA    P_PERIODO,                -- FECHA DEL PERIODO DE GENERACION DEL REPORTE
                 CARACTER P_RAMO_FECU,              -- DESCRIPCION DEL RAMO FECU
                 CARACTER P_RAMO_CIA,               -- RAMO DE LA CIA
                 CARACTER P_COD_PRODUCTO,           -- COD DEL PRODUCTO
                 CARACTER P_PRODUCTO,               -- DESCRIPCION DEL PRODUCTO
                 CARACTER P_COD_OFICINA,            -- CODIGO DE LA OFICINA
                 CARACTER P_OFICINA,                -- NOMBRE DE LA OFICINA
                 CARACTER P_NRO_POLIZA,             -- NUMERO DE LA POLIZA
                 CARACTER P_NRO_PROPUESTA,          -- NUMERO DE LA PROPUESTA
                 FECHA    P_VIG_DESDE,              -- FECHA DE VIGENCIA DESDE LA POLIZA
                 FECHA    P_VIG_HASTA,              -- FECHA DE VIGENCIA HASTA LA POLIZA
                 FECHA    P_FECHA_ACEPT,            -- FECHA DE ACEPTACION DE LA POLIZA
                 CARACTER P_RUT_ASEGURADO,          -- RUT DEL ASEGURADO
                 CARACTER P_NOM_ASEGURADO,          -- NOMBRE DEL ASEGURADO
                 CARACTER P_RUT_AGENTE,             -- RUT AGENTE
                 CARACTER P_NOM_AGENTE,             -- NOMBRE AGENTE
                 CARACTER P_COD_MONEDA,             -- CODIGO DE LA MONEDA
                 CARACTER P_GLOSA_MONEDA,           -- GLOSA CORTA MONEDA
                 NUMERO   P_MONTO_PRIMA_EXENTA_MO,  -- MTO PRIMA EXENTA EN MONEDA DE ORIGEN
                 NUMERO   P_MONTO_PRIMA_NETA_MO,    -- MTO PRIMA NETA EN MONEDA DE ORIGEN
                 NUMERO   P_MONTO_IVA_MO,           -- MONTO IVA EN MONEDA DE ORIGEN
                 NUMERO   P_MONTO_PRIMA_TOTAL_MO,   -- MONTO PRIMA TOTAL EN MONEDA DE ORIGEN
                 NUMERO   P_MONTO_PRIMA_EXENTA,     -- MONTO PRIMA EXENTA EN PESOS
                 NUMERO   P_MONTO_PRIMA_NETA,       -- MONTO PRIMA NETA EN PESOS
                 NUMERO   P_MONTO_IVA,              -- MONTO IVA EN PESOS
                 NUMERO   P_MONTO_PRIMA_TOTAL,      -- MONTO PRIMA TOTAL EN PESOS
                 NUMERO   P_MONTO_COM_DEV_MO,       -- MONTO COMISION DEVENGADA EN MONEDA ORIGEN
                 NUMERO   P_MONTO_COM_DEV_PESOS,    -- MONTO COMISION DEVENGADA EN PESOS
                 NUMERO   P_NRO_CERTIF,             -- NUMERO DE CERTIFICADO
                 NUMERO   NRECEIPT,
                 NUMERO   NTRATYPEI,
                 CARACTER STRATYPEI,
                 NUMERO   NTYPE
            FROM TAB_AUXILIAR;
	   END IF;
   ELSE
        OPEN BLOCKDATAREA_LPRODUCCION  FOR
        SELECT NULL SKEY,
               CARACTER P_COD_CIA,                -- CODIGO DE LA EMPRESA
               CARACTER P_AREA_SEGURO,            -- AREA DE SEGURO
               CARACTER P_GLOSA_CIA,              -- GLOSA DE LA EMPRESA
               FECHA    P_PERIODO,                -- FECHA DEL PERIODO DE GENERACION DEL REPORTE
               CARACTER P_RAMO_FECU,              -- DESCRIPCION DEL RAMO FECU
               CARACTER P_RAMO_CIA,               -- RAMO DE LA CIA
               CARACTER P_COD_PRODUCTO,           -- COD DEL PRODUCTO
               CARACTER P_PRODUCTO,               -- DESCRIPCION DEL PRODUCTO
               CARACTER P_COD_OFICINA,            -- CODIGO DE LA OFICINA
               CARACTER P_OFICINA,                -- NOMBRE DE LA OFICINA
               CARACTER P_NRO_POLIZA,             -- NUMERO DE LA POLIZA
               CARACTER P_NRO_PROPUESTA,          -- NUMERO DE LA PROPUESTA
               FECHA    P_VIG_DESDE,              -- FECHA DE VIGENCIA DESDE LA POLIZA
               FECHA    P_VIG_HASTA,              -- FECHA DE VIGENCIA HASTA LA POLIZA
               FECHA    P_FECHA_ACEPT,            -- FECHA DE ACEPTACION DE LA POLIZA
               CARACTER P_RUT_ASEGURADO,          -- RUT DEL ASEGURADO
               CARACTER P_NOM_ASEGURADO,          -- NOMBRE DEL ASEGURADO
               CARACTER P_RUT_AGENTE,             -- RUT AGENTE
               CARACTER P_NOM_AGENTE,             -- NOMBRE AGENTE
               CARACTER P_COD_MONEDA,             -- CODIGO DE LA MONEDA
               CARACTER P_GLOSA_MONEDA,           -- GLOSA CORTA MONEDA
               NUMERO   P_MONTO_PRIMA_EXENTA_MO,  -- MTO PRIMA EXENTA EN MONEDA DE ORIGEN
               NUMERO   P_MONTO_PRIMA_NETA_MO,    -- MTO PRIMA NETA EN MONEDA DE ORIGEN
               NUMERO   P_MONTO_IVA_MO,           -- MONTO IVA EN MONEDA DE ORIGEN
               NUMERO   P_MONTO_PRIMA_TOTAL_MO,   -- MONTO PRIMA TOTAL EN MONEDA DE ORIGEN
               NUMERO   P_MONTO_PRIMA_EXENTA,     -- MONTO PRIMA EXENTA EN PESOS
               NUMERO   P_MONTO_PRIMA_NETA,       -- MONTO PRIMA NETA EN PESOS
               NUMERO   P_MONTO_IVA,              -- MONTO IVA EN PESOS
               NUMERO   P_MONTO_PRIMA_TOTAL,      -- MONTO PRIMA TOTAL EN PESOS
               NUMERO   P_MONTO_COM_DEV_MO,       -- MONTO COMISION DEVENGADA EN MONEDA ORIGEN
               NUMERO   P_MONTO_COM_DEV_PESOS,     -- MONTO COMISION DEVENGADA EN PESOS
               NUMERO   P_NRO_CERTIF,              -- NUMERO DE CERTIFICADO
               NUMERO   NRECEIPT,
               NUMERO   NTRATYPEI,
               CARACTER STRATYPEI,
               NUMERO   NTYPE
          FROM TAB_AUXILIAR;
    END IF;

END REA_LPRODUCCION;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 