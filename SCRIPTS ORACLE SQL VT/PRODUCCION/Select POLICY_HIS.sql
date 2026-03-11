select 
	Polhis.SCERTYPE  SCERTYPE
    ,ctyp.sdescript as TipoRegistro
	,Polhis.NBRANCH As NBRANCH
	,Polhis.NPRODUCT AS NPRODUCT
	,Polhis.NPOLICY  As NPOLICY
	,Polhis.NCERTIF  As NCERTIF
	,Polhis.NMOVEMENT  As NroMovimiento
	,to_date(Polhis.DCOMPDATE,'DD-MM-YYYY')  As FechaRegistro
	,Polhis.NCLAIM as CodSiniestro
	,Polhis.NCURRENCY as CodMonenda
    ,mon.sdescript as Moneda
	,to_date(Polhis.DEFFECDATE,'DD-MM-YYYY')  As FechaEfectoRegistro
	,Polhis.SNULL_MOVE  AS MovimientoAnulado
	,to_date(Polhis.DNULLDATE,'DD-MM-YYYY')  As FechaAnulacion
	,Polhis.NRECEIPT  AS NroFacturaoMovimientoPendiente_Colectivo
	,Polhis.NTRANSACTIO  AS NroTransaccionMovimiento
	,Polhis.NTYPE_HIST  AS CodTipoTransaccion
    ,thit.sdescript AS TipoTransaccion
	,Polhis.NUSERCODE  As CodUsuarioUltimoMovimiento
	,to_date(Polhis.DLEDGERDAT ,'DD-MM-YYYY')  As FechaContabilizacion 
	,Polhis.NOFICIAL_P  As NroPolizaLegal
	,Polhis.NTYPE_AMEND As  CodEndoso_Anexo
    , tane.sdescript As TipoEndoso_Anexo
	,Polhis.NSERV_ORDER As CodOrdenServicio_Siniestro
	,Polhis.NNOTENUM As NroNotaAsociadaMovimiento
	,Polhis.SINTERMEI As IndicadorProcesadoComisionesIntermediario
	,to_date(Polhis.DFER ,'DD-MM-YYYY')  As FEchaEndosoRetreactivo
	,Polhis.NPROPONUM  As NroSolicitudOrigen
	,Polhis.NAGENCY as CodAgenciaOrigen
	,Polhis.NWAIT_CODE  as NWAIT_CODE
	,Polhis.NSTATQUOTA  AS CodEstadoCotizacionSolicitud
    , estsol.sdescript AS EstadoCotizacionSolicitud
	,Polhis.NNO_CONVERS  As CodCausaNoConversion
	,Polhis.NCARTPOL  As NCARTPOL
	,Polhis.NNUMCART As NNUMCART
	,Polhis.NPOLREF  As NroPolizaOrigen
	,Polhis.NCERREF  As CertificadoOrigen
	,Polhis.NPAYFREQ  As CodFrecuenciaPago
	,Polhis.NNULLCODE  As CodAnulacion
	,Polhis.SFILE_REPORT  
	,Polhis.SPROCESS_NUM  
	,Polhis.DSTARPROCESS 
	,Polhis.DENDPROCESS 
	,Polhis.SIND_TRANFER 
	,Polhis.SKEY  AS ClaveOrigen
	,Polhis.NSYSTEM AS COdSistemaIntegrado
	,Polhis.SLOT  As DescripcionLote
	,Polhis.NWAY_PAY  As CodViaPago
	,Polhis.NBILL_DAY  As DiaPagoRecibo
	,Polhis.NCOD_AGREE  As CodConvenio
	,Polhis.NNUMCERT  As NroCertificadoDJ1889

From POLICY_HIS Polhis
inner join TABLE5632 CTyp On Polhis.SCERTYPE = ctyp.scertype
inner join TABLE165 THit on Polhis.NTYPE_HIST = THit.NTYPE_HIST
Left Join Table11 Mon On Polhis.ncurrency = mon.ncodigint
Left Join TYPE_AMEND TAne on Polhis.nbranch =tane.nbranch and polhis.nproduct= tane.nproduct And polhis.NTYPE_AMEND= tane.NTYPE_AMEND
Left Join PROF_ORD OrdSer on polhis.nserv_order= ordser.nserv_order
Left Join TABLE5526 EstSol On polhis.nstatquota= estsol.nstatquota
Where Polhis.npolicy=1537 
--and Polhis.scertype=2  and Polhis.nbranch=5 and Polhis.nproduct=700
Order by Polhis.NMOVEMENT
