create or replace PROCEDURE "INSCALPREM_BAS_VUL" 
/*-------------------------------------------------------------------------------------*/
/* NOMBRE    : INSCALPREM_BAS_VUL                                                      */
/* OBJETIVO  : CALCULA  LA PRIMA MINIMA ADEUDADA PARA UNA PÓLIZA DEL PRODUCTO VUL       */
/* PARAMETROS: 1 - SCERTYPE    : TIPO DE REGISTRO                                      */
/*             2 - NBRANCH     : CODIGO DEL RAMO COMERCIAL.                            */
/*             3 - NPRODUCT    : CODIGO DEL PRODUCTO.                                  */
/*             4 - NPOLICY     : NUMERO QUE IDENTIFICA LA POLIZA                       */
/*             5 - NCERTIF     : NUMERO DEL CERTIFICADO                                */
/*             6 - DEFFECDATE  : FECHA DE EFECTO DEL REGISTRO.                         */
/*             7 - SYEAR       : INDICA SI SE REQUIERE LA PRIMA BÁSICA ANUAL 1-SI, 2-NO*/
/*             8 - NPAYFREQ    : FRECUANCIA DE PAGO, SI SYEAR = 2 SE CALCULA PRIMA     */
/*                               BÁSICA SEGÚN FRECIENCIA DE PAGO                       */
/*             9 - NROU_SURR_LIFE: SI ES LLAMADO DESDE LA RUTINA DE RESCATE            */
/*            10 - NOPTRECAMOUNT: SI TIENE EL VALOR                                    */
/*                                0 - SOLO PRIMA NETA (COVER)                          */
/*                                1 - PRIMA NETA + RECARGO 2  (COVER)                  */
/*                                2 - SOLO RECARGO  (COVER)                            */
/*                                3 - CALCULA RECARGO SEGÚN PRIMA BÁSICA ABONADA PUI   */
/*                                4 - PRIMA BASICA DE FALLECIMIENTO                    */
/*                                5 - PRIMA BASICAS ACUMULADAS (PREMPAYED_POL)         */
/*            11 - NOPTION_EJEC : OPCIÓN DE EJECUCIÓN 3 - ILUSTRACIÓN                  */
/*                                                                                     */
/*  SOURCESAFE INFORMATION:                                                            */
/*     $Author:: Clobos         $                                                      */
/*     $Date:: 13/06/06 10:35a  $                                                      */
/*     $Revision:: 6            $                                                      */
/*-------------------------------------------------------------------------------------*/
    (SCERTYPE        COVER.SCERTYPE%TYPE,
     NBRANCH         COVER.NBRANCH%TYPE,
     NPRODUCT        COVER.NPRODUCT%TYPE,
     NPOLICY         COVER.NPOLICY%TYPE,
     NCERTIF         COVER.NCERTIF%TYPE,
     DEXECDATE       COVER.DEFFECDATE%TYPE,
     SYEAR           CHAR DEFAULT '1',
     NPAYFREQ        CERTIFICAT.NPAYFREQ%TYPE DEFAULT NULL,
     NPREM_TOT       IN OUT NUMBER,
     NROU_SURR_LIFE  SMALLINT DEFAULT 0,
     DEFFECDATE      COVER.DEFFECDATE%TYPE DEFAULT NULL,
     NOPTRECAMOUNT   INTEGER DEFAULT 0,
     NOPTION_EJEC    INTEGER DEFAULT 2,
     NRECEIPT        PREMIUM.NRECEIPT%TYPE DEFAULT NULL,
     SKEY            TCURRENCY.SKEY%TYPE DEFAULT NULL) AUTHID CURRENT_USER AS

    NPAYFREQ_AUX CERTIFICAT.NPAYFREQ%TYPE;

    SSEL            VARCHAR2(2000);
    NCOVER          COVER.NCOVER%TYPE;
    SCLIENT         COVER.SCLIENT%TYPE;
    NCOVER_ANT      COVER.NCOVER%TYPE;
    SCLIENT_ANT     COVER.SCLIENT%TYPE;
    DEFFECDATE_AUX  COVER.DEFFECDATE%TYPE;
    DNULLDATE       COVER.DNULLDATE%TYPE;
    NPREMIUM        COVER.NPREMIUM%TYPE;
    TYPE RCURSOR IS REF CURSOR;
    C_COVER         RCURSOR;
    NPREM_D         COVER.NPREMIUM%TYPE;
    NPREM_PAY       COVER.NPREMIUM%TYPE;
    NPRINTEXP       LIFE_COVER.NPRINTEXP%TYPE;


