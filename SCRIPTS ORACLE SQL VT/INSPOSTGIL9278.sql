create or replace PROCEDURE INSPOSTGIL9278
/*----------------------------------------------------------------------------*/
/* NOMBRE INSPOSTGIL9278. INSPOSTGIL9278                                                    */
/* OBJETIVO INSPOSTGIL9278.                                                                 */
/* PARAMETROSINSPOSTGIL9278.                                                                */
/*                                                                            */
/* SOURCESAFE INFORMATIONINSPOSTGIL9278.                                                    */
/* $AUTHORINSPOSTGIL9278. nceijas $                                                         */
/* $DATEINSPOSTGIL9278. 08/05/2023 16INSPOSTGIL9278.00 PM $                                               */
/* $REVISIONINSPOSTGIL9278. $                                                               */
/*----------------------------------------------------------------------------*/

  (SKEY                T_INTERFACE.SKEY%TYPE        ,
   NSHEET              MASTERSHEET.NSHEET%TYPE      ,
   NUSERCODE           MASTERSHEET.NUSERCODE%TYPE   ,
   DINIDATE            DATE                         ,
   DENDDATE            DATE                         ,
   NOFFICE             TABLE9.NOFFICE%TYPE          ,
   SPOLITYPE           POLICY.SPOLITYPE%TYPE        ,
   NBRANCH             POLICY.NBRANCH%TYPE          ,
   NPRODUCT            POLICY.NPRODUCT%TYPE         ,
   NINTERTYP           INTERM_TYP.NINTERTYP%TYPE    ,
   NINTERMED           INTERMEDIA.NINTERMED%TYPE    ,
   NSELLCHANNEL        CERTIFICAT.NSELLCHANNEL%TYPE ,
   NERROR          OUT T_ERR_INTERFACE.NERROR%TYPE  ,
   SERRORDESC      OUT VARCHAR2                     ) AUTHID CURRENT_USER AS

