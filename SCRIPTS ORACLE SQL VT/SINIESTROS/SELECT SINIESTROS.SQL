
select * from claim where nclaim= '260500449' -- NIDPRECLAIM tiene el codigo de denuncia
select * from PRECLAIM where NIDPRECLAIM=2879
select * from CLAIM_CASE  where nclaim= '260500449'
select * from CLAIM_ORDER where nclaim= '260500449'
select * from CLAIM_SETT_ORDER WHERE NORDER_NUM=3565
select * from CLAIM_SETTlEMENT WHERE NSETTLEMENT_NUM=392
select * from CLAIM_HIS where nclaim= '260500449' order by ntransac

SELECT * FROM CL_COVER  where nclaim= '260500449'

select * from DOCUMENTS_PRECLAIM where NIDPRECLAIM=2879
select * from MASTERCL_ORDER where NMASTERORDER=3565

SELECT * FROM CL_DIAGNOSTIC 
SELECT * FROM CL_PROFSERV
select * from CLAIM_ATTM 
select * from CLAIM_MASTER 




select * from OPT_SINIES