PROCEDURE INSPRECA017 
/*----------------------------------------------------------------------------------------*/
/* NOMBRE    : INSPRECA017                                                                */
/* OBJETIVO  : GENERACION DE LA TRANSACCION CA017 DE VISUALTIME PARA OBTENER VALOR POLIZA */
/*                                                                                      */
/* PARAMETROS: 1 - SCERTYPE            : TIPO DE REGISTRO                               */
/*             2 - NBRANCH             : CODIGO DEL RAMO                                */
/*             3 - NPRODUCT            : CODIGO DEL PRODUCTO                            */
/*             4 - NPOLICY             : NUMERO DE POLIZA                               */
/*             5 - NCERTIF             : NUMERO DEL CERTIFICADO                         */
/*             6 - DEFFECDATE          : FECHA DE EFECTO DE LA OPERACION                */
/*             7 - DNULLDATE           : FECHA DE ANULACION DE LA OPERACION             */
/*             8 - NTRANSACTION        : CODIGO DE LA TRANSACCION                       */
/*             9 - NUSERCODE           : CODIGO DEL USUARIO                             */
/*                                                                                      */
/* SOURCESAFE INFORMATION:                                                              */
/*     $Author:: Nvaplat7       $                                                       */
/*     $Date:: 21/09/04 10:33a  $                                                       */
/*     $Revision:: 7            $                                                       */
/*--------------------------------------------------------------------------------------*/
    (SCERTYPE             CERTIFICAT.SCERTYPE%TYPE,
     NBRANCH              CERTIFICAT.NBRANCH%TYPE,
     NPRODUCT             CERTIFICAT.NPRODUCT%TYPE,
     NPOLICY              CERTIFICAT.NPOLICY%TYPE,
     NCERTIF              CERTIFICAT.NCERTIF%TYPE,
     DEFFECDATE           CERTIFICAT.DSTARTDATE%TYPE,
     DNULLDATE            CERTIFICAT.DSTARTDATE%TYPE,
     NTRANSACTION         POLICY_HIS.NTRANSACTIO%TYPE,
     NUSERCODE            CERTIFICAT.NUSERCODE%TYPE,
     NAMOUNT              IN OUT PREMIUM.NPREMIUM%TYPE,
     SKEY                 TCURRENCY.SKEY%TYPE) AS

/* VARIABLES AUXILIARES DE TRABAJO */
    NCOUNT           INTEGER;
    NISSUERECEIPT    PREMIUM.NRECEIPT%TYPE;
    DLEDGERDATE      POLICY_HIS.DLEDGERDAT%TYPE;
    SPOLITYPE        POLICY.SPOLITYPE%TYPE;
    SCOLINVOT        POLICY.SCOLINVOT%TYPE;
    SBRANCHT         PRODMASTER.SBRANCHT%TYPE;

    SKEY2            TCURRENCY.SKEY%TYPE; 
/*- DATOS EXISTENTES EN POLICY*/
    C_POLICY         REAPOLICY_BRANCHPKG.RCT1;
    R_POLICY         C_POLICY%ROWTYPE;

/*- DATOS EXISTENTES EN CERTIFICAT*/
    C_CERTIFICAT  REACERTIFICAT_BRANCHPKG.RCT1;
    R_CERTIFICAT  C_CERTIFICAT%ROWTYPE;

/*- DATOS EXISTENTES EN POLICY_HIS*/
    C_POLICY_HIS  REAPOLICY_HIS_1PKG.RCT1;
    R_POLICY_HIS  C_POLICY_HIS%ROWTYPE;

