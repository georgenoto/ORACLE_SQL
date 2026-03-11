SELECT
    XPre.scertype,
    XPre.nbranch,
    XPre.nproduct,
    XPre.npolicy,
    XPre.ncertif,
    XPre.ndisc_code,
    D_XPre.sdescript Descripcion,
    XPre.deffecdate,
    XPre.namount,
    XPre.dcompdate,
    XPre.ncurrency,
    XPre.nnotenum,
    XPre.dnulldate,
    XPre.nusercode,
    XPre.ncause,
    XPre.sagree,
    XPre.npercent
FROM
    disc_xprem  XPre
INNER JOIN DISCO_EXPR D_XPre ON XPre.NDISC_CODE= D_XPre.NDISEXPRC AND XPre.NBranch=  D_XPre.NBranch and xpre.nproduct= D_XPre.NProduct
WHERE XPre.npolicy=1538 and XPre.scertype=2  and XPre.nbranch=5 and XPre.nproduct=700