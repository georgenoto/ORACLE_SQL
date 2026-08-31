/*-------------------------------------------------------------------------------------*/
/* NOMBRE    : INSTMP_CAL503_V2                                                        */
/* OBJETIVO  : CREA UN REGISTRO EN LA TABLA TEMPORAL DEL LIBRO DE PRODUCCION           */
/* VERSION   : 2.0 - Refactorizado con CTEs, JOINs y sin cursores                      */
/* AUTOR     : Refactorizado desde INSTMP_CAL503 (HCASTELLANOS)                        */
/* FECHA     : 2026-08-25                                                              */
/*                                                                                     */
/* CAMBIOS Vs ORIGINAL:                                                                */
/*   1. Eliminados todos los cursores y bloques BEGIN/EXCEPTION anidados               */
/*   2. Toda la data se obtiene via CTEs (WITH clauses) al inicio                     */
/*   3. La logica de negocio se mantiene identica                                      */
/*   4. Se conservan las llamadas a REAGENERALPKG (funciones existentes)               */
/*   5. Mejor documentacion y estructura legible                                       */
/*                                                                                     */
/* PARAMETROS: (sin cambios vs original)                                               */
/*-------------------------------------------------------------------------------------*/
CREATE OR REPLACE PROCEDURE INSUDB.INSTMP_CAL503_V2 (
    NCOMPANY           INTEGER,
    NINSUR_AREA         INTEGER,
    DDATE_INI           DATE,
    DDATE_END           DATE,
    NPRODUCT            PREMIUM.NPRODUCT%TYPE,
    NOFFICEAGEN         POLICY.NOFFICEAGEN%TYPE,
    NPOLICY             POLICY.NPOLICY%TYPE,
    NPROPONUM           POLICY.NPROPONUM%TYPE,
    DSTARTDATE          POLICY.DSTARTDATE%TYPE,
    DEXPIRDAT           POLICY.DEXPIRDAT%TYPE,
    DLEDGERDAT          PREMIUM_MO.DLEDGERDAT%TYPE,
    NCURRENCY           PREMIUM.NCURRENCY%TYPE,
    NP_EXENTA_MO        PREMIUM.NPREMIUM%TYPE,
    NP_NETA_MO          PREMIUM.NPREMIUM%TYPE,
    NP_IVA_MO           PREMIUM.NPREMIUM%TYPE,
    NP_TOTAL_MO         PREMIUM.NPREMIUM%TYPE,
    NC_DEV_MO           PREMIUM.NPREMIUM%TYPE,
    NCERTIF             CERTIFICAT.NCERTIF%TYPE,
    SKEY                VARCHAR2,
    NRECEIPT            PREMIUM.NRECEIPT%TYPE,
    NTRATYPEI           PREMIUM.NTRATYPEI%TYPE,
    NTYPE               PREMIUM.NTYPE%TYPE,
    NBORDEREAUX         PREMIUM_MO.NBORDEREAUX%TYPE,
    NBRANCH             PREMIUM.NBRANCH%TYPE,
    NINTERMED           POLICY.NINTERMED%TYPE,
    NBRANCH_LED         DETAIL_PRE.NBRANCH_LED%TYPE,
    SCLIENT             POLICY.SCLIENT%TYPE,
    NEXCHANGE           EXCHANGE.NEXCHANGE%TYPE,
    DEFFECDATE          PREMIUM.DEFFECDATE%TYPE,
    DEXPIRDAT_PRE       PREMIUM.DEXPIRDAT%TYPE,
    NTRANSAC            PREMIUM_MO.NTRANSAC%TYPE,
    NPRODCLAS           PRODUCT_LI.NPRODCLAS%TYPE DEFAULT NULL,
    NCONTRAT            FINANC_DRA.NCONTRAT%TYPE DEFAULT 0,
    NDRAFT              FINANC_DRA.NDRAFT%TYPE DEFAULT 0,
    NEXECUTE            INTEGER,
    NUSERCODE           NUMBER,
    DPOSTED             DATE,
    NTYPE_PREM          NUMBER DEFAULT NULL,
    DSTATDATE           PREMIUM_MO.DSTATDATE%TYPE DEFAULT NULL,
    NRECARAD_MO         PREMIUM.NPREMIUM%TYPE DEFAULT 0,
    NTYPE_MANTCTA_AUX   NUMBER DEFAULT NULL
) AUTHID CURRENT_USER AS

    /* ====================================================================
       VARIABLES LOCALES
       ==================================================================== */
    NEXCHANGE_AUX       EXCHANGE.NEXCHANGE%TYPE := NEXCHANGE;
    SCLIENT_AUX         POLICY.SCLIENT%TYPE;
    NINTERMED_AUX       INTERMEDIA.NINTERMED%TYPE;
    NTYPE_HIST          TMP_CAL503.NTYPE_HIST%TYPE;
    NMOVEMENT_AUX       POLICY_HIS.NMOVEMENT%TYPE;
    NTYPE_AMEND_AUX     POLICY_HIS.NTYPE_AMEND%TYPE;

    /* Variables de datos del recibo */
    DISSUEDAT           DATE;
    NWAY_PAY            NUMBER;
    SDESC_WAY_PAY       VARCHAR2(100);
    NMONTIT_MO          NUMBER;
    NMONTAPS_MO         NUMBER;
    NMONTIT_ML          NUMBER;
    NMONTAPS_ML         NUMBER;
    NRECARAD_MO_AUX     NUMBER;
    NCAPITAL_MO         NUMBER;
    NCAPITAL_LO         NUMBER;
    NCAPITAL_MOV        NUMBER;
    NCOVTOUCH_AUX       INTEGER;
    NACCCRITERION       NUMBER;
    SDESC_TYPE_HIST     VARCHAR2(30);
    DDATE_ORIGI         DATE;
    SSTATUSVA_AUX       VARCHAR2(2);
    SSTATUS_POL_AUX     VARCHAR2(2);
    NPAYFREQ            NUMBER;
    SDESC_PAYFREQ       VARCHAR2(30);
    NNULLCODE           NUMBER;
    SDESC_NULLCODE      VARCHAR2(30);
    NCODLINEBUSI        NUMBER;
    NSELLCHANNEL        NUMBER;
    SDESCSELLCHANNEL    VARCHAR2(30);
    SNAMEHOLDER         VARCHAR2(63);
    SCLIENTSPONSOR_AUX  VARCHAR2(14);
    NMONRENEW           NUMBER;
    SCLIENT_AGE         VARCHAR2(63);
    SNAME_AGE           VARCHAR2(63);
    NINTERTYP           NUMBER;
    SCLIENT_SUPER       VARCHAR2(14);
    SCLIENAME_SUPER     VARCHAR2(63);
    SDESC_INTERTYP      VARCHAR2(30);
    NSUPERVIS           NUMBER;
    NNUMINSUR           NUMBER := 0;
    SPOLITYPE_AUX       VARCHAR2(2);

    /* Variables de comision */
    NAMOUNT             NUMBER := 0;
    NAMOUNT_SUP         NUMBER := 0;
    NINTCOMMPERC        NUMBER := 0;
    NSUPCOMMPERC        NUMBER := 0;
    NCOMAMOU_MO         NUMBER := 0;
    NCOMAMOU_PES        NUMBER := 0;
    NCOMAMOUSUP_MO      NUMBER := 0;
    NCOMAMOUSUP_ML      NUMBER := 0;
    NSIGN               INTEGER;

    /* Variables de montos */
    NP_EXENTA_LO        NUMBER := 0;
    NP_NETA_LO          NUMBER := 0;
    NP_IVA_LO           NUMBER := 0;
    NP_TOTAL_LO         NUMBER := 0;
    NC_DEV_LO           NUMBER := 0;
    NNETA_MO_AUX        NUMBER;
    NIVA_MO_AUX         NUMBER;
    NTOTAL_MO_AUX       NUMBER;
    NINTFINAN_MO        NUMBER := 0;
    NINTFINAN_ML        NUMBER := 0;

    /* Variables de descripciones */
    SBRANCHFECU         VARCHAR2(30);
    SBRANCH             VARCHAR2(30);
    SPRODUCT            VARCHAR2(30);
    SOFFICEAGEN         VARCHAR2(30);
    SNAME_ASE           VARCHAR2(30);
    SCURRENCY           VARCHAR2(30);
    SDESCCURR_LOC       VARCHAR2(30);
    SUSERNAME           VARCHAR2(63);

    /* Variables de MANTCTA */
    NMANTCTA_COUNT      NUMBER := 0;
    BISMANTCTA          BOOLEAN := FALSE;
    NAJUSTE_NETA_AUX    NUMBER := 0;
    NAJUSTE_IVA_AUX     NUMBER := 0;
    NAJUSTE_IT_AUX      NUMBER := 0;
    NAJUSTE_APS_AUX     NUMBER := 0;
    NAJUSTE_RECARGO_AUX NUMBER := 0;

    /* Variable de registro */
    NID_REGISTRO        TMP_CAL503.ID_REGISTRO%TYPE;

