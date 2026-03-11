select  
pre.SCERTYPE as SCERTYPE
,pre.NRECEIPT As NRECEIPT 
,pre.NBRANCH as NBRANCH
,pre.NPRODUCT as NPRODUCT
,pre.NDIGIT as NDIGIT
,pre.NPAYNUMBE as NPAYNUMBE
, pre.npolicy as NroPoliza
,pre.sclient as CodCliente
,cli.sCliename as Cliente
, pre.scessions as scessions
, pre.ncertif as NCERTIF
, pre.sdirdebit As SDIRDEBIT
, pre.sleadinvo AS SLEADINVO
, pre.smanauti as IndicadorFacturaManual
, pre.srenewal as IndicadorRenovacionAutomatica
, pre.ssubstiti as IndicadorSustitucionPoliza
, pre.nstatus_pre as CodEstado
, estfac.sdescript as Estado
, pre.sconcoll as IndicadorConvenioCobranza
, pre.sstatusva as CodEstadoRegistro
, to_date(pre.dcompdate,'DD-MM-YYYY') as FechaCreacionModificacionREgistro
, to_date(pre.deffecdate,'DD-MM-YYYY') As FechaEfectoFactura
, to_date(pre.dexpirdat,'DD-MM-YYYY') AS FechaVencimientoRecibo
, to_date(pre.DISSUEDAT,'DD-MM-YYYY') As FechaEmisionFactura
, to_date(pre.dnulldate,'DD-MM-YYYY') As FechaAnulacionFactura
, to_date(pre.dpaydate,'DD-MM-YYYY') As FechaPagoFactura
, to_date(pre.dstatdate,'DD-MM-YYYY') AS FechaModEstadoActualFactura
, pre.nbalance As SaldoPendientePrima
, pre.ncomamou as MontoComisionFactura
, pre.nexchange as FactorCambioAMonedaLocal
, pre.nintammou As MontoInteresIncluidoenPago
, pre.nparticip AS POrcentajeParticipacionProductorPpal
, pre.npremium As MontoPrima
, pre.npremiuml as MontoPrimaLiquida
, pre.npremiumn as MontoPrimaNetaFactura
, pre.npremiums as MontoPrimaPolizaSustituida
, pre.nrate as PorcentajeInteresConvenio
, pre.ntaxamou As MontoImpuesto
, pre.ncollecto AS CodEncargadoCobro
, cli.scliename as EncargadoCObro
, pre.ncontrat as CodContratoFinanciamiento
, pre.ninspecto as CodInspectorCObro
, pre.nintermed as CodIntermediario
, cli.scliename as Intermediario
, pre.nsustit as NroFacturaGeneradoEnLaEmision
, pre.ntransactio as NroMovimientoTransaccion
, pre.nnullcode as CodAnulacionRecibo
, anu.sdescript as MotivoAnulacion
, pre.ncurrency as CodMoneda
, mon.sdescript  as Moneda
, pre.nnotenum as CodiNotaTextoLibreFActura
, pre.noffice as CodSucursal
, suc.sdescript as Sucursal
, pre.ntype As TipoFactura_CobroDevolucion -- Cobro o Devolucion
, pre.NTRATYPEI as CodOrigenRecibo
, tori.sdescript as OrigenRecibo_TipoCuota -- TipoCuota
, pre.nusercode as CodUsuarioCreacionModificacionRegistro
, pre.nperiod as NroCuota --Nro Cuota
, pre.ncompany as CodCompania
, pre.SORIGRECEIPT as NroREciboCompaniaSeguro -- 
, pre.NWAY_PAY as CodMetodoPago
, mpag.sdescript as MetodoPago
, to_date(pre.dlimitdate,'DD-MM-YYYY') as FechaVencimientoPago
, pre.ninsur_area as CodAreaSeguro
, arseg.sdescript as AreaSeguro
, pre.NINDRECDEP as IndicadorFactura -- Solo para vida Especial o rentas vitalicias
, to_date(pre.DCOLLSUS_INI,'DD-MM-YYYY') as FechaSuspencionCobroRecibo
, to_date(pre.DCOLLSUS_END,'DD-MM-YYYY') As FechaFinSuspencionCobroRecibo
, pre.NSUS_REASON as CodMotivoSupencion
, pre.SSUS_ORIGI as IndicadorOrigenSupencion
, pre.SREJECT as IndicadorREchazoCobro
, pre.ncollector as CodUltimoCobradorAsociado
, pre.NIDLOANS as NroPrestamoAsociadoProductor
, pre.ncod_agree
, pre.sbilltype
, pre.nbillnum as UltimoNroFactura
, pre.sindcheque
, pre.sind_cap
, pre.nbulletins
, pre.sindmargin
, pre.sind_reserv
, pre.nyearmonthdesc
, pre.nbill_day
, pre.npayfreq
, Fpago.sdescript FrecuenciaPago
, pre.sdocument
, pre.nbank_code
, pre.nsituation
, pre.nstipend_amount
, pre.ncollector_assig
, pre.npremiumtec
from PREMIUM pre 
Inner Join Client Cli on pre.sclient = cli.sclient
inner join TABLE19 EstFac on pre.nstatus_pre= estfac.nstatus_pre
inner join TABLE5632 CTyp On pre.SCERTYPE = ctyp.scertype
Inner Join Table11 Mon On pre.ncurrency = mon.ncodigint
inner join TABLE24 TOri on pre.ntratypei = tori.ntratypei

left Join Table9 Suc on pre.noffice = suc.noffice
left Join TABLE95 Anu on pre.nnullcode= anu.nnullcode
Left Join TABLE5001 ArSeg on pre.ninsur_area = arseg.ninsur_area
left Join TABLE5002 MPag on pre.nway_pay= mpag.nway_pay
left Join Table36  FPago on pre.NpayFreq= Fpago.NpayFreq
Where pre.NPolicy=1637 
and pre.scertype=2  and pre.nbranch=5 
pre.NPolicy IN (91) and pre.nreceipt=965
 
Order By pre.NRECEIPT 