/*-DATOS DEL CUROSR TEMPORAL DEL CALCULO DEL RECIBO */

    TEMPCURSOR        INSCALRECEIPTPKG.RCT1;

    SWINDOWS       VARCHAR(100);
    SCONTEN        VARCHAR2(1);

    NCONTRAT       FINANC_DRA.NCONTRAT%TYPE;
    
    CURSOR  C_DETAILPRE IS 
      SELECT /*+ INDEX ( TDETAIL_PRE XIE2TDETAIL_PRE ) */
          T.NPREMIUM_AN,
          T.NCODE,
          T.STYPE_DETAI,
          0 NGROUP_INSU,
          T.SCLIENT,
          T.NROLE,
          T.NPREMIUME,
          T.NPREMIUMA,
          T.NID_BILL,
          T.NREL_IDBILL,
          A.NCODE     NCOVER,
    7        NAPLY
        FROM TDETAIL_PRE T,
          TDETAIL_PRE A
       WHERE T.SKEY     = INSPRECA017.SKEY
      AND T.STYPE_DETAI IN ('1', '7','8', '9')
         AND A.SKEY     (+)= T.SKEY 
         AND A.NID_BILL (+)= T.NREL_IDBILL
    UNION
      SELECT /*+ INDEX ( TDETAIL_PRE XIE2TDETAIL_PRE ) */
          T.NPREMIUM_AN,
          T.NCODE,
          T.STYPE_DETAI,
          0 NGROUP_INSU,
          T.SCLIENT,
          T.NROLE,
          T.NPREMIUME,
          T.NPREMIUMA,
          T.NID_BILL,
          T.NREL_IDBILL,
          A.NCODE     NCOVER,
    D.NAPLY
        FROM TDETAIL_PRE T,
    TDETAIL_PRE A,
    DISCO_EXPR  D
       WHERE T.SKEY       = INSPRECA017.SKEY
      AND T.STYPE_DETAI NOT IN ('1', '7','8', '9')
         AND A.SKEY        (+) = T.SKEY 
         AND A.NID_BILL    (+) = T.NREL_IDBILL
   AND D.NBRANCH        = INSPRECA017.NBRANCH
   AND D.NPRODUCT        = INSPRECA017.NPRODUCT
   AND D.NDISEXPRC    = T.NCODE
   AND D.DEFFECDATE   <= INSPRECA017.DEFFECDATE
   AND (D.DNULLDATE    IS NULL
    OR D.DNULLDATE    > INSPRECA017.DEFFECDATE);
       
FUNCTION GET_LAST_CONTRAT
/*----------------------------------------------------------------------------*/
/* NOMBRE    : GET_LAST_CONTRAT                                               */
/* OBJETIVO  : RETORNA EL ULTIMO CONTRATO ASOCIADO A LA POLIZA/CERTIFICADO    */
/*----------------------------------------------------------------------------*/
    (SCERTYPE             CERTIFICAT.SCERTYPE%TYPE,
     NBRANCH              CERTIFICAT.NBRANCH%TYPE,
     NPRODUCT             CERTIFICAT.NPRODUCT%TYPE,
     NPOLICY              CERTIFICAT.NPOLICY%TYPE,
     NCERTIF              CERTIFICAT.NCERTIF%TYPE) RETURN PREMIUM.NCONTRAT%TYPE AS

    NCONTRAT_RET    PREMIUM.NCONTRAT%TYPE;



