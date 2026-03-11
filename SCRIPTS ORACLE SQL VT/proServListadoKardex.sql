create or replace PROCEDURE proServListadoKardex
/*------------------------------------------------------------------------------------------------------*/
/* NOMBRE    : proServListadoKardex                                                                     */
/* OBJETIVO  : MiddleWare 2, Cobranzas,                                                                 */
/*             Busca el historial de pagos de una póliza	                                        */
/*             Obtención del listado Kardex del sistema                                                 */
/*                                                                                                      */
/* PARAMETROS: 1.- NRODOCUMENTOS         : Numero de Documento                                          */
/*             2.- NROPOLIZA             : Numero de la Poliza                                          */
/*             3.- RAMOS                 : Ramo                                                         */
/*             4.- FECHAINICIOPAGO       : Fecha de inicio del pago                                     */
/*             5.- FECHAFINPAGO          : Fecha de termino del pago                                    */
/*             6.- ESTADOCUOTAS          : Estado de las cuotas                                         */
/*             7.- FILASPORPAGINA        : Cantidad de filas a desplegar por pagina                     */
/*             8.- PAGINA                : Numero de la pagina a desplegar (retornar)                   */
/*             9.- MAXFILAS              : Cantidad maxima de busqueda                                  */
/*            10.- RC1                   : Lista de Datos de Salida                                     */
/*                 10.1 - NROPOLIZA           : Numero de Poliza                                        */
/*                 10.2 - CODEMPRESA          : Codigo de Empresa                                       */
/*                 10.3 - CODSISTEMA          : Codigo del Sistema                                      */
/*                 10.4 - EMPRESA             : Descripcion de la Empresa                               */
/*                 10.5 - NRODOCUMENTO        : Numero de Documento del Cliente                         */
/*                 10.6 - CLIENTE             : Nombre del Cliente                                      */
/*                 10.7 - RAMO                : Descripcion del Ramo                                    */
/*                 10.8 - IDCUOTA             : Id de la Cuota                                          */
/*                 10.9 - NROCUOTA            : Numero de la Cuota                                      */
/*                10.10 - TIPOCUOTA           : Tipo de Cuota                                           */
/*                10.11 - MONTO               : Monto de la Cuota                                       */
/*                10.12 - FECHAPAGO           : Fecha de pago de la Cuota                               */
/*                10.13 - FORMAPAGO           : Forma de pago de la Cuota                               */
/*                10.14 - MONTOPAGADO         : Monto pagado de la Cuota                                */
/*                10.15 - DOCUMENTOPAGO       : Documento del pago                                      */
/*                10.16 - IDFACTURA           : Id de la Factura                                        */
/*                10.17 - NUMEROFACTURA       : Numero de la Factura                                    */
/*                10.18 - FECHAFACTURA        : Fecha de la Factura                                     */
/*                10.19 - IDTRANSACCION       : Id de la transaccion                                    */
/*                10.20 - FECHAREGISTROPAGO   : Fecha de registro del pago                              */
/*                10.21 - NUMERORECIBO        : Numero del recibo                                       */
/*                10.22 - FECHAREGISTRORECIBO : Fecha de registro del recibo                            */
/*                10.23 - TIPOCAMBIO          : Tipo de cambio                                          */
/*                10.24 - MONEDA              : Descripcion de la Moneda                                */
/*                10.25 - INICIOVIGENCIA      : Inicio vigencia del movimiento                          */
/*                10.26 - TERMINOVIGENCIA     : Fin vigencia del movimiento                             */
/*            11 .- TOTALFILASCONSULTA  : Total de filas de la consulta                                 */
/*                                                                                                      */
/* SOURCESAFE INFORMATION:                                                                              */
/*     $Author:: Gregorio Reyes C. $                                                                    */
/*     $Date:: 16/12/2022 $                                                                             */
/*     $Revision:: 1 $                                                                                  */
/*------------------------------------------------------------------------------------------------------*/
    ( NRODOCUMENTOS	VARCHAR,
      NROPOLIZA         POLICY.NPOLICY%TYPE,
      RAMOS		VARCHAR,
      FECHAINICIOPAGO	DATE,
      FECHAFINPAGO	DATE,
      ESTADOCUOTAS	VARCHAR,
      FILASPORPAGINA	INTEGER,
      PAGINA		INTEGER,
      MAXFILAS		INTEGER,
      RC1		  OUT SYS_REFCURSOR,
      TOTALFILASCONSULTA  OUT INTEGER ) AUTHID CURRENT_USER AS

    NERROR             T_ERR_INTERFACE.NERROR%TYPE;
    SERRORDESC         VARCHAR2(1024);
    SPHONES            VARCHAR2(1024);
    LNROPAGINA         INTEGER;
    LNOFFSET           INTEGER;

