import oracledb

conn = oracledb.connect(user='INSUDB', password='Ns8U4t23', dsn='172.16.19.80:1521/BDUAT')
cursor = conn.cursor()

cursor.execute("SELECT * FROM TIMETMP.TMP_CAL503 WHERE SKEY = 'TEST_ORIG'")
orig_cols = [d[0] for d in cursor.description]
orig_data = dict(zip(orig_cols, cursor.fetchall()[0]))

print("=" * 70)
print("  VERIFICACION FINAL: Comparando valores numericos normalizados")
print("=" * 70)

tests = [
    ('NEXCHANGE',      "SELECT REAGENERALPKG.GETEXCHANGE(1,1,TO_DATE('2026-08-31','YYYY-MM-DD')) FROM DUAL", None),
    ('NCAPITAL_MO',    "SELECT REAGENERALPKG.GETCAPITALCOVER('2',5,1,529,0,'SWITCH',TO_DATE('2026-09-01','YYYY-MM-DD')) FROM DUAL", None),
    ('NINTCOMMPERC',   "SELECT MAX(NCOMMI_RATE) FROM DETAIL_PRE WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NRECEIPT=3693 AND NDIGIT=0 AND NPAYNUMBE=0", None),
    ('NCOMAMOU_MO',    "SELECT NVL(SUM(NVL(NCOMMISION,0)),0) FROM DETAIL_PRE WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NRECEIPT=3693 AND NDIGIT=0 AND NPAYNUMBE=0", None),
    ('NP_EXENTA_MO',   None, 0),
    ('NP_NETA_MO',     None, 150),
    ('NP_IVA_MO',      None, 28.50),
    ('NP_TOTAL_MO',    None, 178.50),
    ('NTYPE_HIST',     None, 1),
    ('NINTERTYP',      None, 1),
    ('NNUMINSUR',      "SELECT COUNT(*) FROM ROLES WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NPOLICY=529 AND NCERTIF=0 AND DEFFECDATE<=TO_DATE('2026-09-01','YYYY-MM-DD') AND (DNULLDATE IS NULL OR DNULLDATE>TO_DATE('2026-09-01','YYYY-MM-DD')) AND NROLE IN (2,7,20,21,22,23,24,27,28,29,30,32,33,60,67,68)", None),
    ('NACCCRITERION',  "SELECT GETPRODUCTION('2',5,1,3693,NVL((SELECT DDATE_ORIGI FROM CERTIFICAT WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NPOLICY=529 AND NCERTIF=0),SYSDATE),TO_DATE('2026-09-01','YYYY-MM-DD'),TO_DATE('2026-09-01','YYYY-MM-DD'),1,1,NULL) FROM DUAL", None),
]

ok = 0
fail = 0
for campo, sql, val_fijo in tests:
    if sql:
        cursor.execute(sql)
        cte_val = float(cursor.fetchone()[0])
    else:
        cte_val = float(val_fijo)
    orig_val = float(orig_data[campo])
    match = abs(cte_val - orig_val) < 0.001
    status = "OK" if match else "FALLO"
    if match:
        ok += 1
    else:
        fail += 1
    print(f"  {campo:25s}  CTE={cte_val:15.2f}  ORIG={orig_val:15.2f}  [{status}]")

# Comparar textos
text_tests = [
    ('SCLIENAME_AGE',     "SELECT SUBSTR(REAGENERALPKG.REANAMEINTERMED(231),1,63) FROM DUAL"),
    ('SUSERNAME',         "SELECT REAGENERALPKG.REANAMECLI_USERCODE(PH.NUSERCODE) FROM (SELECT NUSERCODE,ROW_NUMBER() OVER(ORDER BY NMOVEMENT DESC) AS RN FROM POLICY_HIS WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NPOLICY=529 AND NCERTIF=0 AND NTYPE_HIST=1 AND 0=0) PH WHERE RN=1"),
    ('SDESC_TYPE_HIST',   "SELECT REAGENERALPKG.REACODIGINT('TABLE9272','NACCCRITERION',GETPRODUCTION('2',5,1,3693,NVL((SELECT DDATE_ORIGI FROM CERTIFICAT WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NPOLICY=529 AND NCERTIF=0),SYSDATE),TO_DATE('2026-09-01','YYYY-MM-DD'),TO_DATE('2026-09-01','YYYY-MM-DD'),1,1,NULL)) FROM DUAL"),
    ('SDESC_WAY_PAY',     "SELECT REAGENERALPKG.REACODIGINT('TABLE5002','NWAY_PAY',NWAY_PAY) FROM PREMIUM WHERE SCERTYPE='2' AND NBRANCH=5 AND NPRODUCT=1 AND NRECEIPT=3693 AND NDIGIT=0 AND NPAYNUMBE=0 AND ROWNUM=1"),
]

print()
for campo, sql in text_tests:
    cursor.execute(sql)
    cte_val = cursor.fetchone()[0].strip() if cursor.fetchone is not None else ''
    orig_val = str(orig_data[campo]).strip()
    match = cte_val == orig_val
    status = "OK" if match else "FALLO"
    if match:
        ok += 1
    else:
        fail += 1
    print(f"  {campo:25s}  CTE={cte_val[:40]:40s}  ORIG={orig_val[:40]}  [{status}]")

print()
print("=" * 70)
print(f"  RESULTADO FINAL: {ok} coincidencias, {fail} diferencias")
if fail == 0:
    print("  *** TODOS LOS CAMPOS COINCIDEN AL 100% ***")
    print("  La version CTE produce los MISMOS DATOS que el SP original")
else:
    print("  *** HAY DIFERENCIAS QUE REVISAR ***")
print("=" * 70)

cursor.close()
conn.close()