BEGIN
    BEGIN
        SELECT NCONTRAT
          INTO NCONTRAT_RET
          FROM PREMIUM
         WHERE SCERTYPE  = GET_LAST_CONTRAT.SCERTYPE
           AND NBRANCH   = GET_LAST_CONTRAT.NBRANCH
           AND NPRODUCT  = GET_LAST_CONTRAT.NPRODUCT
           AND NPOLICY   = GET_LAST_CONTRAT.NPOLICY
           AND NCERTIF   = GET_LAST_CONTRAT.NCERTIF
           AND NRECEIPT  = (SELECT MAX (NRECEIPT)
                              FROM PREMIUM
                             WHERE SCERTYPE   = GET_LAST_CONTRAT.SCERTYPE
                               AND NBRANCH    = GET_LAST_CONTRAT.NBRANCH
                               AND NPRODUCT   = GET_LAST_CONTRAT.NPRODUCT
                               AND NPOLICY    = GET_LAST_CONTRAT.NPOLICY
                               AND NCERTIF    = GET_LAST_CONTRAT.NCERTIF);
    EXCEPTION
        WHEN OTHERS THEN
            NCONTRAT_RET := 0;
    END;

    RETURN NCONTRAT_RET;

END GET_LAST_CONTRAT;


BEGIN

/*+ LECTURA DE DATOS DE LA POLIZA */
    REAPOLICY_BRANCH(SCERTYPE  => INSPRECA017.SCERTYPE,
                     NBRANCH   => INSPRECA017.NBRANCH,
                     NPRODUCT  => INSPRECA017.NPRODUCT,
                     NPOLICY   => INSPRECA017.NPOLICY,
                     RC1       => C_POLICY);

    FETCH C_POLICY
      INTO R_POLICY;
    CLOSE C_POLICY;

 SBRANCHT  := '1';
    SPOLITYPE := R_POLICY.SPOLITYPE;
    SCOLINVOT := R_POLICY.SCOLINVOT;

    REACOVERCOUNT (SCERTYPE    => INSPRECA017.SCERTYPE,
                   NBRANCH     => INSPRECA017.NBRANCH,
                   NPRODUCT    => INSPRECA017.NPRODUCT,
                   NPOLICY     => INSPRECA017.NPOLICY,
                   NCERTIF     => INSPRECA017.NCERTIF,
                   DEFFECDATE  => INSPRECA017.DEFFECDATE,
                   SCODISPL    => 'CA014',
                   STYP_MODULE => R_POLICY.STYP_MODULE,
                   NCOUNT      => INSPRECA017.NCOUNT);

    IF NCOUNT > 0 THEN

