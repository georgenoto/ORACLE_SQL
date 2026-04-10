SELECT excl.scertype,excl.NBranch,excl.NProduct,excl.NPolicy,excl.sclient 
,SUBSTR(LISTAGG( TRIM(CASE WHEN excl.STYPE_EXC=1 
                      THEN TRIM(desExc.sdescript) || ' ' || TRIM(excl.sdescript)                     
                      END ), ', ') WITHIN GROUP(ORDER BY excl.NPolicy,excl.sclient), 1, 200) AS Exclusiones
,SUBSTR(LISTAGG( TRIM(CASE WHEN excl.STYPE_EXC=2 THEN
                              CASE WHEN (excl.DINIT_DATE IS NOT NULL AND excl.DEND_DATE IS NOT NULL ) THEN TRIM(desExc.sdescript)  || ' Desde: ' || TO_CHAR( NVL(excl.DINIT_DATE, SYSDATE), 'DD-MM-YYYY')  || ' Hasta: ' || TO_CHAR( NVL(excl.DEND_DATE, SYSDATE), 'DD-MM-YYYY')|| ' ' || TRIM(excl.sdescript)
                                 WHEN (excl.DINIT_DATE IS NOT NULL AND excl.DEND_DATE IS NULL) THEN  TRIM(desExc.sdescript)  || ' Desde: ' || TO_CHAR( NVL(excl.DINIT_DATE, SYSDATE), 'DD-MM-YYYY')  || ' ' || TRIM(excl.sdescript)                 
                                 ELSE TRIM(desExc.sdescript) || ' ' || TRIM(excl.sdescript)
                                 END                    
                      END ), ', ') WITHIN GROUP(ORDER BY excl.NPolicy,excl.sclient), 1, 200) AS CarenciasParticulares
FROM TAB_AM_EXC excl 
LEFT JOIN TAB_AM_ILL desExc On excl.SILLNESS= desExc.SILLNESS    
WHERE  excl.DNULLDATE IS NULL
GROUP BY excl.scertype, excl.NBranch, excl.NProduct, excl.NPolicy, excl.sclient
