SELECT
    fact.ninsur_area,
    area.sdescript Area,
    fact.sbilltype, --Tipo de factura Valores fijos   1.- Afecta   2.- Exenta   3.- Nota de credito   4.- Proforma
    case fact.sbilltype when To_char(1) then 'Afecta'
                        when To_char(2) then 'Exenta'
                        when To_char(3) then 'Nota de credito'
                        else 'Proforma'
                        end As TipoFactura,
    fact.sbilling,  --Facturación Valores fijos   1.- Factura   2.- Proforma
    case fact.sbilling when to_char(1) then 'Factura' else 'Proforma' end As Facturacion,
    fact.nbillnum, -- Numero de FActura
    fact.ncurrency,
    mnda.sdescript MonedaFactura,
    fact.sclient,
    cli.scliename Client,
    fact.namount MontoTotalFactura,
    fact.namo_afec MontoAfecto,
    fact.namo_exen MontoExento,
    fact.niva MontoIva,
    fact.ncre_note,
    fact.nnewbill,
    fact.dcompdate FechaRegistro,
    fact.nusercode,
    cliUsr.scliename UsuarioRegistro,
    fact.nbillstat,
    est.sdescript EstadoDocumento,
    fact.dstatdate FechaUltimaActualizacion,
    fact.dvaldate FechaValorizacion,
    fact.skeyaddress,
    fact.nrecowner,
    fact.sbill_ind,
    fact.sorigin,
    fact.nprevbill,
    fact.dissuedat,
    fact.sbillfullnum,
    fact.sauthorization,
    fact.nrucprint,
    fact.nidtransaction,
    fact.sbillnumsfe,
    fact.nbordereaux,
    fact.npolicy,
    fact.nnullcode
FROM     bills fact
INNER JOIN Client cli on cli.sclient = fact.sclient
INNER JOIN Table5564 est On est.nbillstat= fact.nbillstat
INNER JOIN Table5001 area on area.ninsur_area= fact.ninsur_area
INNER JOIN USERS usr on usr.nusercode= fact.nusercode
INNER JOIN CLIENT cliUsr on cliUsr.sclient= usr.sclient
LEFT JOIN TABLE11 Mnda on Mnda.ncodigint=fact.ncurrency
where fact.NBordereaux= 1736