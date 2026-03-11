select * from Premium where npolicy=2025 and scertype=2  and nbranch=5 and nproduct=700 Order by Deffecdate asc  -- ncontrat
--- ANUAL, MENSUAL
select * from PREMIUM_MO where nreceipt=30 order by Ntransac
----- CUOTAS
select * from Financ_dra where ncontrat=23 order by ndraft --248.999149
select * from DRAFT_HIST where ncontrat=23 and ndraft=1 and Ntype in (2)  order by ntransac
select * from TRELDOC WHERE nbordereaux=3776
----- 
select * from COLFORMREF where NBordereaux = 4002
SELECT * FROM CASH_MOV WHERE nbordereaux=4002 --- movieento de caja: efectivo, cheque, etc
SELECT * FROM BANK_MOV WHERE nbordereaux=4002 --- movimiento de banco: transacción bancaria


-- Tabla historica de la tabla Premium, aqui se crea una nueva tupla por cobro
select * from Premium_Mo Where nreceipt=24630 and scertype=2  and nbranch=5 and nproduct=700 
SELECT * FROM TABLE182 -- SPAY_FORM
select * from Table6 --- premium_mo.NType
select * from Premium_Ce Where nreceipt=24820 and scertype=2  and nbranch=5 and nproduct=700
select * from Detail_Pre Where nreceipt=24878 and scertype=2  and nbranch=5 and nproduct=700
---- CAJAS
select * from  USER_CASHNUM Where Ncashnum=25 -- Premium_Mo.NCASHNUM= UCash.NCASHNUM
select * from  USERS  where NUsercode= '3461'
select * from  USERS  where NUsercode= '3462' -- ON USER_CASHNUM.NUSER= USERS.NUsercode
select * from  CLIENT Where SClient = '00000000003462'

-- Al hacer un movimiento de ingreso, se crea una tupla en esta tabla
select * from COLFORMREF where NBordereaux= 1807 -- Premium_Mo.NBordereaux
select * from T_DOCTYP where NBordereaux= 1807   -- Tabla Temporal de Doc. de Cobranzas
--- Se reflejan movimientos de Transferencia bancaria
select * from BANK_MOV where NBordereaux= 1807 order by DREALDEP DESC
select * from BANK_ACC where nacc_bank=1 -- BANK_MOV.nacc_bank = BANK_ACC.nacc_bank
select * from TABLE7 where Nbank_code=5  -- BANK_ACC.Nbank_code = TABLE7.Nbank_code
select * from BANK_TRANS
-- detalle de las cuotas que se estan pagando
select * from TRELDOC Where nreceipt=24820 
-----------------------------------------------------------------------
---- Movimiento en caja - Entrada de dinero - Deposito en caja - CHEQUE
select * from CASH_MOV where  NBordereaux= 1807 --- NMOV_TYPE
select * from CASH_MOV where nreceipt=24820
select * from table78 where nmov_type=2 --  NMOV_TYPE
select * from BANK_ACC where  Nbank_code=2
select * from TABLE7 where Nbank_code=2

-- 294419
select * from Bills where NBordereaux= 1904 --2947
select * from BILLS_HIS where nbillnum in (296476)
select * from BILL_DET where nbillnum=3196
select * from TAB_BILL_I


select * from  USER_CASHNUM Where NUSER='3461' -- Premium_Mo.NCASHNUM= UCash.NCASHNUM
select * from  USERS  where NUsercode= '3461' -- ON USER_CASHNUM.NUSER= USERS.NUsercode
select * from  CLIENT Where SClient = '00000000003462'
---------------------------------------------
-- Movimientos de la cuenta corriente  (ejm. pagos en demasia)
select * from MOVE_ACC where  NBordereaux= 1807 ---NID 248274  
select * from BANK_MOV where NUSERCODE=1647 order by DEFFECDATE
select * from CHEQUE_MOV where NUSERCODE=2948 order by DEFFECDATE

select * from CHEQUE_MOV order by DEFFECDATE DESC
-----------------------------------------------------------------------

select * from Commiss_pr where nreceipt=20751
select * from Table4
select * from Out_Moveme
select * from Out_Premiu
select * from CHEQUES order by DCompdate desc
select * from COLLECT_GEN
select * from TMP_COLLECTION
select * from CHEQ_BOOK
select * from BULLETINS
select * from TAR_TRALIFE
select * from ENTRIES
 
select * from BOOK_COLLECTION where NRECEIPT=21830
select * from T_CHEQUES
select * from CHEQUES

select * from CONTRMASTER
select * from TABLE258

SELECT * FROM table78