/*+ LECTURA DE DATOS DEL CERTIFICADO */
        REACERTIFICAT_BRANCH(SCERTYPE   => INSPRECA017.SCERTYPE,
                             NBRANCH    => INSPRECA017.NBRANCH,
                             NPRODUCT   => INSPRECA017.NPRODUCT,
                             NPOLICY    => INSPRECA017.NPOLICY,
                             NCERTIF    => INSPRECA017.NCERTIF,
                             RC1        => C_CERTIFICAT);

        FETCH C_CERTIFICAT
         INTO R_CERTIFICAT;
        CLOSE C_CERTIFICAT;

        IF NVL(R_CERTIFICAT.SCERTYPE,'*') <> '*' THEN

            REAPOLICY_HIS_1(SCERTYPE   => INSPRECA017.SCERTYPE,
                            NBRANCH    => INSPRECA017.NBRANCH,
                            NPRODUCT   => INSPRECA017.NPRODUCT,
                            NPOLICY    => INSPRECA017.NPOLICY,
                            NCERTIF    => INSPRECA017.NCERTIF,
                            RC1        => C_POLICY_HIS);

             FETCH C_POLICY_HIS
              INTO R_POLICY_HIS;
             CLOSE C_POLICY_HIS;

             IF R_POLICY_HIS.NMOVEMENT IS NOT NULL THEN
                 DLEDGERDATE := R_POLICY_HIS.DLEDGERDAT;
             END IF;
             SKEY2:=SKEY;   
             INSCALRECEIPT (SCERTYPE       => SCERTYPE,
                            NBRANCH        => NBRANCH,
                            NPRODUCT       => NPRODUCT,
                            NPOLICY        => NPOLICY,
                            NCERTIF        => NCERTIF,
                            DEFFECDATE     => DEFFECDATE,
                            SPRORSHORT     => R_CERTIFICAT.SPRORSHORT,
                            DSTARTCERT     => R_CERTIFICAT.DSTARTDATE,
                            DEXPIRCERT     => R_CERTIFICAT.DEXPIRDAT,
                            DEXPIRPOL      => R_POLICY.DEXPIRDAT,
                            SCOLTIMRE      => R_POLICY.SCOLTIMRE,
                            NPAYFREQ       => R_CERTIFICAT.NPAYFREQ,
                            DNEXTRECEIP    => R_CERTIFICAT.DNEXTRECEIP,
                            SPOLITYPE      => R_POLICY.SPOLITYPE,
                            SCOLINVOT      => R_POLICY.SCOLINVOT,
                            SDECLARI       => R_POLICY.SDECLARI,
                            NPROCTYPE      => NTRANSACTION,
                            DT_EXPIRDAT    => R_CERTIFICAT.DNEXTRECEIP,
                            NANUALITY      => 1,
                            NDAYSFQ        => R_CERTIFICAT.NDAYSFQ,
                            NDAYSSQ        => R_CERTIFICAT.NDAYSSQ,
                            NUSERCODE      => NUSERCODE,
                            SBRANCHT       => SBRANCHT,
                            SDIRDEBIT      => R_POLICY.SDIRDEBIT,
                            NOFFICE        => R_POLICY.NOFFICE,
                            NINTERMED      => R_POLICY.NINTERMED,
                            SCLIENT        => R_POLICY.SCLIENT,
                            NTRANSACTIO    => R_POLICY.NTRANSACTIO,
                            NGROUP         => R_CERTIFICAT.NGROUP,
                            SISSUE_RECEIPT => '1',
                            NREVAL_IND     => 2,
                            NPOLICY_DUR    => 0,
                            NMIN_DURAT     => 0,
                            NRECEIPT       => NISSUERECEIPT ,
                            SKEY           => SKEY2,
                            DDATE_ORIGI    => R_CERTIFICAT.DDATE_ORIGI,
                            NPARTICIP      => R_POLICY.NPARTICIP,
                            DLEDGERDATE    => DLEDGERDATE,
                            NWAY_PAY       => R_CERTIFICAT.NWAY_PAY,
                            SFRACRECEIP    => R_CERTIFICAT.SFRACRECEIP,
                            NRECURSIVECALL => 0,
                            NFLAG          => 0,
                            NCOMMIT        => 2,
                            RC1            => TEMPCURSOR);

        END IF;
    END IF;
    


     NAMOUNT:=0;

     FOR R_DETAILPRE IN C_DETAILPRE LOOP
/*+SI EL INDICADOR DEL RECARGO/DESCUENTO APLICA PARA LA PRIMA MINIMA*/
/*+(1:Prima mínima; 2;Recibo; 3:Costo cobertura;4:Prima minima/ recibo;5:Prima minima/costo cobertura;6;Recibo/costo cobertura;7:Todas)*/  
        IF R_DETAILPRE.NAPLY IN (1, 4, 5, 7)  AND
     R_DETAILPRE.STYPE_DETAI <> '8'    THEN  
      NAMOUNT:= NAMOUNT + R_DETAILPRE.NPREMIUM_AN;
  END IF;
     END LOOP; 


END INSPRECA017;