BEGIN

    DELETE TMP_INT9278 WHERE SKEY != INSPOSTGIL9278.SKEY;
    
    COMMIT;

    INSERT INTO TMP_INT9278 (SKEY          , NOFFICE        , SDESOFFICE            , NOFFICEAGEN               , SDESOFFICEAGEN  ,
                             SPOLITYPE     , SDESPOLITYPE   , NSELLCHANNEL          , SDESSELLCHANNEL           , NBRANCH         ,
                             SDESBRANCH    , SSTATUSVA      , SDESSTATUSVA          , DISSUEDAT                 , DSTARTDATE      ,
                             DEXPIRDAT     , NPREMIUM       , NPRODUCT              , SDESPRODUCT               , NPOLICY         ,
                             SCLIENT_C     , SCLIENAME_C    , SCLIENT_A             , SCLIENAME_A               , NCOUNT_ASEG     ,
                             DPAYDATE      , DEXPIRDAT_P    , NDAYS_PAST            , NRECEIPT                  , STRATYPEI       ,
                             NRECEIPT_A    , SDESPAYFREQ    , SDESSTATUS_PRE        , NPREMIUM_USD              , NPREMIUM_PAY    ,
                             NBALANCE      , SDESSPAY_FORM  , SDESWAY_PAY           , SADDRE                    , SPHONE_L        ,
                             SPHONE_C      , SADDRESS       , SPHONE_C_C            , SE_MAIL                   , SCLIENAME_C_P   ,
                             SCLINUMDOCU_C , SCLIENAME_SR   , SCLIENAME_I           , SDESINTERTYP              , DCOLLECT        ,
                             DISSUEDAT_F   , NBILLNUM       , NRECEIPT_P            , SDESTYPE_TRAN             , DEFFECDATE_MOV  ,
                             SBANK_CODE    , SACC_NUMBER    , SDEP_NUMBER           , SCLIENAME_I_P             , SCLIENAME_CA    ,
                             SCLIENAME_CO  , DCOLLSUS_END   , NDAYS_COUT_PAST       , NPOLICY_PAST              , NCOUT_PENDING   ,
                             SRANGE_PAST   , SNWAY_PAY_LAST , SNWAY_PAY_PENULTIMATE , SNWAY_PAY_ANTEPENULTIMATE )
                    SELECT DISTINCT INSPOSTGIL9278.SKEY, 
                                    P.NOFFICE AS "CODIGO_REGIONAL",
                                    REAGENERALPKG.REACODIGINT('TABLE9','NOFFICE',P.NOFFICE) AS "REGIONAL",
                                    P.NOFFICEAGEN AS "CODIGO_OFICINA",
                                    REAGENERALPKG.REACODIGINT('TABLE5556','NOFFICEAGEN',P.NOFFICEAGEN) AS "OFICINA",
                                    P.SPOLITYPE AS "CODIGO_LINEA_NEGOCIO",
                                    REAGENERALPKG.REACODIGINT('TABLE17','NCODIGINT',P.SPOLITYPE) AS "LINEA_NEGOCIO",
                                    C.NSELLCHANNEL AS "CODIGO_CANAL_DE_VENTA",
                                    REAGENERALPKG.REACODIGINT('TABLE5532','NSELLCHANNEL',C.NSELLCHANNEL) AS "CANAL_DE_VENTA",
                                    P.NBRANCH AS "CODIGO_RRAMO",
                                    REAGENERALPKG.REACODIGINT('TABLE10','NBRANCH',P.NBRANCH) AS "RAMO",
                                    C.SSTATUSVA AS "CODIGO_ESTADO_POLIZA",
                                    REAGENERALPKG.REACODIGINT('TABLE181','SSTATUSVA',C.SSTATUSVA) AS "ESTADO_POLIZA",
                                    P.DISSUEDAT AS "FECHA_EMISION",
                                    C.DSTARTDATE AS "INICIO_VIGENCIA",
                                    C.DEXPIRDAT AS "TERMINA_VIGENCIA",
                                    PR.NPREMIUM AS "PRIMA_TOTAL",
                                    P.NPRODUCT AS "CODIGO_PRODUCTO",
                                    REAGENERALPKG.REASPRODUCT(P.NBRANCH,P.NPRODUCT) AS "PRODUCTO",
                                    P.NPOLICY AS "NRO_POLIZA",
                                    RO.SCLIENT AS "CODIGO_CONTRATANTE",
                                    REAGENERALPKG.REANAMECLI(RO.SCLIENT) AS "CONTRATANTE",
                                    RO2.SCLIENT AS "CODIGO_LISTA_ASEG_VIGENTE",
                                    REAGENERALPKG.REANAMECLI(RO2.SCLIENT) AS "DESCRIPCION_LISTA_ASEG_VIGENTE",
                                    (SELECT COUNT( DISTINCT RO3.NROLE)
                                       FROM ROLES RO3
                                      WHERE RO3.SCERTYPE = PR.SCERTYPE
                                        AND RO3.NBRANCH  = PR.NBRANCH
                                        AND RO3.NPRODUCT = PR.NPRODUCT
                                        AND RO3.NPOLICY  = PR.NPOLICY
                                        AND RO3.NCERTIF  = PR.NCERTIF
                                        AND RO3.NROLE    IN (2,3,21,22,23,24,27,28,29,30,33,67,68)
                                        AND RO3.DEFFECDATE >= INSPOSTGIL9278.DINIDATE
                                        AND (RO3.DNULLDATE IS NULL
                                         OR RO3.DNULLDATE <= INSPOSTGIL9278.DENDDATE)) AS "CANTIDAD_DE_ASEGURADOS_VIGENTES",
                                        (SELECT DPAYDATE
                                          FROM PREMIUM PR2
                                         WHERE PR2.SCERTYPE  = C.SCERTYPE
                                           AND PR2.NBRANCH   = C.NBRANCH
                                           AND PR2.NPRODUCT  = C.NPRODUCT
                                           AND PR2.NPOLICY   = C.NPOLICY
                                           AND PR2.NRECEIPT  = (SELECT MAX(NRECEIPT)
                                                                  FROM PREMIUM PR3
                                                                 WHERE PR3.SCERTYPE  = C.SCERTYPE
                                                                   AND PR3.NBRANCH   = C.NBRANCH
                                                                   AND PR3.NPRODUCT  = C.NPRODUCT
                                                                   AND PR3.NPOLICY   = C.NPOLICY
                                                                   AND PR3.NSTATUS_PRE = 2
                                                                   AND PR3.NRECEIPT  < (SELECT /*+ INDEX (PREMIUM XDELPREMIUM) */
                                                                                           MAX(NRECEIPT)
                                                                                      FROM PREMIUM PR4
                                                                                     WHERE PR4.SCERTYPE    = C.SCERTYPE
                                                                                       AND PR4.NBRANCH     = C.NBRANCH
                                                                                       AND PR4.NPRODUCT    = C.NPRODUCT
                                                                                       AND PR4.NPOLICY     = C.NPOLICY
                                                                                       AND PR4.NCERTIF     = C.NCERTIF
                                                                                       AND PR4.NSTATUS_PRE = 2))) AS "FECHA_ULTIMO_PAGO",
                                    PR.DEXPIRDAT AS "FECHA_VENCIMIENTO_CUOTA",
                                    cast(PR.DEXPIRDAT - PR.DLIMITDATE as number(10)) as "DIAS_MORA",
                                    PR.NRECEIPT AS "NRO_CUOTA",
                                    CASE WHEN PR.NTRATYPEI >= 3 THEN 'Anexos'
                                         WHEN PR.NTRATYPEI >= 1 THEN 'Cuota'
                                         ELSE 'Regular'
                                    end AS "TIPO_CUOTA",
                                    DECODE(PR.NTRATYPEI, 3, PR.NRECEIPT, NULL) AS "NRO_ANEXO",
                                    REAGENERALPKG.REACODIGINT('TABLE36','NPAYFREQ',P.NPAYFREQ) AS "PERIODICIDAD_PAGO",
                                    REAGENERALPKG.REACODIGINT('TABLE19','NSTATUS_PRE',PR.NSTATUS_PRE) AS "ESTADO_CUOTA",
                                    PR.NPREMIUM AS "MONTO_CUOTA_USD",
                                    DECODE(PR.NSTATUS_PRE,2,PR.NPREMIUM,NULL) AS "MONTO_PAGADO_CUOTA",
                                    PR.NBALANCE AS "SALDO_ACTUAL_CUOTA",
                                    REAGENERALPKG.REACODIGINT('TABLE182','SPAY_FORM',MO.SPAY_FORM) AS "FORMA_PAGO",
                                    REAGENERALPKG.REACODIGINT('TABLE5002','NWAY_PAY',PR.NWAY_PAY) AS "CANAL_DE_PAGO",
                                    REAGENERALPKG.REAADDBILLS_2(2,2||PR.SCLIENT,TRUNC(SYSDATE)) AS "DIRECCION_COBRANZAS",               
                                    REAGENERALPKG.REAPHONES1(2,2||PR.SCLIENT,1,TRUNC(SYSDATE)) AS "TELEFONO_COBRANZAS",
                                    REAGENERALPKG.REAPHONES1(2,2||PR.SCLIENT,1,TRUNC(SYSDATE)) AS "CELULAR_COBRANZAS",
                                    REAGENERALPKG.REAADDRESS_KEY_2(2,2||RO.SCLIENT,TRUNC(SYSDATE)) AS "DIRECCION",
                                    REAGENERALPKG.REAPHONES1(2,2||RO.SCLIENT,1,TRUNC(SYSDATE)) AS "TELÉFONO",
                                    (SELECT TRIM(AD.SE_MAIL)
                                       FROM ADDRESS      AD
                                      WHERE AD.NRECOWNER = 2
                                        AND AD.SCLIENT = RO.SCLIENT
                                        AND AD.DNULLDATE IS NULL
                                        AND AD.DEFFECDATE   <= TRUNC(SYSDATE)
                                        AND (AD.DNULLDATE   IS NULL
                                         OR AD.DNULLDATE     > TRUNC(SYSDATE))
                                        AND ROWNUM = 1) AS "EMAIL",
                                    REAGENERALPKG.REANAMECLI(RO.SCLIENT) AS "PERSONA_ENCARGADA_DEL_PAGO",
                                    (SELECT SCLINUMDOCU 
                                       FROM CLIDOCUMENTS CLI
                                      WHERE CLI.NTYPCLIENTDOC = 3
                                        AND CLI.SCLIENT = RO.SCLIENT
                                        AND ROWNUM = 1) AS "NIT_CONTRATANTE",
                                    REAGENERALPKG.REANAMECLI(RO.SCLIENT) AS "RAZÓN_SOCIAL",
                                    REAGENERALPKG.REANAMECLI(I.SCLIENT) AS "NOMBRE_INTERMEDIARIO",
                                    IT.SDESCRIPT AS "TIPO_INTERMEDIARIO",
                                    (SELECT COL.DCOLLECT 
                                       FROM COLFORMREF COL
                                      WHERE COL.NBORDEREAUX = MO.NBORDEREAUX) AS "FECHA_COBRO",
                                    PR.DISSUEDAT AS "FECHA_FACTURACIÓN",
                                    MO.NBILLNUM "NRO_FACTURA",
                                    PR.NRECEIPT AS "NRO_RECIBO",
                                    DECODE(MO.NTYPE,2,REAGENERALPKG.REACODIGINT('TABLE6','NTYPE_TRAN',MO.NTYPE),NULL) AS "TIPO_COBRO",
                                    (SELECT CM.DEFFECDATE
                                       FROM CASH_MOV CM
                                      WHERE CM.NBORDEREAUX = MO.NBORDEREAUX) AS "FECHA_DEPOSITO",
                                    (SELECT REAGENERALPKG.REACODIGINTSH('TABLE7','NBANK_CODE', BA.NBANK_CODE)  
                                       FROM CASH_MOV CM2, BANK_ACC BA
                                      WHERE CM2.NBORDEREAUX = MO.NBORDEREAUX
                                        and BA.NACC_BANK = CM2.NACC_BANK) AS "ENTIDAD_BANCARIA",
                                    (SELECT BA.SACC_NUMBER  
                                       FROM CASH_MOV CM2, BANK_ACC BA
                                      WHERE CM2.NBORDEREAUX = MO.NBORDEREAUX
                                        AND BA.NACC_BANK = CM2.NACC_BANK) AS "NRO_CUENTA_TARJETA",
                                    (SELECT CM3.SDEP_NUMBER
                                       FROM CASH_MOV CM3
                                      WHERE CM3.NBORDEREAUX = MO.NBORDEREAUX) AS "NRO_COMPROBANTE",
                                    REAGENERALPKG.REANAMECLI(I.SCLIENT) AS "NOMBRE_INTERMEDIARIO",
                                    REAGENERALPKG.REANAMECLI(CR.SCLIENT) AS "CAJERO",
                                    REAGENERALPKG.REANAMECLI(CR2.SCLIENT) AS "COBRADOR_ASIGNADO",
                                    PR.DCOLLSUS_END as "FECHA_DE_PRORROGA",
                                    CAST(PR.DEXPIRDAT - PR.DLIMITDATE AS NUMBER(10)) as "DIAS_MORA_CUOTA",
                                    ((SELECT PR4.DEXPIRDAT
                                       FROM PREMIUM PR4
                                      WHERE PR4.NRECEIPT = (select min(PR5.NRECEIPT) 
                                                         from PREMIUM PR5
                                                        where PR5.SCERTYPE = C.SCERTYPE
                                                          AND PR5.NBRANCH  = C.NBRANCH
                                                          AND PR5.NPRODUCT = C.NPRODUCT
                                                          AND PR5.NPOLICY  = C.NPOLICY
                                                          AND PR5.NCERTIF  = C.NCERTIF
                                                          AND PR5.NSTATUS_PRE IN (1))) -
                                    (SELECT PR6.DLIMITDATE
                                       FROM PREMIUM PR6
                                      WHERE PR6.NRECEIPT = (select MAX(PR7.NRECEIPT) 
                                                         from PREMIUM PR7
                                                        where PR7.SCERTYPE = C.SCERTYPE
                                                          AND PR7.NBRANCH  = C.NBRANCH
                                                          AND PR7.NPRODUCT = C.NPRODUCT
                                                          AND PR7.NPOLICY  = C.NPOLICY
                                                          AND PR7.NCERTIF  = C.NCERTIF
                                                          AND PR7.NSTATUS_PRE IN (1)))) AS "MORA_POLIZA",
                                    (SELECT COUNT(*)
                                       FROM PREMIUM PR8
                                      WHERE PR8.SCERTYPE = C.SCERTYPE
                                                          AND PR8.NBRANCH  = C.NBRANCH
                                                          AND PR8.NPRODUCT = C.NPRODUCT
                                                          AND PR8.NPOLICY  = C.NPOLICY
                                                          AND PR8.NCERTIF  = C.NCERTIF
                                                          AND PR8.NSTATUS_PRE IN (1)) AS "CANTIDAD_CUOTAS_PENDIENTES",
                                    CASE WHEN PR.DEXPIRDAT - PR.DLIMITDATE >= 0 AND PR.DEXPIRDAT - PR.DLIMITDATE <= 29 THEN '0-30'
                                         WHEN PR.DEXPIRDAT - PR.DLIMITDATE >= 30 AND PR.DEXPIRDAT - PR.DLIMITDATE <= 59 THEN '30-60'
                                         WHEN PR.DEXPIRDAT - PR.DLIMITDATE >= 60 AND PR.DEXPIRDAT - PR.DLIMITDATE <= 119 THEN '60-120'
                                         WHEN PR.DEXPIRDAT - PR.DLIMITDATE >= 120 THEN '120 o Mas'
                                    END AS "RANGO_MORA",
                                    REAGENERALPKG.REACODIGINT('TABLE5002','NWAY_PAY',PR.NWAY_PAY) AS "ULTIMA_MEDIO_DE_PAGO",
                                    REAGENERALPKG.REACODIGINT('TABLE5002','NWAY_PAY',PR.NWAY_PAY) AS "PENÚLTIMA_MEDIO_DE_PAGO",
                                    REAGENERALPKG.REACODIGINT('TABLE5002','NWAY_PAY',PR.NWAY_PAY) AS "ANTEPENÚLTIMA_MEDIO_DE_PAGO"
                      FROM POLICY P
                     INNER JOIN CERTIFICAT C
                        ON C.SCERTYPE = P.SCERTYPE
                       AND C.NBRANCH  = P.NBRANCH
                       AND C.NPRODUCT = P.NPRODUCT
                       AND C.NPOLICY  = P.NPOLICY
                       AND (C.NSELLCHANNEL = INSPOSTGIL9278.NSELLCHANNEL
                        OR NVL(INSPOSTGIL9278.NSELLCHANNEL,0) = 0)
                     INNER JOIN INTERMEDIA I
                        ON I.NINTERMED = P.NINTERMED
                       AND (I.NINTERTYP = INSPOSTGIL9278.NINTERTYP
                        OR NVL(INSPOSTGIL9278.NINTERTYP,0) = 0)
                     INNER JOIN INTERM_TYP IT
                        ON IT.NINTERTYP = I.NINTERTYP
                     INNER JOIN PREMIUM PR
                        ON PR.SCERTYPE = C.SCERTYPE
                       AND PR.NBRANCH  = C.NBRANCH
                       AND PR.NPRODUCT = C.NPRODUCT
                       AND PR.NPOLICY  = C.NPOLICY
                       AND PR.NCERTIF  = C.NCERTIF
                       AND PR.NSTATUS_PRE IN (1,2)
                       AND PR.DEFFECDATE >= INSPOSTGIL9278.DINIDATE
                       AND (PR.DEXPIRDAT IS NULL
                        OR PR.DEXPIRDAT  <= INSPOSTGIL9278.DENDDATE)
                       AND PR.DEXPIRDAT <= INSPOSTGIL9278.DENDDATE
                     INNER JOIN PREMIUM_MO MO
                        ON MO.SCERTYPE = PR.SCERTYPE
                       AND MO.NBRANCH  = PR.NBRANCH
                       AND MO.NPRODUCT = PR.NPRODUCT
                       AND MO.NRECEIPT  = PR.NRECEIPT
                     INNER JOIN ROLES RO
                        ON RO.SCERTYPE = C.SCERTYPE
                       AND RO.NBRANCH  = C.NBRANCH
                       AND RO.NPRODUCT = C.NPRODUCT
                       AND RO.NPOLICY  = C.NPOLICY
                       AND RO.NCERTIF  = C.NCERTIF
                       AND RO.NROLE    = 1
                       AND RO.DEFFECDATE >= INSPOSTGIL9278.DINIDATE
                       AND (RO.DNULLDATE IS NULL
                        OR RO.DNULLDATE <= INSPOSTGIL9278.DENDDATE)
                     INNER JOIN ROLES RO2
                        ON RO2.SCERTYPE = C.SCERTYPE
                       AND RO2.NBRANCH  = C.NBRANCH
                       AND RO2.NPRODUCT = C.NPRODUCT
                       AND RO2.NPOLICY  = C.NPOLICY
                       AND RO2.NCERTIF  = C.NCERTIF
                       AND RO2.NROLE    = 2
                       AND RO2.DEFFECDATE >= INSPOSTGIL9278.DINIDATE
                       AND (RO2.DNULLDATE IS NULL
                        OR RO2.DNULLDATE <= INSPOSTGIL9278.DENDDATE)
                    LEFT JOIN COLLECTOR CR
                        ON CR.NCOLLECTOR = PR.NCOLLECTO
                    LEFT JOIN COLLECTOR CR2
                        ON CR2.NCOLLECTOR = PR.NCOLLECTOR_ASSIG
                     WHERE (P.NBRANCH = INSPOSTGIL9278.NBRANCH
                        OR NVL(INSPOSTGIL9278.NBRANCH,0) = 0)
                       AND (P.NPRODUCT = INSPOSTGIL9278.NPRODUCT
                        OR NVL(INSPOSTGIL9278.NPRODUCT,0) = 0)
                       AND (P.SPOLITYPE = INSPOSTGIL9278.SPOLITYPE
                        OR NVL(INSPOSTGIL9278.SPOLITYPE,0) = 0)
                       AND (P.NOFFICE = INSPOSTGIL9278.NOFFICE
                        OR NVL(INSPOSTGIL9278.NOFFICE,0) = 0)
                       AND (P.NINTERMED = INSPOSTGIL9278.NINTERMED
                        OR NVL(INSPOSTGIL9278.NINTERMED,0) = 0);

        COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        NERROR := SQLCODE;
        SERRORDESC := SQLERRM;
        cretrace2($$PLSQL_UNIT, 1240, 'NERROR '||NERROR||' '||'SERRORDESC '||SERRORDESC);
END INSPOSTGIL9278;