SELECT * FROM PREMIUM WHERE NPOLICY=1398
SELECT * FROM COLFORMREF WHERE STYPE=1

SELECT * FROM FINANC_DRA WHERE NCONTRAT=743 ORDER BY NDRAFT
SELECT * FROM BILLS WHERE nbordereaux=5143

----// PREMIUM
select p.nstatus_pre,t19.sdescript EstadoRecibo
,p.sstatusva,t181.sdescript EstadoValor
,p.ntratypei, t24.sdescript TipoCuota
,p.NTYPE, DECODE(p.NTYPE,1,'COBRO','DEVOLUCION')
,ROW_NUMBER() OVER(PARTITION BY CASE WHEN p.ntratypei = 1 THEN 9999
                                     WHEN p.ntratypei = 2 THEN 9999
                                     ELSE p.ntratypei END ORDER BY  p.deffecdate ) as NroCuota
,p.* 
from Premium p 
inner join table19 t19 on p.nstatus_pre= t19.nstatus_pre
inner join table181 t181 on p.sstatusva= t181.sstatusva
inner join table24 t24 on p.ntratypei = t24.ntratypei
where p.npolicy =1505 
and p.nstatus_pre not in (3) -- Anulado
and p.sstatusva not in (2,3)  -- Invalido, Captura Incompleta
order by p.ntratypei, p.deffecdate;

---///// PREMIUM_MO  ////
SELECT 
PO.NTYPE
,T6.SDESCRIPT TIPO_MOV
,PO.*
FROM PREMIUM_MO PO
INNER JOIN TABLE6 T6 ON PO.NTYPE = T6.NTYPE_TRAN
WHERE
po.nbordereaux=5143 
--PO.NRECEIPT IN (12824,12827)
AND PO.NTYPE NOT IN (1)
ORDER BY PO.NTRANSAC

--////// COLFORMREF     ////
SELECT
CF.STYPE
,DECODE(TRIM(CF.STYPE),'1','Conciliacion','2','DEVOLUCION DE PRIMA','3','COBRO','Indefinido') TIPO
,CF.SREL_TYPE
,T7502.SDESCRIPT TIPO_RELACION
,DECODE(TRIM(CF.SSTATUS),'1','Completa','2','Incompleta','3','Anulada','Indefinido') ESTADO
,CF.*
FROM COLFORMREF CF
INNER JOIN TABLE7502 T7502 ON CF.SREL_TYPE= T7502.SREL_TYPE
WHERE 
--CF.STYPE=3
CF.NBORDEREAUX=5143;

--//// TRELDOC      ////
SELECT TD.*
FROM TRELDOC TD
WHERE TD.NBORDEREAUX=5282;

