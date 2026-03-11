select  
PRE_MO.NRECEIPT As NRECEIPT 
,PRE_MO.NPRODUCT as NPRODUCT
,PRE_MO.NBRANCH as NBRANCH
,PRE_MO.SCERTYPE as SCERTYPE
,ctyp.sdescript as TipoRegistro
,PRE_MO.NDIGIT as DigitoControlREcibos
,PRE_MO.NPAYNUMBE as NumeroConvenioPagoFactura
,PRE_MO.NTRANSAC as NumeroTransaccion
,PRE_MO.NAMOUNT as MontoPrimaMovimiento
,PRE_MO.NCARD_TYPE as CodTarjetaCredito
,tcre.sdescript as TarjetaCredito
,PRE_MO.SAUX_ACCOUN as CodAuxCompelementoCuenta
,PRE_MO.NBALANCE as BalancePendienteFactura
,PRE_MO.NBANK_CODE --as CodBanco
,PRE_MO.NBORDEREAUX as CodNumeroRelacionCobro
,to_date(PRE_MO.DCAR_DATEXP,'DD-MM-YYYY') as FecVencimientoTarjetaCredito
,PRE_MO.SCARD_NUM as NumeroTarjetaCredito
,PRE_MO.NCASH_MOV as NroMovimientoCaja_Transaccion
,PRE_MO.NCASHNUM as NroCaja_Transaccion

,PRE_MO.NCAUSE_AMEN as CodMofificacionRecibo
,PRE_MO.SCESSICOI as IndicadorCesionCoaseguro
,PRE_MO.SCHANG_ACC as CodCuentaContablePorCanje
,to_date(PRE_MO.DCOMPDATE,'DD-MM-YYYY') as FechaRegistro
,PRE_MO.NCURRENCY --as CodigoMoneda
,mon.sdescript as MonedaTransaccion
,PRE_MO.SDOCNUMBE as NroDocumentoFisicoDelMovimiento
,PRE_MO.SIND_REVER as IndicadorMovimientoReversado
,PRE_MO.NINT_MORA as MontoInteresMora
,PRE_MO.SINTERMEI as IndicadorPRocesadoComisiones
,PRE_MO.NNULLCODE as CodAnulacionRecibo
,anu.sdescript as MotivoAnulacion
,PRE_MO.SPAY_FORM --as CodFormaPago
,fpago.sdescript as FormaPAgo
,to_date(PRE_MO.DPOSTED,'DD-MM-YYYY') as FechaRegistroContabilizacion
,PRE_MO.NPREMIUM as MOntoPrima
,PRE_MO.NRECEIPT_FA as NumeroReciboImpresionFactura
,to_date(PRE_MO.DSTATDATE,'DD-MM-YYYY') as FechaEstadoActuaFActura
,PRE_MO.SSTATISI as IndicadorPasadoAEstadisticas
,PRE_MO.NUSERCODE as CodUsuarioModificacionRegistro
,to_date(PRE_MO.DLEDGERDAT,'DD-MM-YYYY') as FEchaContabilizacion
,PRE_MO.NTYPE --As PRE_MO.NTYPE
,tipo.sdescript As TipoMovimiento
,PRE_MO.NEXCHANGE as FactorCambioaMonedaLocal
,PRE_MO.SINDASSOCPRO as IndicadorPRocesoCuentaCorriente
,PRE_MO.NPAYSOONDISC as MontoDescuento
,PRE_MO.SIND_ASIS AS IndicadorCCASistente
,PRE_MO.SIND_COMI as IndicadorCCProductores
,PRE_MO.NBULLETINS as CodAvisoCobro

,PRE_MO.NPAYREJECT as CodRechazo
,PRE_MO.NCOLLECTOR as CodCobrador
,CliCob.sCliename as Cobrador
,PRE_MO.NBILLNUM as NroFactura
,PRE_MO.SBILLTYPE as CodTipoFactura
,PRE_MO.SIND_SOAP as IndicadorCCSoat
,PRE_MO.SINDCHEQUE as IndicadorPagoChequeFechaFutura
,PRE_MO.NID as NroConsecutivoRegistro
,PRE_MO.NRELRECEIPT
,PRE_MO.SPROCESS_IND as IndicadorMovimiento -- //1:Afirmativo 2: Negativo
,PRE_MO.SSTIPENDS as IndicadorCCEstipendio
,PRE_MO.NPAY_SOURCE as CodOrigenRecaudacion
,ori.sdescript as OrigenRecaudacion
,PRE_MO.STYPREVERSE as CodTipoReverso
,PRE_MO.NAMOUNT_LOC as MontoMonedaLocal
,PRE_MO.NCOD_AGREE as CodConvenioDescuento
,PRE_MO.NCONTRAT 
,PRE_MO.DCTB_DATE
,PRE_MO.SPOSTEDSEQUENCE
,PRE_MO.NCOLLECTOR_ASSIG as CodCobradorAsignado


from PREMIUM_MO PRE_MO 
INNER JOIN TAble6 Tipo on PRE_MO.Ntype= tipo.ntype_tran
inner join TABLE5632 CTyp On PRE_MO.SCERTYPE = ctyp.scertype
Inner Join Table11 Mon On PRE_MO.ncurrency = mon.ncodigint
left Join TABLE183 TCre on PRE_MO.NCARD_TYPE = Tcre.NCARD_TYPE
left Join TABLE95 Anu on PRE_MO.nnullcode= anu.nnullcode
left Join TABLE182 Fpago on PRE_MO.spay_form= fpago.spay_form
left Join COLLECTOR CodCob on PRE_MO.ncollector= codcob.ncollector
Left Join Client CliCob on codcob.sclient = clicob.sclient
left Join TABLE5803 Ori on PRE_MO.npay_source = ori.npay_source

Where PRE_MO.nreceipt=23919 and PRE_MO.scertype=2  and PRE_MO.nbranch=5 and PRE_MO.nproduct=700
--AND PRE_MO.Ntype IN (2,12,14)
order by PRE_MO.NTransac