BEGIN

    LNROPAGINA := proServListadoKardex.PAGINA;
    LNOFFSET := (LNROPAGINA-1) * proServListadoKardex.FILASPORPAGINA;

    BEGIN
        SELECT COUNT(1)
          INTO proServListadoKardex.TOTALFILASCONSULTA
          FROM PREMIUM    PR,
               PREMIUM_MO PMO
         WHERE PR.SCERTYPE  = '2'
           AND PR.NTYPE     = 1 -- Recibo de cobro
           AND PR.NPOLICY   = proServListadoKardex.NROPOLIZA
           AND PR.SCERTYPE  = PMO.SCERTYPE
           AND PR.NBRANCH   = PMO.NBRANCH
           AND PR.NPRODUCT  = PMO.NPRODUCT
           AND PR.NRECEIPT  = PMO.NRECEIPT
           AND PR.NDIGIT    = PMO.NDIGIT
           AND PR.NPAYNUMBE = PMO.NPAYNUMBE
           AND PMO.NTYPE IN (2,12,14)
           AND PMO.DSTATDATE BETWEEN proServListadoKardex.FECHAINICIOPAGO
                                 AND proServListadoKardex.FECHAFINPAGO;

    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    OPEN RC1 FOR
        SELECT PR.NPOLICY NROPOLIZA,
               'NSB'      CODEMPRESA,
               PR.NBRANCH CODSISTEMA,
               'NACIONAL SEGUROS BOLIVIA' EMPRESA,
               (SELECT RTRIM(CLD.SCLINUMDOCU)
                  FROM CLIDOCUMENTS CLD
                 WHERE CLD.SCLIENT = PR.SCLIENT
                   AND ROWNUM = 1
               ) NRODOCUMENTO,
               (SELECT RTRIM(CL.SCLIENAME)
                  FROM CLIENT CL
                 WHERE CL.SCLIENT = PR.SCLIENT
               ) CLIENTE,
               (SELECT RTRIM(T10.SDESCRIPT)
                  FROM TABLE10 T10
                 WHERE T10.NBRANCH = PR.NBRANCH
               ) RAMO,
               PR.NRECEIPT IDCUOTA,
               PR.NPERIOD  NROCUOTA,
               (SELECT RTRIM(T24.SDESCRIPT)
                  FROM TABLE24 T24
                 WHERE T24.NTRATYPEI = PR.NTRATYPEI
               ) TIPOCUOTA,
               PR.NPREMIUM MONTO,
               PMO.DSTATDATE FECHAPAGO,
               (SELECT RTRIM(TX.SDESCRIPT)
                  FROM TABLE182 TX
                 WHERE TX.SPAY_FORM = PMO.SPAY_FORM
               ) FORMAPAGO,
               PMO.NAMOUNT MONTOPAGADO,
               PMO.NBILLNUM IDFACTURA,
               PMO.NBILLNUM NUMEROFACTURA,
               PMO.NTRANSAC IDTRANSACCION,
               PMO.DCOMPDATE FECHAREGISTROPAGO,
               PMO.NRECEIPT NUMERORECIBO,
               PMO.DCOMPDATE FECHAREGISTRORECIBO,
               NVL(PMO.NEXCHANGE,0) TIPOCAMBIO,
               (SELECT RTRIM(TX.SDESCRIPT)
                  FROM TABLE11 TX
                 WHERE TX.NCODIGINT = PMO.NCURRENCY
               ) MONEDA,
               PR.DEFFECDATE INICIOVIGENCIA,
               PR.DEXPIRDAT  TERMINOVIGENCIA
          FROM PREMIUM    PR,
               PREMIUM_MO PMO
         WHERE PR.SCERTYPE  = '2'
           AND PR.NTYPE     = 1 -- Recibo de cobro
           AND PR.NPOLICY   = proServListadoKardex.NROPOLIZA
           AND PR.SCERTYPE  = PMO.SCERTYPE
           AND PR.NBRANCH   = PMO.NBRANCH
           AND PR.NPRODUCT  = PMO.NPRODUCT
           AND PR.NRECEIPT  = PMO.NRECEIPT
           AND PR.NDIGIT    = PMO.NDIGIT
           AND PR.NPAYNUMBE = PMO.NPAYNUMBE
           AND PMO.NTYPE IN (2,12,14)
           AND PMO.DSTATDATE BETWEEN proServListadoKardex.FECHAINICIOPAGO
                                 AND proServListadoKardex.FECHAFINPAGO
         ORDER BY PR.SCERTYPE, PR.NPOLICY, PR.NRECEIPT, PMO.NTRANSAC
       OFFSET LNOFFSET ROWS FETCH NEXT proServListadoKardex.FILASPORPAGINA ROWS ONLY;

EXCEPTION
    WHEN OTHERS THEN
--        CRETRACE2('proServListadoKardex;',1024,SQLERRM || ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        NERROR      := SQLCODE;
        SERRORDESC  := SQLERRM || ' - ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

END proServListadoKardex;