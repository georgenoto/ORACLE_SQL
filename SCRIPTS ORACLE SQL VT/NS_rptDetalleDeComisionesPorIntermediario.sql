CREATE OR REPLACE PROCEDURE NS_rptDetalleDeComisionesPorIntermediario
/*-------------------------------------------------------------------------------*/
/* NOMBRE    : NS_rptDetalleDeComisionesPorIntermediario                                        */
/* OBJETIVO  : OBTENER INFORMACIÓN DE LAS COMISIONES POR INTERMEDIARIO               			*/
/* PARAMETROS: 1 -  DFECHAHASTA     	: FECHA MINIMA DE COBRO							*/
/*             2 -  DFECHAHASTA   		: FECHA MAXIMA DE COBRO			            	*/
/*             3 -  NREGIONAL   		: CODIGO DE REGIONAL DE LA POLIZA           	*/
/*             4 -  NTIPOINTERMEDIARIO  : CODIGO DE TIPO DE INTERMEDIARIO DE LA POLIZA	*/
/*             5 -  SINTERMEDIARIO_SCAB : CODIGO SCAB DEL INTERMEDIARIO DE LA POLIZA	*/
/*             6 -  SINTERMEDIARIO 		: NOMBRE DEL INTERMEDIARIO              		*/
/*             7 -  NRAMO          		: CODIGO DE RAMO DE LA POLIZA            		*/
/*-------------------------------------------------------------------------------*/
   (DFECHADESDE     	POLICY.DISSUEDAT%TYPE,
    DFECHAHASTA     	POLICY.DISSUEDAT%TYPE,
	NREGIONAL	    	POLICY.NOFFICE%TYPE,
	NTIPOINTERMEDIARIO	INTERMEDIA.NINTERTYP%TYPE,
	SINTERMEDIARIO_SCAB INTERMEDIA.SCODAGENT_SCAB%TYPE,
	SINTERMEDIARIO		CLIENT.SLEGALNAME%TYPE,
	NRAMO		    	POLICY.NBRANCH%TYPE,
	RC1 IN OUT SYS_REFCURSOR
	) AUTHID CURRENT_USER AS

BEGIN

OPEN RC1 FOR

select 
 temp1.Anio
