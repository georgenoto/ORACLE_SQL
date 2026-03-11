select * from Policy where npolicy=1946
--------------------------------------------------------
select * from Policy where npolicy=1598 and scertype=2  and nbranch=5 and nproduct=700
select * from Certificat where npolicy=1946 and scertype=2  and nbranch=5 and nproduct=700
select * from Policy_his where  npolicy=1946 and scertype=2  and nbranch=5 and nproduct=700
select * from Life where npolicy=1435
--------------------------------------------------------
------------------- COBERTURAS
select * from Cover where  npolicy=1705 and scertype=2  and nbranch=5 and nproduct=700
select * from life_cover where ncover=95 and nbranch=5 and nproduct=700 and nmodulec=30
select * from TAB_LIFCOV where ncovergen=92360 -- sdescript= NombreCobertura
select * from clause  where  npolicy=1511 and scertype=2  and nbranch=5 and nproduct=700
------------------ coberturas por poliza
select tcob.ncovergen ,tcob.sdescript NombreCobertura,cob.* 
from cover cob 
inner join life_cover lcob ON cob.nbranch= lcob.nbranch and cob.nproduct= lcob.nproduct and cob.ncover= lcob.ncover and cob.nmodulec= lcob.nmodulec
inner join tab_lifcov tcob on lcob.ncovergen= tcob.ncovergen
where cob.npolicy=1726 and cob.scertype=2 and cob.nbranch=5 and cob.nproduct=700
-------------------------------------------------------
-- RECARGOS/DESCUENTOS/IMPUESTOS
select * from DISC_XPREM where npolicy=1946 and scertype=2  and nbranch=5 and nproduct=700 -- NDISC_CODE
select * from DISCO_EXPR Where NDISEXPRC=20 
select * from DISCO_EXPR ORDER BY NDISEXPRC,NDINSUR_TYPE 
-------------------------------------------------------
-- ROLES: Contratante, titular, etc.
select crol.sdescript,rol.* 
from roles rol 
inner join Table12 cRol on rol.nrole= cRol.nrole
where  npolicy=1946 and scertype=2  and nbranch=5 and nproduct=700

select * from CLIDOCUMENTS  where sclient='00000000003669' and ntypclientdoc=3
SELECT * FROM FORMATVALUES
-----------------------------------------------------------
--- Titular de la Factura

select crol.sdescript,clirol.scliename, clidoc.sclinumdocu
, REAGENERALPKG.REANAMECLI(rol.sclient)
from roles rol 
inner join Table12 cRol on rol.nrole= cRol.nrole
inner join Client clirol on rol.sclient= clirol.sclient
inner join CLIDOCUMENTS clidoc on rol.sclient = clidoc.sclient and rol.ntypclientdoc = clidoc.ntypclientdoc
where  npolicy=1647 and scertype=2  and nbranch=5 and nproduct=700 
and rol.nstatusrol=1 and rol.nrole=87
----------------------------------------------------------

select * from Client where sclient='00000000003669'
select * from Client where sclient in (select sclient from roles where  npolicy=1537 and scertype=2 )
select * from Bk_account where sclient='00000000002995' --  Cuentas Bancarias
select * from Cred_card where sclient='00000000002995' -- Tarjeta de credito

select * from Table12 -- Roles de Poliza
select * from Table417 -- Especialidades
select * from Table18 -- Sexo
select * from Table14 -- Estado Civil
select * from Table222 -- Profesion
select * from TAble5006 -- Tipo Persona
-----------------------------------------------------------
--- COmisiones
select * from COMMISSION where npolicy=1569 -- Distribucion de Comision por Intermediario  
select * from COMM_POL where npolicy=1558
select * from INTERM_TYP
------------------------------------------------------------
-- DIRECCIONES
select * from Address where sclient='00000000003759'--- npolicy=
select * from Phones where skeyaddress='12570015130                                       '
select * from Notes where NNotenum=2062 --- POLICY.NNOTE_COMME= 2061   1685

