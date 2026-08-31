import oracledb

conn = oracledb.connect(user='INSUDB', password='Ns8U4t23', dsn='172.16.19.80:1521/BDUAT')
cursor = conn.cursor()

# Buscar recibos con todos los JOINs que necesita el SP
sql = """
    SELECT PR.NBRANCH, PR.NPRODUCT, PR.NPOLICY, PR.NCERTIF,
           PR.NRECEIPT, PR.NCURRENCY, PR.NTRATYPEI, PR.NTYPE,
           PR.NWAY_PAY, PR.DEFFECDATE, PR.DISSUEDAT,
           PM.NTRANSAC, PM.DLEDGERDAT, PM.DSTATDATE, PM.NTYPE AS PM_NTYPE,
           PM.NEXCHANGE,
           CERT.SCLIENT AS CERT_SCLIENT,
           POL.SPOLITYPE,
           POL.NINTERMED
      FROM PREMIUM PR
      INNER JOIN PREMIUM_MO PM
              ON PM.SCERTYPE = PR.SCERTYPE
             AND PM.NBRANCH = PR.NBRANCH
             AND PM.NPRODUCT = PR.NPRODUCT
             AND PM.NRECEIPT = PR.NRECEIPT
             AND PM.NDIGIT = PR.NDIGIT
             AND PM.NPAYNUMBE = PR.NPAYNUMBE
      INNER JOIN CERTIFICAT CERT
              ON CERT.SCERTYPE = PR.SCERTYPE
             AND CERT.NBRANCH = PR.NBRANCH
             AND CERT.NPRODUCT = PR.NPRODUCT
             AND CERT.NPOLICY = PR.NPOLICY
             AND CERT.NCERTIF = PR.NCERTIF
      INNER JOIN POLICY POL
              ON POL.SCERTYPE = PR.SCERTYPE
             AND POL.NBRANCH = PR.NBRANCH
             AND POL.NPRODUCT = PR.NPRODUCT
             AND POL.NPOLICY = PR.NPOLICY
      WHERE PR.SCERTYPE = '2'
        AND PR.NDIGIT = 0
        AND PR.NPAYNUMBE = 0
        AND ROWNUM <= 10
      ORDER BY PR.NRECEIPT DESC
"""
cursor.execute(sql)
cols = [d[0] for d in cursor.description]
print("=== RECIBOS COMPLETOS PARA PRUEBA ===")
for r in cursor.fetchall():
    d = dict(zip(cols, r))
    print(d)

cursor.close()
conn.close()
