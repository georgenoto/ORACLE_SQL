create or replace PACKAGE BODY          "PKG_REPPROPFULLCAR" IS

	PROCEDURE Getaddress (p_nRecowner   ADDRESS.nRecowner%TYPE
	                     ,p_sKeyaddress ADDRESS.sKeyaddress%TYPE
	                     ,io_cursor OUT t_cursor)
	IS
	BEGIN
		OPEN io_cursor FOR
			SELECT AD.nZip_code  AS "CodPostal"
			,      INITCAP(AD.sStreet)     AS "Direccion"
			,      AD.nFloor      AS "Piso"
			,      AD.sDepartment AS "Depto"
			,      INITCAP(AD.sPopulation) AS "VillaPob"
			,		   INITCAP(MU.sDescript)   AS "Comuna"
			,		   INITCAP(TL.sDescript)   AS "Ciudad"
			,		   TO_CHAR(AD.nProvince)   AS "Region"
		  ,      Getareacode(AD.nRecowner,AD.sKeyaddress,AD.dEffecdate,4) AS "CodAreaPart"
			,      Getphones(AD.nRecowner,AD.sKeyaddress,AD.dEffecdate,4) AS "FonoPart"
		  ,      Getareacode(AD.nRecowner,AD.sKeyaddress,AD.dEffecdate,1) AS "CodAreaCom"
			,      Getphones(AD.nRecowner,AD.sKeyaddress,AD.dEffecdate,1) AS "FonoCom"
		  ,      Getareacode(AD.nRecowner,AD.sKeyaddress,AD.dEffecdate,3) AS "CodAreaFax"
			,      Getphones(AD.nRecowner,AD.sKeyaddress,AD.dEffecdate,3) AS "Fax"
			,		   LOWER(AD.se_mail)     AS "E-Mail"
			FROM   ADDRESS AD
			,		   MUNICIPALITY MU
			,		   TAB_LOCAT TL
			WHERE	 AD.nRecowner	= p_nRecowner
			AND		 AD.sKeyaddress	= RPAD(p_sKeyaddress,50)
			AND		 AD.dEffecdate  	<= SYSDATE
			AND   (AD.dNulldate   	IS NULL OR AD.dNulldate >= SYSDATE)
			AND		 AD.nMunicipality = MU.nMunicipality
			AND		 MU.nlocal		 = TL.nLocal;

	END Getaddress;

	PROCEDURE Getclienterol (p_sCertype ROLES.sCertype%TYPE
	                        ,p_nBranch  ROLES.nBranch%TYPE
	                        ,p_nProduct ROLES.nProduct%TYPE
											    ,p_nPolicy  ROLES.nPolicy%TYPE
											    ,p_nCertif  ROLES.nCertif%TYPE
											    ,p_nRole    ROLES.nRole%TYPE
	                        ,io_cursor OUT t_cursor)
	IS
	BEGIN
		OPEN io_cursor FOR
			SELECT LTRIM(RTRIM(TO_CHAR(TO_NUMBER(CL.sClient),'99G999G999')))||'-'||sDigit AS "Rut"
			,      RTRIM(CL.sClient) AS "CodCliente"
			,      INITCAP(LOWER(RTRIM(sFirstname))) AS "Nombre"
			,      INITCAP(LOWER(RTRIM(sLastname)))  AS "ApellPaterno"
			,      INITCAP(LOWER(RTRIM(sLastname2))) AS "ApellMaterno"
			,      INITCAP(LOWER(RTRIM(sCliename))) AS "ApellMaterno"
	    ,      DECODE(CL.sSexClien,'1','F','2','M','')  AS "Sexo"
			,      Getphones (2,'2'||CL.sClient,SYSDATE,4) AS "Fono"
			FROM   ROLES RO
			,      CLIENT CL
			WHERE  sCertype    = p_sCertype
			AND    nBranch     = p_nBranch
			AND    nProduct    = p_nProduct
			AND    nPolicy     = p_nPolicy
			AND    nCertif     = p_nCertif
			AND    nRole       = p_nRole
			AND    dEffecdate <= SYSDATE
			AND   (dNulldate  IS NULL OR dNulldate >= SYSDATE)
			AND    CL.sClient  = RO.sClient;

	END Getclienterol;
  PROCEDURE Getcolectivo (p_sCertype IN POLICY.sCertype    %TYPE
                       ,p_nBranch  IN POLICY.nBranch     %TYPE
                       ,p_nProduct IN POLICY.nProduct    %TYPE
                       ,p_nPolicy  IN POLICY.nPolicy     %TYPE
                       ,io_cursor  OUT t_cursor)
	AS
	BEGIN
		 OPEN io_cursor FOR
				SELECT AG.ncod_agree AS "CodConvenio"
	      ,      LTRIM(TO_CHAR(TO_NUMBER(RTRIM(CL.sClient)),'99G999G999'))||'-'||sDigit AS "RutCliente"
				,      CL.scliename AS "NombreCliente"
				FROM   POLICY PO
				,      CLIENT CL
				,      AGREEMENT AG
				WHERE	 PO.scertype   = p_sCertype
				AND 	 PO.nbranch    = p_nBranch
				AND    PO.nproduct   = p_nProduct
				AND  	 PO.npolicy    = p_nPolicy
				AND    AG.ncod_agree = PO.ncod_agree
				AND    AG.sClient    = CL.sClient
				AND    AG.ntype_rec  = 8;

	END Getcolectivo;
	PROCEDURE Getcontratante (p_sCertype IN ROLES.sCertype%TYPE
	                         ,p_nBranch  IN ROLES.nBranch%TYPE
	                         ,p_nProduct IN ROLES.nProduct%TYPE
	                         ,p_nPolicy  IN ROLES.nPolicy%TYPE
			 			               ,p_nCertif  IN ROLES.nCertif%TYPE
													 ,io_cursor  OUT t_cursor)
	IS
	BEGIN
		OPEN io_cursor FOR
			SELECT LTRIM(TO_CHAR(TO_NUMBER(RTRIM(CL.sClient)),'99G999G999'))||'-'||sDigit AS "Rut"
			,      RTRIM(CL.sClient)
			,      INITCAP(LOWER(RTRIM(sFirstname)))
			,      INITCAP(LOWER(RTRIM(sLastname)))
			,      INITCAP(LOWER(RTRIM(sLastname2)))
			,      INITCAP(LOWER(RTRIM(sCliename)))
	    ,      DECODE(CL.sSexClien,'1','F','2','M','')
			FROM   CERTIFICAT CE
			,      CLIENT CL
			WHERE  CE.sCertype = p_sCertype
			AND    CE.nBranch  = p_nBranch
			AND    CE.nProduct = p_nProduct
			AND    CE.nPolicy  = p_nPolicy
			AND    CE.nCertif  = p_nCertif
			AND    CL.sClient  = CE.sClient;

	END Getcontratante;
	PROCEDURE Getdatosauto (p_sCertype IN AUTO.sCertype%TYPE
	                       ,p_nProduct IN AUTO.nProduct%TYPE
											   ,p_nPolicy  IN AUTO.nPolicy%TYPE
											   ,p_nCertif  IN AUTO.nCertif%TYPE
	                       ,io_cursor  OUT t_cursor)
	IS
	BEGIN
		OPEN io_cursor FOR
			SELECT MV.sDescript AS "marca_veh_aseg"
			,      TA.sVehmodel	AS "mod_veh_aseg"
			,      AU.nYear		  AS "ano_fab_veh_aseg"
			,      AU.sRegist	  AS "pat_veh_aseg"
			,      AU.sMotor	  AS "motor_veh_aseg"
			,      TV.sDescript AS "tip_veh_aseg"
			,      AU.nUse		  AS "uso_veh_aseg"
			,      DECODE(AD.nIndAlarm,1,'SI',2,'NO','') AS "ind_alarma"
			FROM   AUTO AU
			,	     TAB_AU_VEH TA
			,	     AUTO_DB AD
			,	     TABLE226 TV
			,	     TABLE7042 MV
			WHERE  AU.sCertype = p_sCertype
			AND    AU.nBranch  = 9
			AND    AU.nProduct = p_nProduct
			AND    AU.nPolicy  = p_nPolicy
			AND    AU.nCertif  = p_nCertif
			AND    AU.dEffecdate  	<= SYSDATE
			AND   (AU.dNulldate	IS NULL OR AU.dNulldate >= SYSDATE)
			AND	   TA.sVehcode    = AU.sVehcode
			AND	   AD.sLicense_ty = AU.sLicense_ty
			AND	   AD.sRegist     = AU.sRegist
			AND	   TV.nVehtype    = AU.nVehtype
			AND	   MV.nvehbrand   = TA.nVehbrand;

	END Getdatosauto;
	PROCEDURE Getdectos (p_sCertype IN POLICY.sCertype    %TYPE
	                    ,p_nBranch  IN POLICY.nBranch     %TYPE
	                    ,p_nProduct IN POLICY.nProduct    %TYPE
	                    ,p_nPolicy  IN POLICY.nPolicy     %TYPE
	                    ,io_cursor  OUT t_cursor)
	AS
		v_nDctoViaPagoUF NUMBER;
		v_nDctoViaPago   NUMBER;
		v_nDctoVolumenUF NUMBER;
		v_nDctoVolumen   NUMBER;
		v_nDctoConHabiUF NUMBER;
		v_nDctoConHabi   NUMBER;
	BEGIN
	  BEGIN
			SELECT NVL(SUM(dcto.nAmount),0)  AS "DctoReca_ViaPagoUF"
			,      NVL(SUM(dcto.nPercent),0) AS "DctoReca_ViaPago%"
			INTO   v_nDctoViaPagoUF
			,      v_nDctoViaPago
			FROM   CERTIFICAT CER
			,      DISC_XPREM DCTO
			,      DISCO_EXPR DX
			WHERE  cer.scertype		= p_scertype
			AND    cer.nbranch		= p_nbranch
			AND    cer.nproduct		= p_nproduct
			AND    cer.npolicy		= p_npolicy
			AND    cer.scertype		= dcto.scertype
			AND    cer.nbranch		= dcto.nbranch
			AND    cer.nproduct		= dcto.nproduct
			AND    cer.npolicy		= dcto.npolicy
			AND    cer.ncertif    = dcto.ncertif
			AND    dcto.deffecdate <= SYSDATE
			AND   (dcto.dnulldate IS NULL OR dcto.dnulldate >= SYSDATE)
			AND    dcto.nbranch    = dx.nbranch
			AND    dcto.nproduct   = dx.nproduct
			AND    dcto.ndisc_code IN  (3,100) -- Via de Pago.
			AND    dcto.ndisc_code = dx.ndisexprc
			AND    dx.deffecdate   <= SYSDATE
			AND   (dx.dnulldate 	IS NULL OR dx.dnulldate >= SYSDATE);
       	  EXCEPTION
	      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
            v_nDctoViaPagoUF := 0;
			v_nDctoViaPago   := 0;
	  END;

      BEGIN
			SELECT NVL(SUM(dcto.nAmount),0)  AS "DctoReca_VolumenUF"
			,      NVL(SUM(dcto.nPercent),0) AS "DctoReca_Volumen%"
			INTO   v_nDctoVolumenUF
			,      v_nDctoVolumen
			FROM   CERTIFICAT CER
			,      DISC_XPREM DCTO
			,      DISCO_EXPR DX
			WHERE  cer.scertype		= p_scertype
			AND    cer.nbranch		= p_nbranch
			AND    cer.nproduct		= p_nproduct
			AND    cer.npolicy		= p_npolicy
			AND    cer.scertype		= dcto.scertype
			AND    cer.nbranch		= dcto.nbranch
			AND    cer.nproduct		= dcto.nproduct
			AND    cer.npolicy		= dcto.npolicy
			AND    cer.ncertif        = dcto.ncertif
			AND    dcto.deffecdate   <= SYSDATE
			AND   (dcto.dnulldate IS NULL OR dcto.dnulldate >= SYSDATE)
			AND    dcto.nbranch    = dx.nbranch
			AND    dcto.nproduct   = dx.nproduct
			AND    dcto.ndisc_code = 2  --Volumen.
			AND    dcto.ndisc_code = dx.ndisexprc
			AND    dx.deffecdate   <= SYSDATE
			AND   (dx.dnulldate 	IS NULL OR dx.dnulldate >= SYSDATE);
       	  EXCEPTION
	      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
            v_nDctoVolumenUF := 0;
			v_nDctoVolumen   := 0;
	  END;

      BEGIN
			SELECT NVL(SUM(dcto.nAmount),0) AS "DctoReca_ConHabitUF"
			,      NVL(SUM(dcto.nPercent),0) AS "DctoReca_ConHabit%"
			INTO   v_nDctoConHabiUF
			,      v_nDctoConHabi
			FROM   CERTIFICAT CER
			,      DISC_XPREM DCTO
			,      DISCO_EXPR DX
			WHERE  cer.scertype		= p_scertype
			AND    cer.nbranch		= p_nbranch
			AND    cer.nproduct		= p_nproduct
			AND    cer.npolicy		= p_npolicy
			AND    cer.scertype		= dcto.scertype
			AND    cer.nbranch		= dcto.nbranch
			AND    cer.nproduct		= dcto.nproduct
			AND    cer.npolicy		= dcto.npolicy
			AND    cer.ncertif        = dcto.ncertif
			AND    dcto.deffecdate   <= SYSDATE
			AND   (dcto.dnulldate IS NULL OR dcto.dnulldate >= SYSDATE)
			AND    dcto.nbranch    = dx.nbranch
			AND    dcto.nproduct   = dx.nproduct
			AND    dcto.ndisc_code IN (5,10,11,12) --Conductor Habitual.
			AND    dcto.ndisc_code = dx.ndisexprc
			AND    dx.deffecdate   <= SYSDATE
			AND   (dx.dnulldate 	IS NULL OR dx.dnulldate >= SYSDATE)
			ORDER BY dcto.ndisc_code;
	      EXCEPTION
	      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
            v_nDctoVolumenUF := 0;
			v_nDctoVolumen   := 0;
	  END;

	  OPEN io_cursor FOR
		SELECT v_nDctoViaPagoUF
			,  v_nDctoViaPago
			,  v_nDctoVolumenUF
			,  v_nDctoVolumen
			,  v_nDctoConHabiUF
			,  v_nDctoConHabi
		FROM Dual;

	END Getdectos;
	PROCEDURE Getpagopropuesta (p_sCertype IN AUTO.sCertype %TYPE
	                           ,p_nBranch  IN AUTO.nBranch  %TYPE
	                           ,p_nProduct IN AUTO.nProduct %TYPE
	                           ,p_nPolicy  IN AUTO.nPolicy  %TYPE
	                           ,io_cursor  OUT t_cursor)
	IS
		v_CosInspecc    NUMBER; -- No se sabe de donde sacar este valor.
		v_ValorCuotaUF  NUMBER;
		v_PrimaAfectaUF NUMBER;
    v_PrimaNetaUF   NUMBER;
		v_PrimaTotal    NUMBER;
	 	v_Iva           NUMBER;
		vDefFecdate     NUMBER;
	BEGIN
	  BEGIN
			SELECT MAX(TO_NUMBER(TO_CHAR(dEffecdate,'J')))
			INTO   vDefFecdate
			FROM   PREMIUM
			WHERE  sCertype = p_sCertype
			AND	   nBranch  = p_nBranch
			AND    nProduct = p_nProduct
			AND    nPolicy  = p_nPolicy;

			SELECT NVL(PRE.nPremium,0) AS PrimaAfecta
			,      NVL(PRE.nPremiumn,0) AS PrimaNeta
			,      NVL(PRE.nTaxamou,0)   AS mto_iva
			INTO   v_PrimaAfectaUF
			,      v_PrimaNetaUF
			,      v_Iva
			FROM   PREMIUM PRE
			WHERE  PRE.sCertype = p_sCertype
			AND		 PRE.nBranch  = p_nBranch
			AND		 PRE.nProduct = p_nProduct
			AND		 PRE.nPolicy  = p_nPolicy
			AND		 TO_NUMBER(TO_CHAR(PRE.dEffecdate,'j')) = vDeffecdate;
		EXCEPTION
		  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
			     NULL;
			WHEN OTHERS THEN
			     NULL;
		END;

		OPEN io_cursor FOR
			SELECT NVL(fin.namount,0) AS "DepositoUF"
			,      NVL(fin.namount,0) + NVL(v_CosInspecc,0) AS "TotPagoPropUF"
			,      NVL(EX.nExchange,0) AS "ValorUF"
			,      (NVL(fin.namount,0) + NVL(v_CosInspecc,0)) * NVL(ex.nexchange,0) AS "TotPagoProp$"
			,      Pkg_Reppropfullcar.Getprimeracuota (p_sCertype,p_nBranch,p_nProduct,p_nPolicy) AS "ValorCuotaUF"
			,      v_PrimaAfectaUF
			,      v_PrimaNetaUF
		  ,      v_Iva
			FROM   FINANC_DRA FIN
			,      COLFORMREF CO
			,      PREMIUM PRE
		  ,      EXCHANGE EX
			WHERE	 pre.scertype	  = p_sCertype
			AND 	 pre.nbranch	  = p_nBranch
			AND    pre.nproduct	  = p_nProduct
			AND  	 pre.npolicy   	= p_nPolicy
			AND  	 fin.ncontrat   = pre.ncontrat
			AND    fin.ndraft     = 0
			AND    co.nbordereaux = fin.nbordereaux
			AND    ex.ncurrency   = pre.ncurrency
			AND    ex.deffecdate  = dvaluedate;

	END Getpagopropuesta;
	PROCEDURE Getplanpago (p_sCertype IN POLICY.sCertype%TYPE
	                      ,p_nBranch  IN POLICY.nBranch%TYPE
	                      ,p_nProduct IN POLICY.nProduct%TYPE
	                      ,p_nPolicy  IN POLICY.nPolicy%TYPE
	                      ,p_nCertif  IN CERTIFICAT.nCertif%TYPE
	                      ,io_cursor  OUT t_cursor)
	AS
	BEGIN

		OPEN io_cursor FOR
			SELECT	T5.sDescript AS "ViaPago"
			,       T3.sDescript AS "FormaPago"
			,	      DI.sBankauth AS "NumMandato"
			,       T7.sDescript AS "NomBanco"
			,       DECODE(DI.sTyp_dirdeb,1,DI.sAccount,2,DI.sCredi_card) AS "NumCtaCteTar"
			,       LTRIM(RTRIM(TO_CHAR(TO_NUMBER(CL.sClient),'99G999G999')))||'-'||CL.sDigit AS "RutCliCtaCte"
			,		    INITCAP(RTRIM(CL.sCliename)) AS "NomCliente"
			,       T1.sDescript AS "TipoTarjeta"
			FROM    CERTIFICAT CE
			,       DIR_DEBIT  DI
			,       CLIENT     CL
			,       TABLE7     T7
			,       TABLE36    T3
			,       TABLE5002  T5
			,       TABLE183   T1
			WHERE   CE.scertype  	  = p_scertype
			AND     CE.nbranch   	 	= p_nbranch
			AND     CE.nproduct  	 	= p_nproduct
			AND     CE.npolicy   	 	= p_npolicy
			AND     CE.ncertif   	 	= p_ncertif
			AND     DI.scertype     = CE.scertype
			AND     DI.nbranch	    = CE.nbranch
			AND     DI.nproduct     = CE.nproduct
			AND     DI.npolicy      = CE.npolicy
			AND     DI.ncertif      = CE.ncertif
			AND     DI.deffecdate  <= SYSDATE
			AND    (DI.dnulldate IS NULL OR DI.dnulldate  > SYSDATE)
			AND     DI.styp_dirdeb  IN ('1','2')
			AND     T7.nbank_code(+)   = DI.nbankext
			AND     T3.nPayfreq(+)     = CE.nPayfreq
			AND     T5.nWay_pay(+)     = CE.nWay_pay
			AND     T1.nCard_type(+)   = DI.ntyp_crecard
			AND     CL.sclient(+)      = DI.sclient;

	END Getplanpago;

	PROCEDURE GetAgente(p_sCertype POLICY.sCertype%TYPE
	                   ,p_nBranch  POLICY.nBranch%TYPE
	                   ,p_nProduct POLICY.nProduct%TYPE
	                   ,p_nPolicy  POLICY.nPolicy%TYPE
	                   ,io_cursor OUT t_cursor)
	IS
	BEGIN
	OPEN io_cursor FOR
		SELECT PO.nAgency
		,  		 T55.sDescript
		,      LTRIM(RTRIM(TO_CHAR(TO_NUMBER(CL.sClient),'99G999G999')))||'-'||CL.sDigit
		,      CL.sCliename
		FROM   POLICY PO,
				   CLIENT CL,
				   TABLE5555 T55,
				   INTERMEDIA IM
		WHERE  PO.sCertype	= p_sCertype
		AND		 PO.nBranch		= p_nBranch
		AND		 PO.nProduct	= p_nProduct
		AND		 PO.nPolicy  	= p_nPolicy
		AND   (PO.dNulldate IS NULL OR PO.dNulldate > SYSDATE)
		AND    PO.nIntermed	= IM.nIntermed
		AND    IM.sClient	  = CL.sClient
		AND		 PO.nAgency		= T55.nAgency;
	END;

	PROCEDURE GetVariosHA (p_sCertype ROLES.sCertype%TYPE
	                      ,p_nBranch  ROLES.nBranch%TYPE
	                      ,p_nProduct ROLES.nProduct%TYPE
											  ,p_nPolicy  ROLES.nPolicy%TYPE
											  ,p_nCertif  ROLES.nCertif%TYPE
	                      ,io_cursor  OUT t_cursor)
	IS
	BEGIN
	IF p_nBranch = 10 THEN
		OPEN io_cursor FOR
			SELECT PO.sStatus_pol
			,      T1.sDescript
			,      PM.nProduct
			,      PM.sShort_des
			,      NULL
			,      NULL
			FROM   POLICY PO
			,      PRODMASTER PM
			,      TABLE181 T1
			WHERE  PO.sCertype    = p_sCertype
			AND    PO.nBranch     = p_nBranch
			AND    PO.nProduct    = p_nProduct
			AND    PO.nPolicy     = p_nPolicy
			AND    PM.nBranch     = PO.nBranch
			AND    PM.nProduct    = PO.nProduct
			AND    T1.sStatusva   = PO.sStatus_pol;
	ELSIF p_nBranch = 9 THEN
		OPEN io_cursor FOR
			SELECT PO.sStatus_pol
			,      T1.sDescript
			,      PM.nProduct
			,      PM.sShort_des
			,      CL.dBirthdat
			,      CL.dDriverdat
			FROM   POLICY PO
			,      PRODMASTER PM
			,      TABLE181 T1
			,      ROLES RO
			,      CLIENT CL
			WHERE  PO.sCertype    = p_sCertype
			AND    PO.nBranch     = p_nBranch
			AND    PO.nProduct    = p_nProduct
			AND    PO.nPolicy     = p_nPolicy
			AND    PM.nBranch     = PO.nBranch
			AND    PM.nProduct    = PO.nProduct
			AND    T1.sStatusva   = PO.sStatus_pol
			AND    RO.sCertype    = p_sCertype
			AND    RO.nBranch     = p_nBranch
			AND    RO.nProduct    = p_nProduct
			AND    RO.nPolicy     = p_nPolicy
			AND    RO.nCertif     = p_nCertif
			AND    RO.nRole       = 4
			AND    RO.dEffecdate <= SYSDATE
			AND   (RO.dNulldate  IS NULL OR RO.dNulldate >= SYSDATE)
			AND    CL.sClient  = RO.sClient;
  END IF;

	END GetVariosHA;

	FUNCTION Getphones (p_nRecowner   PHONES.nrecowner   %TYPE
		                 ,p_sKeyaddress PHONES.skeyaddress %TYPE
		                 ,p_dEffecdate  PHONES.deffecdate  %TYPE
		                 ,p_nPhone_type PHONES.nphone_type %TYPE) RETURN VARCHAR2
	AS
	  v_Fono PHONES.sPhone%TYPE:='-';
	BEGIN

		SELECT /*+ INDEX ( PHONES XPKPHONES ) */
               LTRIM(RTRIM(sPhone))
		INTO   v_Fono
		FROM   PHONES
		WHERE  nRecowner    = p_nrecowner
		AND    sKeyaddress  = p_skeyaddress
		AND    nKeyphones   > 0
		AND    dEffecdate  <= p_deffecdate
		AND   (dnulldate  IS NULL OR dnulldate >= SYSDATE)
		AND   phones.nphone_type=p_nphone_type;

		RETURN(v_Fono);

	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
		     RETURN(v_Fono);
		WHEN TOO_MANY_ROWS THEN
		     RETURN(v_Fono);
		WHEN OTHERS THEN
		     RETURN(v_Fono);
	END Getphones;

	FUNCTION Getprimeracuota (p_sCertype CERTIFICAT.sCertype %TYPE
	                         ,p_nBranch  CERTIFICAT.nProduct %TYPE
	                         ,p_nProduct CERTIFICAT.nProduct %TYPE
	                         ,p_nPolicy  CERTIFICAT.nPolicy  %TYPE) RETURN NUMBER
	IS
	  vCuota NUMBER;
	BEGIN

		SELECT namount
		INTO   vCuota
		FROM	 PREMIUM PRE
		,      FINANC_DRA FIN
		WHERE	 PRE.sCertype	= p_sCertype
		AND 	 PRE.nBranch	= p_nBranch
		AND    PRE.nProduct	= p_nProduct
		AND  	 PRE.nPolicy	= p_nPolicy
		AND  	 FIN.nContrat = PRE.nContrat
		AND  	 FIN.ndraft = 1;

		RETURN (vCuota);
	EXCEPTION
	 	WHEN NO_DATA_FOUND THEN
				 RETURN(vCuota);
		WHEN OTHERS        THEN
				 RETURN(vCuota);
	END Getprimeracuota;

	FUNCTION Getareacode (p_nRecowner   PHONES.nrecowner   %TYPE
		                 ,p_sKeyaddress PHONES.skeyaddress %TYPE
		                 ,p_dEffecdate  PHONES.deffecdate  %TYPE
		                 ,p_nPhone_type PHONES.nphone_type %TYPE) RETURN NUMBER
	AS
	  v_CodArea PHONES.nArea_code%TYPE:=0;
	BEGIN

		SELECT /*+ INDEX ( PHONES XPKPHONES ) */
               nArea_code
		INTO   v_CodArea
		FROM   PHONES
		WHERE  nRecowner    = p_nrecowner
		AND    sKeyaddress  = p_skeyaddress
		AND    nKeyphones   > 0
		AND    dEffecdate  <= p_deffecdate
		AND   (dnulldate  IS NULL OR dnulldate >= SYSDATE)
		AND   phones.nphone_type=p_nphone_type;

		RETURN(v_CodArea);

	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
		     RETURN(v_CodArea);
		WHEN TOO_MANY_ROWS THEN
		     RETURN(v_CodArea);
		WHEN OTHERS THEN
		     RETURN(v_CodArea);
	END Getareacode;

	FUNCTION Getcuotas (p_sCertype IN POLICY.sCertype%TYPE
	                   ,p_nBranch  IN POLICY.nBranch%TYPE
	                   ,p_nProduct IN POLICY.nProduct%TYPE
	                   ,p_nPolicy  IN POLICY.nPolicy%TYPE) RETURN NUMBER
	IS
	  vCuotas NUMBER(10,2):=0;
	BEGIN
		SELECT MAX(NDRAFT)
		INTO   vcuotas
		FROM	 PREMIUM PRE
		,      FINANC_DRA FIN
		WHERE	 pre.scertype	= p_sCertype
		AND 	 pre.nbranch	= p_nBranch
		AND    pre.nproduct	= p_nProduct
		AND  	 pre.npolicy	= p_nPolicy
		AND  	 pre.ncontrat = fin.ncontrat
		AND  	 nstat_draft NOT IN (3,5);

		RETURN (vCuotas);
	EXCEPTION
	 	WHEN NO_DATA_FOUND THEN
				 RETURN(vCuotas);
		WHEN OTHERS        THEN
				 RETURN(vCuotas);
	END Getcuotas;

	FUNCTION Gettipomovto (p_sCertype IN POLICY.sCertype%TYPE
		                    ,p_nBranch  IN POLICY.nBranch%TYPE
		                    ,p_nProduct IN POLICY.nProduct%TYPE
		                    ,p_nPolicy  IN POLICY.nPolicy%TYPE
		                    ,p_nCertif  IN CERTIFICAT.nCertif%TYPE) RETURN VARCHAR
	IS
	  v_nMovement policy_his.nMovement%TYPE;
		v_DescTipoMovto VARCHAR2(50);
	BEGIN
		IF p_sCertype = '8' THEN
		  BEGIN
				SELECT MAX(nMovement)
				INTO   v_nMovement
				FROM   POLICY_HIS PH
				WHERE  PH.sCertype = p_sCertype
				AND    PH.nBranch  = p_nBranch
				AND    PH.nProduct = p_nProduct
				AND    PH.nPolicy  = p_nPolicy
				AND    PH.nCertif  = p_nCertif;

				SELECT TO_CHAR(T1.ntype_hist)||' - '||sshort_des
				INTO   v_DescTipoMovto
				FROM   POLICY_HIS PH
				,      TABLE165 T1
				WHERE  PH.sCertype = p_sCertype
				AND    PH.nBranch  = p_nBranch
				AND    PH.nProduct = p_nProduct
				AND    PH.nPolicy  = p_nPolicy
				AND    PH.nCertif  = p_nCertif
				AND    PH.nMovement = v_nMovement
				AND    T1.nType_hist = PH.nType_hist;
			EXCEPTION
			  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
				     NULL;
				WHEN OTHERS THEN
				     NULL;
			END;
		ELSE
			SELECT DECODE(p_sCertype,1,'1 - Prop.Suscripcion'
			                        ,2,'2 - Poliza'
															,3,'3 - Cotizacion'
															,4,'4 - Cot.Modificacion'
															,5,'5 - Cot.Renovacion'
															,6,'6 - Prop.Modificacion'
															,7,'7 - Prop.Renovacion')
			INTO   v_DescTipoMovto
			FROM   dual;
		END IF;

		RETURN (v_DescTipoMovto);
	END Gettipomovto;

END Pkg_Reppropfullcar;