,temp1.Mes
,temp1.Regional
,temp1.Ramo
,temp1.Producto
,temp1.Canal
,temp1.NroPoliza
,temp1.Contratante
,temp1.NroFacturaRecibo
,temp1.FechaDePago
,temp1.FrecuenciaDePago
,temp1.NroCuota
,temp1.TipoDeAnexo
,temp1.MontoCuotaMO
,temp1.MontoCuotaML
,temp1.MontoCobradoMO
,temp1.MontoCobradoML
,temp1.PrimaTotalMO
,temp1.PrimaTotalML
,temp1.PrimaNetaCobradaMO
,temp1.PrimaNetaCobradaML
,temp1.PorcComision
--campos calculados>
/*
,cast((PrimaNetaCobradaMO*PorcComision) as number(15,2)) ComisionAPagarMO
,cast((PrimaNetaCobradaML*PorcComision) as number(15,2)) ComisionAPagarML
,cast((PrimaNetaCobradaMO*PorcComision*0.14943) as number(15,2)) ImpuestosMO
,cast((PrimaNetaCobradaML*PorcComision*0.14943) as number(15,2)) ImpuestosML
,cast(((PrimaNetaCobradaMO*PorcComision)+(PrimaNetaCobradaMO*PorcComision*0.14943)) as number(15,2)) TotalFacturarMO
,cast(((PrimaNetaCobradaML*PorcComision)+(PrimaNetaCobradaML*PorcComision*0.14943)) as number(15,2)) TotalFacturarML
*/
,temp1.ComisionAPagarMO ComisionAPagarMO
,temp1.ComisionAPagarML ComisionAPagarML
,temp1.ImpuestosMO ImpuestosMO
,temp1.ImpuestosML ImpuestosML
,cast((temp1.ComisionAPagarMO+temp1.ImpuestosMO) as number(15,2)) TotalFacturarMO
,cast((temp1.ComisionAPagarML+temp1.ImpuestosML) as number(15,2)) TotalFacturarML
--<campos calculados
,temp1.TipoIntermediario
,temp1.CodigoDelIntermediario
,temp1.Intermediario
,temp1.Supervisor
,temp1.JefeComercial
,temp1.MonedaDeLaPoliza
,temp1.TipoCambio
from (
    SELECT 
    EXTRACT(YEAR FROM pmo.DSTATDATE) Anio
    ,EXTRACT(MONTH FROM pmo.DSTATDATE) Mes
    ,regional.sdescript Regional
    ,ramo.sdescript Ramo
    ,prod.sdescript Producto
    ,Canal.SDESCRIPT Canal
    ,p.npolicy NroPoliza 
    ,NS_fnGetNombreCompletoCliente(contratante.sclient) Contratante --contratante.SCLIENAME
    ,case when pmo.NBILLNUM is null then 'R'||to_char(pmo.NRECEIPT) else 'F'||to_char(pmo.NBILLNUM) end NroFacturaRecibo
    ,pmo.DSTATDATE FechaDePago --TO-DO
    ,frecpago.sdescript FrecuenciaDePago
    ,pr.NPERIOD NroCuota --TO-DO
    ,tipoanexo.sdescript TipoDeAnexo --TO-DO
    ,cast(pr.NPREMIUM as number(15,2)) MontoCuotaMO --TO-DO
    ,cast(pr.NPREMIUM * pr.NEXCHANGE as number(15,2)) MontoCuotaML --TO-DO
    ,cast(pmo.NAMOUNT as number(15,2)) MontoCobradoMO --TO-DO
    ,case when pmo.NAMOUNT_LOC is not null then cast(pmo.NAMOUNT_LOC as number(15,2)) else cast((pmo.NAMOUNT * pmo.NEXCHANGE) as number(15,2)) end MontoCobradoML --TO-DO
    ,cast(p.NPREMIUM as number(15,2)) PrimaTotalMO --TO-DO
    ,cast((p.NPREMIUM*pr.NEXCHANGE) as number(15,2)) PrimaTotalML --TO-DO
    ,cast(pr.NPREMIUMN as number(15,2)) PrimaNetaCobradaMO --TO-DO
    ,cast(pr.NPREMIUMN*pr.NEXCHANGE as number(15,2)) PrimaNetaCobradaML --TO-DO
    --,nvl(p.NCOMMISSI,0) PorcComision --TO-DO
    ,nvl(cpr.NPERCENT,0) PorcComision --TO-DO
    ,cast(nvl(cpr.NAMOUNT,0) as number(15,2)) ComisionAPagarMO --TO-DO
    ,cast(nvl(cpr.NAMOUNT,0)*pr.NEXCHANGE as number(15,2)) ComisionAPagarML --TO-DO
    ,cast(nvl(cpr.NCOM_AFEC,0) as number(15,2)) ImpuestosMO
    ,cast(nvl(cpr.NCOM_AFEC,0)*pr.NEXCHANGE as number(15,2)) ImpuestosML
    ,ti.sdescript TipoIntermediario
    ,INTERMEDIA.SCODAGENT_SCAB CodigoDelIntermediario
    ,trim(intermediario.scliename) Intermediario
    ,trim(supervisor.scliename) Supervisor --TO-DO
    ,trim(jefecomercial.scliename) JefeComercial --TO-DO
    ,moneda.sdescript MonedaDeLaPoliza
    ,cast(pr.NEXCHANGE as decimal(15,2)) TipoCambio --TO-DO
    FROM PREMIUM pr
    inner join PREMIUM_MO pmo on PR.SCERTYPE = PMO.SCERTYPE AND PR.NBRANCH = PMO.NBRANCH AND PR.NPRODUCT = PMO.NPRODUCT
               AND PR.NRECEIPT = PMO.NRECEIPT AND PR.NDIGIT = PMO.NDIGIT AND PR.NPAYNUMBE = PMO.NPAYNUMBE
    inner join policy p on PR.SCERTYPE = p.SCERTYPE AND PR.NBRANCH = p.NBRANCH AND PR.NPRODUCT = p.NPRODUCT AND PR.NPOLICY=p.NPOLICY
    left join POLICY_HIS PH on PR.SCERTYPE=PH.SCERTYPE AND PR.NBRANCH=PH.NBRANCH AND PR.NPRODUCT=PH.NPRODUCT 
        AND PR.NRECEIPT=PH.NRECEIPT and ph.NTYPE_HIST in (11,12) 
    inner join client contratante on p.sclient=contratante.sclient
    left join TABLE6059 tipoanexo on ph.NTYPE_AMEND=tipoanexo.NTYPE_AMEND
    inner join TABLE9 regional on p.noffice=regional.noffice 
    inner join prodmaster prod on p.NBRANCH=prod.NBRANCH and p.NPRODUCT=prod.NPRODUCT 
    inner join table10 ramo on p.NBRANCH=ramo.NBRANCH
    inner join TABLE36 frecpago on p.npayfreq=frecpago.npayfreq
    left join INTERMEDIA on p.NINTERMED = INTERMEDIA.NINTERMED
    left join client intermediario on INTERMEDIA.SCLIENT = intermediario.SCLIENT
    left join INTERM_TYP ti on INTERMEDIA.NINTERTYP = ti.NINTERTYP
    OUTER APPLY(SELECT C.NSELLCHANNEl, Canal.SDESCRIPT FROM CERTIFICAT C
                INNER JOIN TABLE5532 Canal ON C.NSELLCHANNEl = Canal.NSELLCHANNEl
                WHERE p.NPOLICY=c.NPOLICY AND p.SCERTYPE=C.SCERTYPE AND p.NBRANCH=C.NBRANCH AND p.NPRODUCT=C.NPRODUCT
                AND C.NCERTIF = 0) CANAL
    outer apply(SELECT x.ncurrency from CURREN_POL X 
                WHERE p.SCERTYPE=x.SCERTYPE and p.NBRANCH=x.NBRANCH and p.NPRODUCT=x.NPRODUCT and p.NPOLICY=x.NPOLICY 
                and x.dnulldate is null and rownum=1) mon
    left join table11 moneda on mon.ncurrency=moneda.ncodigint
    left join intermedia sup on sup.NINTERMED=intermedia.NSUPERVIS and sup.NINTERTYP=5
    left join client supervisor on sup.sclient=supervisor.sclient
    outer apply (select jc.scliename 
        from DASSIGNMENT_PARTICIPANT jerarquia 
        left join intermedia jef on jerarquia.NINTERMED_P=jef.NINTERMED 
        left join client jc on jef.sclient=jc.sclient
        where sup.NINTERMED=jerarquia.NINTERMED and rownum=1) jefecomercial
    left join COMMISS_PR cpr on pr.SCERTYPE=cpr.SCERTYPE AND pr.NBRANCH=cpr.NBRANCH AND pr.NPRODUCT=cpr.NPRODUCT 
        AND pr.NRECEIPT=cpr.NRECEIPT AND pr.NDIGIT=cpr.NDIGIT AND pr.NPAYNUMBE=cpr.NPAYNUMBE AND pr.NINTERMED=cpr.NINTERMED 
    WHERE
    --PR.NTYPE=1 AND --1=cobro,2=devolucion
    PMO.NTYPE IN (2,3,12,14) --2=abono, 3=devolucion, 12=financiamiento, 14=Cargo a Cuenta Corriente 
    AND pmo.NNULLCODE is null --solo cobros no anulados
    AND PR.NDIGIT = 0
    AND PR.NPAYNUMBE = 0
    AND PR.NSTATUS_PRE not in (3,10) --solo recibos activos
    AND PR.SSTATUSVA NOT IN ('2','3') --solo registros validos
	and pr.NTRATYPEI <> 13 --origen del recibo
    AND p.scertype='2' --solo polizas 
    
    --parametros>
    AND pr.DSTATDATE BETWEEN NS_rptDetalleDeComisionesPorIntermediario.DFECHADESDE AND NS_rptDetalleDeComisionesPorIntermediario.DFECHAHASTA 
    AND p.NOFFICE=CASE WHEN NS_rptDetalleDeComisionesPorIntermediario.NREGIONAL=0 THEN p.NOFFICE ELSE NS_rptDetalleDeComisionesPorIntermediario.NREGIONAL END 
    AND INTERMEDIA.NINTERTYP=CASE WHEN NS_rptDetalleDeComisionesPorIntermediario.NTIPOINTERMEDIARIO=0 THEN INTERMEDIA.NINTERTYP ELSE NS_rptDetalleDeComisionesPorIntermediario.NTIPOINTERMEDIARIO END 
    AND nvl(INTERMEDIA.SCODAGENT_SCAB,'0')=CASE WHEN NS_rptDetalleDeComisionesPorIntermediario.SINTERMEDIARIO_SCAB is null 
        THEN nvl(INTERMEDIA.SCODAGENT_SCAB,'0') ELSE NS_rptDetalleDeComisionesPorIntermediario.SINTERMEDIARIO_SCAB END 
    AND 1=CASE WHEN NS_rptDetalleDeComisionesPorIntermediario.SINTERMEDIARIO='' 
        THEN 1 ELSE NS_fnBusquedaInteligente(intermediario.SCLIENAME,NS_rptDetalleDeComisionesPorIntermediario.SINTERMEDIARIO) END 
    AND p.NBRANCH=CASE WHEN NS_rptDetalleDeComisionesPorIntermediario.NRAMO=0 THEN p.NBRANCH ELSE NS_rptDetalleDeComisionesPorIntermediario.NRAMO END
    
	--<parametros
    ORDER BY ti.sdescript,Intermediario
) temp1;

--dbms_sql.return_result(rc1);

END NS_rptDetalleDeComisionesPorIntermediario;