-----------------------------------------------------------
----- PLANES POR ASEGURADO 
select * from MODUL_INSURED
----- PLANES 
select * from modules where  npolicy=1536 and scertype=2  and nbranch=5 and nproduct=700
select * from TAB_MODUL where Nmodulec in (20,30) and nbranch=5 and nproduct=700

select * from TABLE9214 where NGEOGRAPHAREA=1 -- NGEOGRAPHAREA -- AMBITO GEOGRAFICO
select * from TABLE9215 where NATTENSYSTEM=2 -- NATTENSYSTEM  -- SISTEMA DE ATENCIÓN

-----------------------------------------------------------
--- Documentos solicitados para vida
SELECT * FROM LIFE_DOCU where  npolicy=1538 and scertype=2  and nbranch=5 and nproduct=700
select * from CLIDOCPOL where npolicy=1538 and scertype=2  and nbranch=5 and nproduct=700
select * from TABLE32 where NCRTHECNI=9200
select * from TABLE275 where NSTAT_DOCREQ=2
-----------------------------------------------------------

select * from Intermedia where NIntermed=71
select * from INTERM_TYP where Nintertyp=5  --- Intermedia.Nintertyp = INTERM_TYP.Nintertyp

select * from INTERMEDIA_STAGE where Nsupervis=46
------------------ PRESTACIONES
select * from LEND_AGREE_PRES where npolicy=1538 order by sclient -- NCOD_AGREE
select * from AGREEMENT where NCOD_AGREE=30000
select * from LEND_AGREE_PROD where NCOD_AGREE=30000
-----------------------------------------------------------
------------------ EXCLUSIONES
select * from TAB_AM_EXC WHERE NPOLICY=1485
select * from TAB_AM_ILL WHERE TRIM(SILLNESS)='K359'
-----------------------------------------------------------
------------ Maternidad
SELECT CASE WHEN NVL(COUNT(1),0)> 1 THEN 'SI' ELSE 'NO' END --,lcob.ncovergen,cob.*,  tcob.*
FROM COVER cob
INNER JOIN LIFE_COVER lcob ON cob.nbranch= lcob.nbranch and cob.nproduct= lcob.nproduct and cob.ncover= lcob.ncover and cob.nmodulec= lcob.nmodulec
INNER JOIN TAB_LIFCOV tcob on lcob.ncovergen= tcob.ncovergen
WHERE cob.npolicy=1726 and cob.scertype=2
and cob.nbranch=5    and cob.nproduct=700
and cob.sclient='00000000003968'
and tcob.ncovergen=92250 -- MATERNIDAD

------------ Odontologia
SELECT CASE WHEN NVL(COUNT(1),0)> 1 THEN 'SI' ELSE 'NO' END
--cob.*
FROM COVER cob
INNER JOIN LIFE_COVER lcob ON cob.nbranch= lcob.nbranch and cob.nproduct= lcob.nproduct and cob.ncover= lcob.ncover and cob.nmodulec= lcob.nmodulec
INNER JOIN TAB_LIFCOV tcob on lcob.ncovergen= tcob.ncovergen

WHERE cob.npolicy=1746 and cob.scertype=2
and cob.nbranch=5    and cob.nproduct=700
and tcob.ncovergen IN (92190, 92191) -- Asist./Cob. Odontologica
and cob.npolicy=1746

---------------------------------------------------------
select * from table5632 -- SCertype
select * from Table17 --- TipoPoliza
select * from Table36
select * from Table9
select * from Table181
select * from ProdMaster
select * from Intermedia
select * from HEALTH


select * from TAble5532
select * from OPT_PREMIU
select * from POL_TRAVEL
select * from TABLE5605
select * from TAB_MODUL
select * from groups
select * from cover_co_p
select * from TAB_LOCAT

select * from WAIT_CODE_HIST
select * from Table23


select * from DOCUMENT
select * from SYS.ALL_SOURCE where upper(TEXT) like '%ODONTOLOGIA%%' 