---////// SEGUIMIENTO MENSUAL, ANUAL        ////
SELECT CF3.Nbordereaux 
            ,P.Nreceipt As Nreceipt  
            ,ROW_NUMBER() OVER(PARTITION BY CASE WHEN p.ntratypei = 1 THEN 9999
                                     WHEN p.ntratypei = 2 THEN 9999
                                     ELSE p.ntratypei END ORDER BY  p.deffecdate ) as NroCuota          
            ,P.dlimitdate AS VencimientoDeCuota
            ,ROUND(NVL(P.npremium,0),2) ImporteCuota
            ,NVL(fact.NBILLNUM,0) As NroFactura
            ,NVL(fact.DISSUEDAT,NULL) As FechaFacturaAnterior
            ,NVL(fact.NPREVBILL,0) As NroFacturaAnterior
            ,UCash.NCASHNUM As NCASHNUM
            ,INITCAP(LOWER(RTRIM(CliCaja.scliename))) Cajero
            ,EstRec.sdescript as EstadoRecibo
            ,CASE P.NTRATYPEI
                   WHEN 1 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(P.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END as TipoCuota
            ,TRIM(MPag.sdescript)  As CanalCobroRealizado            
            ,To_char(TRIM(P.NPeriod)) NPeriodo
            ,P.Ntype Ntype
            , DECODE(p.NTYPE,1,'COBRO','DEVOLUCION') TIPO_CUOTA
            ,DECODE(NVL(fact.NBILLNUM,0),0,'Recibo', DECODE(NVL(tblFA.NBILLNUM,0),0,'Factura','Factura Anticipada')) As TipoDocumento      
       FROM COLFORMREF CF3
       INNER JOIN PREMIUM_MO PO ON CF3.Nbordereaux = PO.Nbordereaux
       INNER JOIN PREMIUM P  ON PO.SCERTYPE= P.SCERTYPE
                             AND PO.NBRANCH= P.NBRANCH
                             AND PO.NPRODUCT= P.NPRODUCT
                             AND PO.NRECEIPT= P.NRECEIPT
                             AND PO.NDIGIT= P.NDIGIT
                             AND PO.NPAYNUMBE= P.NPAYNUMBE
        INNER JOIN TABLE19 EstRec ON P.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE24 TCuo ON P.NTRATYPEI= TCuo.NTRATYPEI                     
        LEFT JOIN BILLS fact ON CF3.NBordereaux = fact.NBordereaux OR PO.nbillnum= fact.nbillnum
                                AND fact.Nbillstat not in (2) -- Anulado
        LEFT JOIN USER_CASHNUM UCash ON CF3.NCASHNUM= UCash.NCASHNUM
        LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient        
        LEFT JOIN TABLE5002 MPag ON P.nway_pay= MPag.nway_pay
        LEFT JOIN TABLE6 Tipo ON PO.Ntype= tipo.ntype_tran
        OUTER APPLY (
             SELECT POAUX.NBILLNUM 
             FROM PREMIUM_MO  POAUX 
             WHERE POAUX.nreceipt = PO.nreceipt 
                    AND POAUX.NBILLNUM= PO.NBILLNUM 
                    AND POAUX.NTYPE IN (42)                   
                    AND NVL(POAUX.NNULLCODE,0)=0
        )tblFA
    WHERE 
    PO.Ntype IN (2,13,14,21,39,40) --42 FACT. ANTICIPADA; 3= devolucion de prima --> Se quitan
    AND P.nstatus_pre in (2,5,6,7)
    AND NVL(CF3.nnullcode,0)=0  
    AND CF3.STYPE NOT IN (2)
    AND CF3.Nbordereaux=5143;
    
-----/// SEGUIMIENTO FINANCIADA     ////
SELECT CF2.Nbordereaux 
            , PRE.Nreceipt As Nreceipt  
            , FDRA.Ndraft As NroCuota           
            ,  FDRA.dlimitdate  AS VencimientoDeCuota
            ,  FDRA.namount  ImporteCuota
             , fact.NBILLNUM As NroFactura
            , fact.DISSUEDAT As FechaFacturaAnterior
            , fact.NPREVBILL As NroFacturaAnterior
            , UCash.NCASHNUM As NCASHNUM
            , INITCAP(LOWER(RTRIM(CliCaja.scliename))) Cajero
            , EstRec.sdescript as EstadoRecibo
            ,  CASE PRE.NTRATYPEI
                   WHEN 1 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 2 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 3 THEN 'Anexo'
                   WHEN 4 THEN 'Anexo de resicion de contrato'
                   WHEN 9 THEN DECODE(PRE.NSTATUS_PRE, 8, 'Cuota Financiamiento ', 'Cuota Regular ')
                   WHEN 12 THEN 'Anexo de rehabilitacion'
                   ELSE TRIM(TCuo.sdescript)
              END as TipoCuota            
            , To_char(TRIM(PRE.NPeriod)) NPeriodo
            , TRIM(MPag.sdescript)  As CanalCobroRealizado 
            , PRE.Ntype Ntype       
            , DECODE(NVL(fact.NBILLNUM,0),0,'Recibo', DECODE(NVL(tblFA.NBILLNUM,0),0,'Factura','Factura Anticipada')) As TipoDocumento                       
        FROM  COLFORMREF CF2
        INNER JOIN FINANC_DRA FDRA ON CF2.NBordereaux = FDRA.NBordereaux
        INNER JOIN DRAFT_HIST DRA_HIS ON FDRA.ncontrat= DRA_HIS.ncontrat
                                         AND FDRA.NDRAFT= DRA_HIS.NDRAFT
                                         AND DRA_HIS.Ntype IN (2)
        INNER JOIN PREMIUM PRE ON FDRA.ncontrat = Pre.ncontrat
        INNER JOIN TABLE19 EstRec ON Pre.nstatus_pre= EstRec.nstatus_pre
        INNER JOIN TABLE24 TCuo ON Pre.NTRATYPEI= TCuo.NTRATYPEI                             
        LEFT JOIN BILLS fact ON FDRA.NBordereaux = fact.NBordereaux 
                                AND fact.Nbillstat not in (2) -- Anulado
        LEFT JOIN USER_CASHNUM UCash ON CF2.NCASHNUM= UCash.NCASHNUM
        LEFT JOIN USERS UsrCaja ON UCash.NUSER= UsrCaja.NUSERCODE
        LEFT JOIN CLIENT CliCaja On UsrCaja.SClient= CliCaja.SClient
        LEFT JOIN TABLE5002 MPag ON PRE.nway_pay= MPag.nway_pay   
        OUTER APPLY (
             SELECT DRA_HIS2.NBILLNUM 
             FROM DRAFT_HIST  DRA_HIS2 
             WHERE FDRA.ncontrat= DRA_HIS2.ncontrat
                   AND FDRA.NDRAFT= DRA_HIS2.NDRAFT
                   AND DRA_HIS.Ntype IN (42)             
        )tblFA         
        WHERE PRE.nstatus_pre in (8)
        AND CF2.STYPE NOT IN (2)  --- SE QUITA EGRESO-DEVOLUCION DE PRIMA   
        AND CF2.Nbordereaux =5143;