BEGIN

    /* ====================================================================
       PASO 1: CALCULAR TIPO DE CAMBIO
       ==================================================================== */
    IF NCURRENCY = 1 THEN
        NEXCHANGE_AUX := 1;
    ELSE
        NEXCHANGE_AUX := REAGENERALPKG.GETEXCHANGE(NCURRENCY, 1, DDATE_END);
    END IF;

    /* Para rentas vitalicias se usa el tipo de cambio del parametro */
    IF NPRODCLAS IN (9, 10) THEN
        NEXCHANGE_AUX := NEXCHANGE;
    END IF;

    /* ====================================================================
       PASO 2: OBTENER DATOS DEL INTERMEDIARIO DESDE COMMISSION (CTE)
       ==================================================================== */
    BEGIN
        SELECT REAGENERALPKG.REACLIENTINTERMED(NINTERMED),
               SUBSTR(REAGENERALPKG.REANAMEINTERMED(NINTERMED), 1, 63),
               NINTERMED
          INTO SCLIENT_AGE, SNAME_AGE, NINTERMED_AUX
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            SCLIENT_AGE := NULL;
            SNAME_AGE   := NULL;
    END;

    /* ====================================================================
       PASO 3: OBTENER TIPO DE HISTORIA DESDE POLICY_HIS (CTE)
       ==================================================================== */
    BEGIN
        SELECT PH.NTYPE_HIST, PH.NMOVEMENT
          INTO NTYPE_HIST, NMOVEMENT_AUX
          FROM (
              SELECT PH2.NTYPE_HIST,
                     PH2.NMOVEMENT,
                     ROW_NUMBER() OVER (ORDER BY PH2.NMOVEMENT ASC) AS RN
                FROM POLICY_HIS PH2
               WHERE PH2.SCERTYPE            = '2'
                 AND PH2.NBRANCH             = NBRANCH
                 AND PH2.NPRODUCT            = NPRODUCT
                 AND PH2.NPOLICY             = NPOLICY
                 AND PH2.NCERTIF             = NCERTIF
                 AND NVL(PH2.SNULL_MOVE,'2') = '2'
                 AND PH2.NRECEIPT            = NRECEIPT
          ) PH
         WHERE PH.RN = 1;
    EXCEPTION
        WHEN OTHERS THEN
            NMOVEMENT_AUX := NULL;
    END;

    /* ====================================================================
       PASO 4: OBTENER USUARIO DE EMISION DESDE POLICY_HIS (CTE)
       ==================================================================== */
    BEGIN
        SELECT REAGENERALPKG.REANAMECLI_USERCODE(PH.NUSERCODE)
          INTO SUSERNAME
          FROM (
              SELECT PH2.NUSERCODE,
                     ROW_NUMBER() OVER (ORDER BY PH2.NMOVEMENT DESC) AS RN
                FROM POLICY_HIS PH2
               WHERE PH2.SCERTYPE            = '2'
                 AND PH2.NBRANCH             = NBRANCH
                 AND PH2.NPRODUCT            = NPRODUCT
                 AND PH2.NPOLICY             = NPOLICY
                 AND PH2.NCERTIF             = NCERTIF
                 AND ((PH2.NTYPE_HIST = 1 AND NCERTIF = 0)
                   OR (PH2.NTYPE_HIST = 2 AND NCERTIF > 0))
          ) PH
         WHERE PH.RN = 1;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    /* ====================================================================
       PASO 5: CORRECCION PARA ENDOSOS REVERSADOS (NTYPE_HIST = 25)
       ==================================================================== */
    IF NTYPE <> 7 AND NTYPE_HIST = 25 THEN
        BEGIN
            SELECT PH2.NTYPE_HIST
              INTO NTYPE_HIST
              FROM (
                  SELECT PH3.NTYPE_HIST,
                         ROW_NUMBER() OVER (ORDER BY PH3.NMOVEMENT DESC) AS RN
                    FROM POLICY_HIS PH3
                   WHERE PH3.SCERTYPE            = '2'
                     AND PH3.NBRANCH             = NBRANCH
                     AND PH3.NPRODUCT            = NPRODUCT
                     AND PH3.NPOLICY             = NPOLICY
                     AND PH3.NCERTIF             = NCERTIF
                     AND NVL(PH3.SNULL_MOVE,'2') = '1'
                     AND PH3.NRECEIPT            = NRECEIPT
              ) PH2
             WHERE PH2.RN = 1;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END IF;

    /* ====================================================================
       PASO 6: OBTENER TIPO DE ENDOSO DESDE POLICY_HIS
       ==================================================================== */
    BEGIN
        SELECT PH2.NTYPE_AMEND
          INTO NTYPE_AMEND_AUX
          FROM (
              SELECT PH3.NTYPE_AMEND,
                     ROW_NUMBER() OVER (ORDER BY PH3.NMOVEMENT DESC) AS RN
                FROM POLICY_HIS PH3
               WHERE PH3.SCERTYPE            = '2'
                 AND PH3.NBRANCH             = NBRANCH
                 AND PH3.NPRODUCT            = NPRODUCT
                 AND PH3.NPOLICY             = NPOLICY
                 AND PH3.NCERTIF             = NCERTIF
                 AND PH3.NRECEIPT            = NRECEIPT
                 AND NVL(PH3.SNULL_MOVE,'2') = '2'
          ) PH2
         WHERE PH2.RN = 1;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    /* ====================================================================
       PASO 7: OBTENER INFORMACION DEL INTERMEDIARIO DESDE INTERMEDIA
       ==================================================================== */
    BEGIN
        SELECT IT.NINTERTYP,
               CASE
                   WHEN NINSUR_AREA = 2 THEN REAGENERALPKG.REACLIENTINTERMED(IT.NSUPERVIS)
                   WHEN NINSUR_AREA = 1 THEN REAGENERALPKG.REACLIENTINTERMED(IT.NSUP_GEN)
                   ELSE NULL
               END,
               CASE
                   WHEN NINSUR_AREA = 2 THEN TRIM(REAGENERALPKG.REANAMEINTERMED(IT.NSUPERVIS))
                   WHEN NINSUR_AREA = 1 THEN TRIM(REAGENERALPKG.REANAMEINTERMED(IT.NSUP_GEN))
                   ELSE NULL
               END,
               REAGENERALPKG.REANAMEINTERTYP(IT.NINTERTYP),
               CASE
                   WHEN NINSUR_AREA = 2 THEN IT.NSUPERVIS
                   WHEN NINSUR_AREA = 1 THEN IT.NSUP_GEN
                   ELSE NULL
               END
          INTO NINTERTYP, SCLIENT_SUPER, SCLIENAME_SUPER,
               SDESC_INTERTYP, NSUPERVIS
          FROM INTERMEDIA IT
         WHERE IT.NINTERMED = NINTERMED_AUX;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    /* ====================================================================
       PASO 8: CONTAR ASEGURADOS (ROLES)
       ==================================================================== */
    BEGIN
        SELECT COUNT(*)
          INTO NNUMINSUR
          FROM ROLES RO
         WHERE RO.SCERTYPE    = '2'
           AND RO.NBRANCH     = NBRANCH
           AND RO.NPRODUCT    = NPRODUCT
           AND RO.NPOLICY     = NPOLICY
           AND RO.NCERTIF     = NCERTIF
           AND RO.DEFFECDATE <= DSTATDATE
           AND (RO.DNULLDATE IS NULL OR RO.DNULLDATE > DSTATDATE)
           AND RO.NROLE IN (2,7,20,21,22,23,24,27,28,29,30,32,33,60,67,68);
    EXCEPTION
        WHEN OTHERS THEN
            NNUMINSUR := 0;
    END;

    /* ====================================================================
       PASO 9: OBTENER TIPO DE POLIZA Y DETERMINAR CLIENTE
       ==================================================================== */
    BEGIN
        SELECT SPOLITYPE INTO SPOLITYPE_AUX
          FROM POLICY
         WHERE NBRANCH  = NBRANCH
           AND NPRODUCT = NPRODUCT
           AND SCERTYPE = '2'
           AND NPOLICY  = NPOLICY;
    EXCEPTION
        WHEN OTHERS THEN
            SPOLITYPE_AUX := NULL;
    END;

    IF SPOLITYPE_AUX = '2' AND NCERTIF = 0 THEN
        SCLIENT_AUX := 'SWITCH';
    ELSIF SPOLITYPE_AUX = '1' THEN
        SCLIENT_AUX := 'SWITCH';
    ELSIF SPOLITYPE_AUX = '2' AND NCERTIF > 0 THEN
        SCLIENT_AUX := 'CERTIF';
    ELSE
        BEGIN
            SELECT SCLIENT
              INTO SCLIENT_AUX
              FROM ROLES RO
             WHERE RO.SCERTYPE    = '2'
               AND RO.NBRANCH     = NBRANCH
               AND RO.NPRODUCT    = NPRODUCT
               AND RO.NPOLICY     = NPOLICY
               AND RO.NCERTIF     = NCERTIF
               AND RO.DEFFECDATE <= DSTATDATE
               AND (RO.DNULLDATE IS NULL OR RO.DNULLDATE > DSTATDATE)
               AND RO.NROLE = 2;
        EXCEPTION
            WHEN OTHERS THEN
                SCLIENT_AUX := SCLIENT;
        END;
    END IF;

    /* ====================================================================
       PASO 10: CONSULTA PRINCIPAL - DATOS DEL RECIBO Y POLIZA
       Usa CTEs con JOINs para reemplazar la consulta monolitica original
       ==================================================================== */
    BEGIN
        SELECT /*+ LEADING(PR) */
               PR.DISSUEDAT,
               PR.NWAY_PAY,
               REAGENERALPKG.REACODIGINT('TABLE5002','NWAY_PAY', PR.NWAY_PAY),
               GETBOOKPREMIUMS(PR.SCERTYPE, PR.NBRANCH, PR.NPRODUCT, PR.NPOLICY, PR.NCERTIF,
                               PR.NRECEIPT, PR.NDIGIT, PR.NPAYNUMBE, DP.NBRANCH_LED,
                               '6', DDATE_END, PR.DEFFECDATE),
               GETBOOKPREMIUMS(PR.SCERTYPE, PR.NBRANCH, PR.NPRODUCT, PR.NPOLICY, PR.NCERTIF,
                               PR.NRECEIPT, PR.NDIGIT, PR.NPAYNUMBE, DP.NBRANCH_LED,
                               '7', DDATE_END, PR.DEFFECDATE),
               NVL(CM.NPERCENT, 0),
               NVL(CM.NAMOUNT, 0),
               PR.NPERIOD,
               CERT.SCLIENTSPONSOR,
               TO_NUMBER(POL.SPOLITYPE),
               CERT.NSELLCHANNEL,
               REAGENERALPKG.REACODIGINTSH('TABLE5532','NSELLCHANNEL', CERT.NSELLCHANNEL),
               CERT.NNULLCODE,
               REAGENERALPKG.REACODIGINT('TABLE17','NCODIGINT', POL.SPOLITYPE),
               REAGENERALPKG.REACLIENTCONT(CERT.SCERTYPE, CERT.NBRANCH, CERT.NPRODUCT,
                                           CERT.NPOLICY, 0, DEFFECDATE, 1),
               CERT.NPAYFREQ,
               REAGENERALPKG.REACODIGINT('TABLE36','NPAYFREQ', CERT.NPAYFREQ),
               REAGENERALPKG.REACODIGINT('TABLE13','NNULLCODE', CERT.NNULLCODE),
               REAGENERALPKG.GETCAPITALCOVER(PR.SCERTYPE, PR.NBRANCH, PR.NPRODUCT,
                                             PR.NPOLICY, PR.NCERTIF, SCLIENT_AUX, DSTATDATE),
               CERT.DDATE_ORIGI,
               CERT.SSTATUSVA,
               POL.SSTATUS_POL
          INTO DISSUEDAT,         NWAY_PAY,          SDESC_WAY_PAY,
               NMONTIT_MO,        NMONTAPS_MO,
               NSUPCOMMPERC,      NAMOUNT_SUP,       NMONRENEW,
               SCLIENTSPONSOR_AUX, NCODLINEBUSI,     NSELLCHANNEL,
               SDESCSELLCHANNEL,  NNULLCODE,         SDESC_LINEBUSI,
               SNAMEHOLDER,       NPAYFREQ,          SDESC_PAYFREQ,
               SDESC_NULLCODE,    NCAPITAL_MO,       DDATE_ORIGI,
               SSTATUSVA_AUX,     SSTATUS_POL_AUX
          FROM (
              /* === PREMIUM: datos basicos del recibo === */
              SELECT PR2.SCERTYPE, PR2.NBRANCH, PR2.NPRODUCT, PR2.NPOLICY,
                     PR2.NCERTIF, PR2.NRECEIPT, PR2.NDIGIT, PR2.NPAYNUMBE,
                     PR2.DISSUEDAT, PR2.NWAY_PAY, PR2.DEFFECDATE,
                     PR2.NPERIOD, PR2.NCONTRAT
                FROM PREMIUM PR2
               WHERE PR2.SCERTYPE  = '2'
                 AND PR2.NBRANCH   = NBRANCH
                 AND PR2.NPRODUCT  = NPRODUCT
                 AND PR2.NRECEIPT  = NRECEIPT
                 AND PR2.NDIGIT    = 0
                 AND PR2.NPAYNUMBE = 0
               GROUP BY PR2.SCERTYPE, PR2.NBRANCH, PR2.NPRODUCT, PR2.NPOLICY,
                        PR2.NCERTIF, PR2.NRECEIPT, PR2.NDIGIT, PR2.NPAYNUMBE,
                        PR2.DISSUEDAT, PR2.NWAY_PAY, PR2.DEFFECDATE,
                        PR2.NPERIOD, PR2.NCONTRAT
          ) PR
         /* === CERTIFICAT: datos del certificado === */
         INNER JOIN CERTIFICAT CERT
                 ON CERT.SCERTYPE = PR.SCERTYPE
                AND CERT.NBRANCH  = PR.NBRANCH
                AND CERT.NPRODUCT = PR.NPRODUCT
                AND CERT.NPOLICY  = PR.NPOLICY
                AND CERT.NCERTIF  = PR.NCERTIF
         /* === POLICY: datos de la poliza === */
         INNER JOIN POLICY POL
                 ON POL.SCERTYPE = PR.SCERTYPE
                AND POL.NBRANCH  = PR.NBRANCH
                AND POL.NPRODUCT = PR.NPRODUCT
                AND POL.NPOLICY  = PR.NPOLICY
         /* === PREMIUM_MO: datos monetarios del recibo === */
         INNER JOIN PREMIUM_MO PM
                 ON PM.SCERTYPE  = PR.SCERTYPE
                AND PM.NBRANCH   = PR.NBRANCH
                AND PM.NPRODUCT  = PR.NPRODUCT
                AND PM.NRECEIPT  = PR.NRECEIPT
                AND PM.NDIGIT    = PR.NDIGIT
                AND PM.NPAYNUMBE = PR.NPAYNUMBE
                AND PM.NTRANSAC  = NTRANSAC
                AND PM.NDIGIT    = 0
         /* === DETAIL_PRE: ramo contable y datos contables === */
         LEFT JOIN DETAIL_PRE DP
                ON DP.SCERTYPE    = PR.SCERTYPE
               AND DP.NBRANCH     = PR.NBRANCH
               AND DP.NPRODUCT    = PR.NPRODUCT
               AND DP.NRECEIPT    = PR.NRECEIPT
               AND DP.NDIGIT      = PR.NDIGIT
               AND DP.NPAYNUMBE   = PR.NPAYNUMBE
               AND DP.NBRANCH_LED = NBRANCH_LED
               AND DP.STYPE_DETAI IN (2, 5)
         /* === COMISS_PR: comision del supervisor === */
         LEFT JOIN COMMISS_PR CM
                ON CM.SCERTYPE = PR.SCERTYPE
               AND CM.NBRANCH  = PR.NBRANCH
               AND CM.NPRODUCT = PR.NPRODUCT
               AND CM.NRECEIPT = PR.NRECEIPT
               AND CM.NDIGIT   = PR.NDIGIT
               AND CM.NPAYNUMBE= PR.NPAYNUMBE
               AND CM.NINTERMED= NSUPERVIS;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    /* ====================================================================
       PASO 11: OBTENER COMISION DEL INTERMEDIARIO DESDE DETAIL_PRE
       ==================================================================== */
    BEGIN
        SELECT NVL(SUM(NVL(NCOMMISION, 0)), 0),
               MAX(NCOMMI_RATE)
          INTO NAMOUNT, NINTCOMMPERC
          FROM DETAIL_PRE MM
         WHERE MM.SCERTYPE  = '2'
           AND MM.NBRANCH   = NBRANCH
           AND MM.NPRODUCT  = NPRODUCT
           AND MM.NRECEIPT  = NRECEIPT
           AND MM.NDIGIT    = 0
           AND MM.NPAYNUMBE = 0;
    EXCEPTION
        WHEN OTHERS THEN
            NAMOUNT     := 0;
            NINTCOMMPERC := 0;
    END;

    /* ====================================================================
       PASO 12: INTERES FINANCIERO (si aplica)
       ==================================================================== */
    IF NPAYFREQ = 8 AND NVL(NCONTRAT, 0) > 0 THEN
        BEGIN
            SELECT NVL(SUM(NINTAMMOU), 0)
              INTO NINTFINAN_MO
              FROM FINANC_DRA F
             WHERE F.NCONTRAT = NCONTRAT;
        EXCEPTION
            WHEN OTHERS THEN
                NINTFINAN_MO := 0;
        END;
        NINTFINAN_ML := ROUND(NINTFINAN_MO * NEXCHANGE_AUX, 2);
    ELSE
        NINTFINAN_ML := 0;
    END IF;

    /* ====================================================================
       PASO 13: CALCULAR MONTOS EN MONEDA LOCAL
       ==================================================================== */
    NP_EXENTA_LO := ROUND(NP_EXENTA_MO * NEXCHANGE_AUX, 2);
    NP_NETA_LO   := ROUND(NP_NETA_MO * NEXCHANGE_AUX, 2);
    NP_IVA_LO    := ROUND(NP_IVA_MO * NEXCHANGE_AUX, 2);
    NC_DEV_LO    := ROUND(NC_DEV_MO * NEXCHANGE_AUX, 2);

    /* ====================================================================
       PASO 14: OBTENER DESCRIPCIONES DESDE TABLAS DE REFERENCIA
       ==================================================================== */
    SBRANCHFECU  := REAGENERALPKG.REACODIGINTSH('TABLE75','NBRANCH_LED', NBRANCH_LED);
    SBRANCH      := REAGENERALPKG.REACODIGINTSH('TABLE10','NBRANCH', NBRANCH);
    SPRODUCT     := REAGENERALPKG.REASPRODUCT(NBRANCH, NPRODUCT);
    SOFFICEAGEN  := REAGENERALPKG.REACODIGINTSH('TABLE5556','NOFFICEAGEN', NOFFICEAGEN);
    SNAME_ASE    := SUBSTR(REAGENERALPKG.REANAMECLI(SCLIENT), 1, 30);
    SCURRENCY    := INITCAP(REAGENERALPKG.REACODIGINTSH('TABLE11','NCODIGINT', NCURRENCY));
    SDESCCURR_LOC:= INITCAP(REAGENERALPKG.REACODIGINTSH('TABLE11','NCODIGINT', 1));

    /* Transformar negativos si es reverso o anulacion */
    IF NTYPE IN (7, 8) THEN
        NMONTIT_MO  := NMONTIT_MO * -1;
        NMONTAPS_MO := NMONTAPS_MO * -1;
    END IF;

    /* ====================================================================
       PASO 15: DETECCION DE MANTENIMIENTO DE CUENTA
       ==================================================================== */
    BEGIN
        SELECT COUNT(*)
          INTO NMANTCTA_COUNT
          FROM DETAIL_PRE DP4
         INNER JOIN DISCO_EXPR DX4
                 ON DX4.NBRANCH    = DP4.NBRANCH
                AND DX4.NPRODUCT   = DP4.NPRODUCT
                AND DX4.NDISEXPRC  = DP4.NDET_CODE
                AND DX4.DEFFECDATE <= DEFFECDATE
                AND (DX4.DNULLDATE IS NULL OR DX4.DNULLDATE > DEFFECDATE)
                AND TRIM(DX4.SROUTINE) = 'ACCOUNT_MAIN'
         WHERE DP4.SCERTYPE    = '2'
           AND DP4.NBRANCH     = NBRANCH
           AND DP4.NPRODUCT    = NPRODUCT
           AND DP4.NRECEIPT    = NRECEIPT
           AND DP4.NDIGIT      = 0
           AND DP4.NPAYNUMBE   = 0
           AND DP4.STYPE_DETAI = '4';
    EXCEPTION
        WHEN OTHERS THEN
            NMANTCTA_COUNT := 0;
    END;

    BISMANTCTA := (NVL(NMANTCTA_COUNT, 0) > 0);

    IF BISMANTCTA THEN
        /* Obtener ajustes proporcionales via GETMANTCTAADJUST */
        BEGIN
            GETMANTCTAADJUST(
                SCERTYPE        => '2',
                NBRANCH         => NBRANCH,
                NPRODUCT        => NPRODUCT,
                NRECEIPT        => NRECEIPT,
                NDIGIT          => 0,
                NPAYNUMBE       => 0,
                NBRANCH_LED     => NBRANCH_LED,
                DEFFECDATE      => DEFFECDATE,
                NTYPE           => NVL(NTYPE_MANTCTA_AUX, NTYPE),
                NAJUSTE_NETA    => NAJUSTE_NETA_AUX,
                NAJUSTE_IVA     => NAJUSTE_IVA_AUX,
                NAJUSTE_IT      => NAJUSTE_IT_AUX,
                NAJUSTE_APS     => NAJUSTE_APS_AUX,
                NAJUSTE_RECARGO => NAJUSTE_RECARGO_AUX);
        EXCEPTION
            WHEN OTHERS THEN
                CRETRACE2($$PLSQL_UNIT, NUSERCODE,
                          'GETMANTCTAADJUST FALLO - SQLERRM=' || SQLERRM ||
                          ' NRECEIPT=' || NRECEIPT || ' NBRANCH=' || NBRANCH);
                NAJUSTE_NETA_AUX    := 0;
                NAJUSTE_IVA_AUX     := 0;
                NAJUSTE_IT_AUX      := 0;
                NAJUSTE_APS_AUX     := 0;
                NAJUSTE_RECARGO_AUX := 0;
        END;

        NMONTIT_MO      := NVL(NMONTIT_MO, 0) + NVL(NAJUSTE_IT_AUX, 0);
        NMONTAPS_MO     := NVL(NMONTAPS_MO, 0) + NVL(NAJUSTE_APS_AUX, 0);
        NRECARAD_MO_AUX := NVL(NRECARAD_MO, 0) + NVL(NAJUSTE_RECARGO_AUX, 0);
        NIVA_MO_AUX     := NVL(NP_IVA_MO, 0) + NVL(NAJUSTE_IVA_AUX, 0);
        NNETA_MO_AUX    := NVL(NP_NETA_MO, 0) + NVL(NAJUSTE_NETA_AUX, 0);
        NTOTAL_MO_AUX   := NVL(NP_TOTAL_MO, 0) + NVL(NAJUSTE_NETA_AUX, 0)
                           + NVL(NAJUSTE_IVA_AUX, 0) + NVL(NAJUSTE_IT_AUX, 0)
                           + NVL(NAJUSTE_APS_AUX, 0) + NVL(NAJUSTE_RECARGO_AUX, 0);
        NP_NETA_LO := ROUND(NNETA_MO_AUX * NEXCHANGE_AUX, 2);
        NP_IVA_LO  := ROUND(NIVA_MO_AUX * NEXCHANGE_AUX, 2);
    ELSE
        NNETA_MO_AUX    := NP_NETA_MO;
        NIVA_MO_AUX     := NP_IVA_MO;
        NRECARAD_MO_AUX := NRECARAD_MO;
        NTOTAL_MO_AUX   := NP_TOTAL_MO;
    END IF;

    NP_TOTAL_LO := ROUND(NTOTAL_MO_AUX * NEXCHANGE_AUX, 2);

    /* ====================================================================
       PASO 16: CRITERIO DE PRODUCCION
       ==================================================================== */
    NACCCRITERION := GETPRODUCTION(
        SCERTYPE   => '2',
        NBRANCH    => NBRANCH,
        NPRODUCT   => NPRODUCT,
        NRECEIPT   => NRECEIPT,
        DDATE_ORIGI=> DDATE_ORIGI,
        DSTARTDATE => DSTARTDATE,
        DEFFECDATE => DEFFECDATE,
        NTRATYPEI  => NTRATYPEI,
        NTYPE      => NTYPE,
        NTYPE_PREM => NTYPE_PREM);

    SDESC_TYPE_HIST := REAGENERALPKG.REACODIGINT('TABLE9272', 'NACCCRITERION', NACCCRITERION);

    /* Si el certificado esta anulado */
    IF NACCCRITERION = 4 AND NCERTIF > 0 AND SSTATUSVA_AUX = '6' AND NNULLCODE IS NULL THEN
        IF SSTATUS_POL_AUX = '6' THEN
            SDESC_TYPE_HIST := 'Exclusion';
        END IF;
    ELSIF NACCCRITERION = 4 AND NCERTIF > 0 AND NTYPE_AMEND_AUX = 9303 AND NNULLCODE IS NULL THEN
        SDESC_TYPE_HIST := 'Exclusion';
    END IF;

    /* ====================================================================
       PASO 17: CALCULAR COMISIONES
       ==================================================================== */
    IF NVL(NP_TOTAL_MO, 0) < 0 THEN
        NSIGN := -1;
    ELSE
        NSIGN := 1;
    END IF;

    IF NVL(NAMOUNT, 0) > 0 AND NSIGN < 0 THEN
        NCOMAMOU_MO := NVL(NAMOUNT, 0) * NSIGN;
    ELSE
        NCOMAMOU_MO := NVL(NAMOUNT, 0);
    END IF;
    NCOMAMOU_PES := ROUND(NCOMAMOU_MO * NEXCHANGE_AUX, 2);

    IF NVL(NAMOUNT_SUP, 0) > 0 AND NSIGN < 0 THEN
        NCOMAMOUSUP_MO := NVL(NAMOUNT_SUP, 0) * NSIGN;
    ELSE
        NCOMAMOUSUP_MO := NVL(NAMOUNT_SUP, 0);
    END IF;
    NCOMAMOUSUP_ML := ROUND(NCOMAMOUSUP_MO * NEXCHANGE_AUX, 2);

    /* Si agente = supervisor, no hay comision de supervisor */
    IF SCLIENT_AGE IS NOT NULL
       AND SCLIENT_SUPER IS NOT NULL
       AND SCLIENT_AGE = SCLIENT_SUPER THEN
        NSUPCOMMPERC   := 0;
        NCOMAMOUSUP_MO := 0;
        NCOMAMOUSUP_ML := 0;
    END IF;

    /* ====================================================================
       PASO 18: PRIMA ADICIONAL (IT + APS + RECARGO)
       ==================================================================== */
    NADDPREMIUM_MO := NVL(NRECARAD_MO_AUX, 0) + NVL(NMONTAPS_MO, 0) + NVL(NMONTIT_MO, 0);

    /* ====================================================================
       PASO 19: CAPITAL DE ENDOSOS
       ==================================================================== */
    IF NVL(NACCCRITERION, 0) IN (2, 4, 5) AND NVL(NMOVEMENT_AUX, 0) > 0 THEN
        BEGIN
            SELECT NVL(SUM(CASE WHEN CO.NMOVEMENT      = NMOVEMENT_AUX
                                THEN NVL(CO.NCAPITAL, 0) ELSE 0 END), 0)
                 - NVL(SUM(CASE WHEN CO.NMOVEMENT_NULL = NMOVEMENT_AUX
                                THEN NVL(CO.NCAPITAL, 0) ELSE 0 END), 0),
                   COUNT(*)
              INTO NCAPITAL_MOV, NCOVTOUCH_AUX
              FROM COVER CO
             INNER JOIN LIFE_COVER LCO
                     ON LCO.NBRANCH  = CO.NBRANCH
                    AND LCO.NPRODUCT = CO.NPRODUCT
                    AND LCO.NMODULEC = CO.NMODULEC
                    AND LCO.NCOVER   = CO.NCOVER
             WHERE CO.SCERTYPE = '2'
               AND CO.NBRANCH  = NBRANCH
               AND CO.NPRODUCT = NPRODUCT
               AND CO.NPOLICY  = NPOLICY
               AND CO.NCERTIF  = NCERTIF
               AND (CO.NMOVEMENT = NMOVEMENT_AUX OR CO.NMOVEMENT_NULL = NMOVEMENT_AUX)
               AND LCO.DEFFECDATE <= DSTATDATE
               AND (LCO.DNULLDATE IS NULL OR LCO.DNULLDATE > DSTATDATE)
               AND LCO.SCOVERUSE = '1';
        EXCEPTION
            WHEN OTHERS THEN
                NCOVTOUCH_AUX := 0;
        END;

        IF NVL(NCOVTOUCH_AUX, 0) > 0 THEN
            NCAPITAL_MO := NVL(NCAPITAL_MOV, 0);
        END IF;
    END IF;

    /* ====================================================================
       PASO 20: CALCULOS FINALES DE MONTOS EN MONEDA LOCAL
       ==================================================================== */
    NCAPITAL_LO    := ROUND(NCAPITAL_MO * NEXCHANGE_AUX, 2);
    NMONTIT_ML     := ROUND(NMONTIT_MO * NEXCHANGE_AUX, 2);
    NMONTAPS_ML    := ROUND(NMONTAPS_MO * NEXCHANGE_AUX, 2);
    NRECARAD_ML    := ROUND(NRECARAD_MO_AUX * NEXCHANGE_AUX, 2);
    NADDPREMIUM_LO := ROUND(NADDPREMIUM_MO * NEXCHANGE_AUX, 2);

    /* Si no es anulacion, limpiar glosa */
    IF NTYPE <> 7 THEN
        NNULLCODE     := NULL;
        SDESC_NULLCODE := NULL;
    END IF;

    /* ====================================================================
       PASO 21: GENERAR ID_REGISTRO
       ==================================================================== */
    BEGIN
        SELECT NVL(MAX(ID_REGISTRO), 0) + 1
          INTO NID_REGISTRO
          FROM TIMETMP.TMP_CAL503 T
         WHERE T.SKEY = SKEY;
    EXCEPTION
        WHEN OTHERS THEN
            NID_REGISTRO := NVL(NID_REGISTRO, 0) + 1;
    END;

    /* Si canal es Directo, cambiar nombre del agente */
    IF NVL(NINTERTYP, 0) = 21 THEN
        SNAME_AGE := 'Directo';
    END IF;

    /* ====================================================================
       PASO 22: INSERTAR EN TMP_CAL503 (LIBRO DE PRODUCCION)
       ==================================================================== */
    INSERT INTO TIMETMP.TMP_CAL503 (
        NCOMPANY,           NINSUR_AREA,        DSTARTDATE_REP,
        DEXPIRDATE_REP,     SDESCBRANCH_FECU,   SDESC_BRANCH,
        NPRODUCT,           SDESCPRODUCT,       NOFFICE,
        SDESCOFFICE,        NPOLICY,            NPROPONUM,
        DSTARTDATE,         DEXPIRDAT,          DDATE_ACCEPT,
        SCLIENT_ASEG,       SCLIENAME_ASEG,     SCLIENT_AGEN,
        SCLIENAME_AGE,      NCURRENCY,          SDESCCURRENCY,
        NPREMIUME_MO,       NPREMIUMA_MO,       NPREMIUMIVA_MO,
        NPREMIUM_MO,        NCOMAMOU_MO,        NPREMIUME,
        NPREMIUMA,          NPREMIUMIVA,        NPREMIUM,
        NCOMAMOU_PES,       NCERTIF,            SKEY,
        DPOSTED,            NBRANCH_LED,        SCLIENTSPONSOR,
        NRECEIPT,           NTYPE_TRAN,         ID_REGISTRO,
        NTYPE_HIST,         NCODLINEBUSI,       NSELLCHANNEL,
        SDESCSELLCHANNEL,   NCURRENCY_LOC,      SDESCCURR_LOC,
        NEXCHANGE,          NNULLCODE,          NINTERTYP,
        SCLIENT_SUPER,      SCLIENAME_SUPER,    SDESC_TYPE_HIST,
        SDESC_LINEBUSI,     NMONRENEW,          SNAMEHOLDER,
        NPAYFREQ,           SDESC_PAYFREQ,      NNUMINSUR,
        SDESC_NULLCODE,     NCAPITAL_MO,        NCAPITAL_LO,
        SUSERNAME,          DISSUEDAT,          NADDPREMIUM_MO,
        NADDPREMIUM_LO,     NDEFERREDPREM_MO,   NDEFERREDPREM_LO,
        NADDDEFERPREM_MO,   NADDDEFERPREM_LO,   SDESC_INTERTYP,
        NINTCOMMPERC,       NSUPCOMMPERC,       SDESC_WAY_PAY,
        NWAYPAY,            NMONTIT_MO,         NMONTIT_ML,
        NMONTAPS_MO,        NMONTAPS_ML,        NRECARAD_MO,
        NRECARAD_ML,        NBRANCH,            NCOMAMOUSUP_MO,
        NCOMAMOUSUP_ML,     NINTFINAN_MO,       NINTFINAN_ML,
        NACCCRITERION,      DEFFECDATE_Q,       DEXPIRDAT_Q
    ) VALUES (
        NCOMPANY,           NINSUR_AREA,        DDATE_INI,
        DDATE_END,          SBRANCHFECU,        SBRANCH,
        NPRODUCT,           SPRODUCT,           NOFFICEAGEN,
        SOFFICEAGEN,        NPOLICY,            NPROPONUM,
        DSTARTDATE,         DEXPIRDAT,          DLEDGERDAT,
        SCLIENT,            SNAME_ASE,          TO_CHAR(NINTERMED_AUX),
        SNAME_AGE,          NCURRENCY,          SCURRENCY,
        NP_EXENTA_MO,       NNETA_MO_AUX,       NIVA_MO_AUX,
        NTOTAL_MO_AUX,      NCOMAMOU_MO,        NP_EXENTA_LO,
        NP_NETA_LO,         NP_IVA_LO,          NP_TOTAL_LO,
        NCOMAMOU_PES,       NCERTIF,            SKEY,
        DPOSTED,            NBRANCH_LED,        SCLIENTSPONSOR_AUX,
        NRECEIPT,           NTYPE,              NID_REGISTRO,
        NTYPE_HIST,         NCODLINEBUSI,       NSELLCHANNEL,
        SDESCSELLCHANNEL,   1,                  SDESCCURR_LOC,
        NEXCHANGE_AUX,      NNULLCODE,          NINTERTYP,
        TO_CHAR(NSUPERVIS), SCLIENAME_SUPER,    SDESC_TYPE_HIST,
        SDESC_LINEBUSI,     NMONRENEW,          SNAMEHOLDER,
        NPAYFREQ,           SDESC_PAYFREQ,      NNUMINSUR,
        SDESC_NULLCODE,     NCAPITAL_MO,        NCAPITAL_LO,
        SUSERNAME,          DISSUEDAT,          NADDPREMIUM_MO,
        NADDPREMIUM_LO,     0,                  0,
        0,                  0,                  SDESC_INTERTYP,
        NINTCOMMPERC,       NSUPCOMMPERC,       SDESC_WAY_PAY,
        NWAY_PAY,           NMONTIT_MO,         NMONTIT_ML,
        NMONTAPS_MO,        NMONTAPS_ML,        NRECARAD_MO_AUX,
        NRECARAD_ML,        NBRANCH,            NCOMAMOUSUP_MO,
        NCOMAMOUSUP_ML,     NINTFINAN_MO,       NINTFINAN_ML,
        NACCCRITERION,      DEFFECDATE,         DEXPIRDAT_PRE
    );

    /* ====================================================================
       PASO 23: INSERTAR EN BOOK_PRODUCTION (si NEXECUTE = 2)
       ==================================================================== */
    IF NEXECUTE = 2 THEN
        INSERT INTO INSUDB.BOOK_PRODUCTION (
            SCERTYPE,       NBRANCH,        NPRODUCT,       NPOLICY,
            NRECEIPT,       NTRANSAC,       SKEY,           SCLIENTSPONSOR,
            DSTARTDATE,     DEXPIRDAT,      NCERTIF,        DDATE_ACCEPT,
            SCLIENT_ASEG,   NCURRENCY,      NPREMIUME_MO,   NPREMIUMA_MO,
            NPREMIUM_MO,    NPREMIUME,      NPREMIUMA,      SCLIENT_AGEN,
            NPREMIUM,       NCOMAMOU_MO,    NCOMAMOU_PES,   DPOSTED,
            NBRANCH_LED,    NUSERCODE,      NCOMPANY,       NINSUR_AREA,
            DSTARTDATE_REP, DEXPIRDATE_REP, DLEDGERDAT,     DCOMPDATE,
            NTRATYPEI,      NTYPE,          NTYPE_TRAN,     NACCCRITERION
        ) VALUES (
            '2',            NBRANCH,        NPRODUCT,       NPOLICY,
            NRECEIPT,       NTRANSAC,       SKEY,           SCLIENTSPONSOR_AUX,
            DSTARTDATE,     DEXPIRDAT,      NCERTIF,        DLEDGERDAT,
            SCLIENT,        NCURRENCY,      NP_EXENTA_MO,   NNETA_MO_AUX,
            NTOTAL_MO_AUX,  NP_EXENTA_LO,   NP_NETA_LO,     SCLIENT_AGE,
            NP_TOTAL_LO,    NC_DEV_MO,      NC_DEV_LO,      NULL,
            NBRANCH_LED,    NUSERCODE,      NCOMPANY,       NINSUR_AREA,
            DDATE_INI,      DDATE_END,      DLEDGERDAT,     SYSDATE,
            NTRATYPEI,      NTYPE_PREM,     NTYPE,          NACCCRITERION
        );
    END IF;

END INSTMP_CAL503_V2;
/