BEGIN
  IF NVL(NROU_SURR_LIFE,0) <> 1 THEN
        IF NVL(NOPTRECAMOUNT,0) = 0 THEN
            BEGIN
                SELECT NVL(SUM(NPREMIUM),0)
                  INTO NPREM_TOT
                  FROM COVER C 
                 WHERE C.SCERTYPE    = INSCALPREM_BAS_VUL.SCERTYPE
                   AND C.NBRANCH     = INSCALPREM_BAS_VUL.NBRANCH
                   AND C.NPRODUCT    = INSCALPREM_BAS_VUL.NPRODUCT
                   AND C.NPOLICY     = INSCALPREM_BAS_VUL.NPOLICY
                   AND C.NCERTIF     = INSCALPREM_BAS_VUL.NCERTIF
                   AND C.DEFFECDATE <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (C.DNULLDATE IS NULL
                    OR C.DNULLDATE   > INSCALPREM_BAS_VUL.DEXECDATE);
            EXCEPTION
                WHEN OTHERS THEN
                    NPREM_TOT := 0;
            END;
        ELSIF NVL(NOPTRECAMOUNT,0) = 1 THEN
            BEGIN
             INSPRECA017 (SCERTYPE      => SCERTYPE,
           NBRANCH       => NBRANCH,
           NPRODUCT      => NPRODUCT,
           NPOLICY       => NPOLICY,
           NCERTIF       => NCERTIF,
           DEFFECDATE    => DEXECDATE,
           DNULLDATE     => NULL,
           NTRANSACTION  => 1410,
           NUSERCODE     => 1,
           NAMOUNT       => NPREM_TOT,
                             SKEY          => SKEY);
            END;
        ELSIF NVL(NOPTRECAMOUNT,0) = 2 THEN
            BEGIN
                SELECT SUM(NVL(C.NRECAMOUNT,0))
                  INTO NPREM_TOT
                  FROM COVER C 
                 WHERE C.SCERTYPE    = INSCALPREM_BAS_VUL.SCERTYPE
                   AND C.NBRANCH     = INSCALPREM_BAS_VUL.NBRANCH
                   AND C.NPRODUCT    = INSCALPREM_BAS_VUL.NPRODUCT
                   AND C.NPOLICY     = INSCALPREM_BAS_VUL.NPOLICY
                   AND C.NCERTIF     = INSCALPREM_BAS_VUL.NCERTIF
                   AND C.DEFFECDATE <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (C.DNULLDATE IS NULL
                    OR C.DNULLDATE   > INSCALPREM_BAS_VUL.DEXECDATE);
            EXCEPTION
                WHEN OTHERS THEN
                    NPREM_TOT := 0;
            END;
        ELSIF NVL(NOPTRECAMOUNT,0) = 3 THEN
            BEGIN
                SELECT /*+ INDEX (CO XDELCOVER)
                           INDEX (LC XPKLIFE_COVER)*/
                       LC.NPRINTEXP
                  INTO NPRINTEXP
                  FROM COVER CO,   LIFE_COVER LC
                 WHERE CO.SCERTYPE        = INSCALPREM_BAS_VUL.SCERTYPE
                   AND CO.NBRANCH         = INSCALPREM_BAS_VUL.NBRANCH
                   AND CO.NPRODUCT        = INSCALPREM_BAS_VUL.NPRODUCT
                   AND CO.NPOLICY         = INSCALPREM_BAS_VUL.NPOLICY
                   AND CO.NCERTIF         = INSCALPREM_BAS_VUL.NCERTIF
                   AND CO.NGROUP_INSU     = 0
                   AND CO.NROLE           = 2
                   AND CO.DEFFECDATE     <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (CO.DNULLDATE     IS NULL
                    OR CO.DNULLDATE       > INSCALPREM_BAS_VUL.DEXECDATE)
                   AND LC.NBRANCH         = CO.NBRANCH
                   AND LC.NPRODUCT        = CO.NPRODUCT
                   AND LC.NMODULEC        = CO.NMODULEC
                   AND LC.NCOVER          = CO.NCOVER
                   AND LC.DEFFECDATE     <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (LC.DNULLDATE     IS NULL
                    OR LC.DNULLDATE       > INSCALPREM_BAS_VUL.DEXECDATE)
                   AND LC.SCOVERUSE       = '1';
            EXCEPTION
                WHEN OTHERS THEN
                    NPRINTEXP := 0;
            END;

            IF NVL(NPRINTEXP,0) <> 0 THEN
                IF NVL(NOPTION_EJEC,0) = 3 THEN
                    BEGIN
                        SELECT SUM(NVL(C.NRECAMOUNT,0))
                          INTO NPREM_TOT
                          FROM COVER C 
                         WHERE C.SCERTYPE    = INSCALPREM_BAS_VUL.SCERTYPE
                           AND C.NBRANCH     = INSCALPREM_BAS_VUL.NBRANCH
                           AND C.NPRODUCT    = INSCALPREM_BAS_VUL.NPRODUCT
                           AND C.NPOLICY     = INSCALPREM_BAS_VUL.NPOLICY
                           AND C.NCERTIF     = INSCALPREM_BAS_VUL.NCERTIF
                           AND C.DEFFECDATE <= INSCALPREM_BAS_VUL.DEXECDATE
                           AND (C.DNULLDATE IS NULL
                            OR C.DNULLDATE   > INSCALPREM_BAS_VUL.DEXECDATE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            NPREM_TOT := 0;
                    END;
                ELSE
                    INSPAY_VUL(SCERTYPE     => SCERTYPE,
                               NBRANCH      => NBRANCH,
                               NPRODUCT     => NPRODUCT,
                               NPOLICY      => NPOLICY,
                               NCERTIF      => NCERTIF,
                               DEFFECDATE   => DEXECDATE,
                               NORIGIN      => REAGENERALPKG.REAORIGIN_PRIMARY(NBRANCH,NPRODUCT),
                               NPREM_PAY    => NPREM_PAY,
                               NPREINV      => 2,
                               NAPLY        => 6,
                               NRECEIPT     => NRECEIPT,
          NOPTION      => NOPTION_EJEC );

                    IF NVL(NPREM_PAY,0) <> 0 THEN
                        NPREM_TOT := (NPREM_PAY * NPRINTEXP) / (100 + NPRINTEXP);
                    ELSE
                        NPREM_TOT := 0;
                    END IF;
                END IF;
            ELSE
                NPREM_TOT := 0;
            END IF;
        ELSIF NVL(NOPTRECAMOUNT,0) = 4 THEN
            BEGIN
                SELECT /*+ INDEX (CO XDELCOVER)
                           INDEX (LC XPKLIFE_COVER)*/
                       NVL(SUM(CO.NPREMIUM),0)
                  INTO NPREM_TOT
                  FROM COVER CO,   LIFE_COVER LC
                 WHERE CO.SCERTYPE        = INSCALPREM_BAS_VUL.SCERTYPE
                   AND CO.NBRANCH         = INSCALPREM_BAS_VUL.NBRANCH
                   AND CO.NPRODUCT        = INSCALPREM_BAS_VUL.NPRODUCT
                   AND CO.NPOLICY         = INSCALPREM_BAS_VUL.NPOLICY
                   AND CO.NCERTIF         = INSCALPREM_BAS_VUL.NCERTIF
                   AND CO.NGROUP_INSU     = 0
                   AND CO.NROLE           = 2
                   AND CO.DEFFECDATE     <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (CO.DNULLDATE     IS NULL
                    OR CO.DNULLDATE       > INSCALPREM_BAS_VUL.DEXECDATE)
                   AND LC.NBRANCH         = CO.NBRANCH
                   AND LC.NPRODUCT        = CO.NPRODUCT
                   AND LC.NMODULEC        = CO.NMODULEC
                   AND LC.NCOVER          = CO.NCOVER
                   AND LC.DEFFECDATE     <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (LC.DNULLDATE     IS NULL
                    OR LC.DNULLDATE       > INSCALPREM_BAS_VUL.DEXECDATE)
                   AND LC.SCOVERUSE       = '1';
            EXCEPTION
                WHEN OTHERS THEN
                    NPREM_TOT := 0;
            END;
/*+PRIMAS BASICAS ACUMULADAS (PREMPAYED_POL)*/             
        ELSIF NVL(NOPTRECAMOUNT,0) = 5 THEN
            BEGIN
                SELECT NVL(SUM(NQPREMPAYED),0)
                  INTO NPREM_TOT
                  FROM PREMPAYED_POL
                 WHERE SCERTYPE        = INSCALPREM_BAS_VUL.SCERTYPE
                   AND NBRANCH         = INSCALPREM_BAS_VUL.NBRANCH
                   AND NPRODUCT        = INSCALPREM_BAS_VUL.NPRODUCT
                   AND NPOLICY         = INSCALPREM_BAS_VUL.NPOLICY
                   AND NCERTIF         = INSCALPREM_BAS_VUL.NCERTIF
                   AND DEFFECDATE     <= INSCALPREM_BAS_VUL.DEXECDATE
                   AND (DNULLDATE     IS NULL
                    OR DNULLDATE       > INSCALPREM_BAS_VUL.DEXECDATE);
            EXCEPTION
                WHEN OTHERS THEN
                    NPREM_TOT := 0;
            END;            
            
        END IF;

        IF NVL(SYEAR,'2') = '2' THEN
            IF (NVL(NOPTRECAMOUNT,0) <> 3 OR
               (NVL(NOPTRECAMOUNT,0) = 3  AND
               NVL(NOPTION_EJEC,0) = 3))  THEN
                IF NPAYFREQ IS NULL THEN
                    BEGIN
                        SELECT NPAYFREQ
                          INTO NPAYFREQ_AUX
                          FROM CERTIFICAT
                         WHERE SCERTYPE    = INSCALPREM_BAS_VUL.SCERTYPE
                           AND NBRANCH     = INSCALPREM_BAS_VUL.NBRANCH
                           AND NPRODUCT    = INSCALPREM_BAS_VUL.NPRODUCT
                           AND NPOLICY     = INSCALPREM_BAS_VUL.NPOLICY
                           AND NCERTIF     = INSCALPREM_BAS_VUL.NCERTIF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            NPAYFREQ_AUX := NULL;
                    END;
                ELSE
                    NPAYFREQ_AUX := NPAYFREQ;
                END IF;

                IF NPAYFREQ_AUX = 2 THEN
                    NPREM_TOT := NPREM_TOT / 2;
                ELSIF NPAYFREQ_AUX = 3 THEN
                    NPREM_TOT := NPREM_TOT / 4;
                ELSIF NPAYFREQ_AUX = 4 THEN
                    NPREM_TOT := NPREM_TOT / 3;
                ELSIF NPAYFREQ_AUX = 5 THEN
                    NPREM_TOT := NPREM_TOT / 12;
                END IF;
            END IF;
        END IF;
    ELSE
        NPREM_TOT := 0;
        SSEL := 'SELECT /*+ INDEX (C XDELCOVER) */ '
             || '       C.NCOVER,       C.SCLIENT,   '
             || '       C.DEFFECDATE,   C.DNULLDATE, '
             || '       C.NPREMIUM                   '
             || '  FROM COVER   C                    '
             || ' WHERE C.SCERTYPE    = :SCERTYPE  '
             || '   AND C.NBRANCH     = :NBRANCH   '
             || '   AND C.NPRODUCT    = :NPRODUCT  '
             || '   AND C.NPOLICY     = :NPOLICY   '
             || '   AND C.NCERTIF     = :NCERTIF   '
             || '   AND C.DEFFECDATE <= :DEXECDATE ';

        SSEL := SSEL || 'AND (C.DNULLDATE IS NULL OR C.DNULLDATE > :DEFFECDATE) ';

        SSEL := SSEL || ' ORDER BY NCOVER ASC ,SCLIENT ASC, DEFFECDATE DESC ';

            OPEN C_COVER FOR SSEL USING SCERTYPE,     NBRANCH,     NPRODUCT,
                                        NPOLICY,      NCERTIF,     DEXECDATE,
                                        DEXECDATE;
          
        FETCH C_COVER
         INTO NCOVER,     SCLIENT,     DEFFECDATE_AUX,
              DNULLDATE,  NPREMIUM;

        NCOVER_ANT := 0;
        SCLIENT_ANT:= '0';
        WHILE C_COVER%FOUND LOOP

            NPREM_TOT := NPREM_TOT + NPREMIUM;

            FETCH C_COVER
             INTO NCOVER,     SCLIENT,     DEFFECDATE_AUX,
                  DNULLDATE,  NPREMIUM;
            NCOVER_ANT := NCOVER;
            SCLIENT_ANT:= SCLIENT;
        END LOOP;

        CLOSE C_COVER;
    END IF;

END INSCALPREM_BAS_VUL; 
 
 
 
 
 
 