DROP TABLE TIMETMP.TMP_INT512 CASCADE CONSTRAINTS;

CREATE TABLE TIMETMP.TMP_INT512
(
  SKEY                                  VARCHAR2(20 CHAR),
  SCERTYPE            		            VARCHAR2(1 CHAR),
  NBRANCH                               NUMBER(5),     --- COD. RAMO
  NPRODUCT                              NUMBER(10),    --- COD. PRODUCTO
  NPOLICY                               NUMBER(10),    --- NRO. POLIZA
  SDESPRODUCT                           VARCHAR2(100 CHAR), --- DESC. PRODUCTO
  SCURRENCY					            VARCHAR2(30 CHAR), -- MONEDA POLIZA
  STYPPOLICY                            VARCHAR2(50 CHAR), -- TIPO POLIZA
  SCOLINVOT                             VARCHAR2(100 CHAR),	--- TIPO FACTURA COLECTIVO
  STYPDIS_PAYPERCEN                     VARCHAR2(100 CHAR),	     --- TIPO DISTRIBUCION   
  SGEOGRAPHAREA                         VARCHAR2(100 CHAR),    ---AMBITO GEOGGRAFICO
  SATTENSYSTEM                          VARCHAR2(100 CHAR),    ---SISTEMA ATENCION
  NSTATUSVA                             NUMBER (10),        --- COD ESTADO POIZA
  SSTATUSVA                             VARCHAR(100),       --- ESTADO POLIZA
  DSTARTDATE                            DATE,               --- INICIO DE VIGENCIA
  DEXPIRDAT                             DATE,               --- TERMINO DE VIGENCIA  
  SCLIENT_CONTRACTOR                    VARCHAR2(20 CHAR), --- COD. CONTRATANTE
  SCLIENAME_CONTRACTOR                  VARCHAR2(100 CHAR), --- NOMBRE CONTRATANTE
  DISSUEDAT                             DATE,               --- FECHA EMISION
  NOFFICE                               NUMBER(5),     --- COD. REGIONAL POLIZA
  SDESOFFICE                            VARCHAR2(30 CHAR), --- DESC. REGIONAL POLIZA  
  NCERTIF                               NUMBER(5),             --- NRO. DE CERTIFICADO
  SCLIENT_INSURED                       VARCHAR2(20 CHAR), --- COD. ASEGURADO
  SFIRSTNAME_INSURED                    VARCHAR2(100 CHAR), --- NOMBRE ASEGURADO
  SLASTNAME_INSURED                     VARCHAR2(100 CHAR), --- PRIMER APELLIDO ASEGURADO
  SLASTNAME2_INSURED                    VARCHAR2(100 CHAR), --- SEGUNDO APELLIDO ASEGURADO
  SCLIENTNAME_INSURED                   VARCHAR2(200 CHAR), --- NOMBRE COMPLETO ASEGURADO
  SSEXCLIENT_INSURED                    VARCHAR2(50 CHAR), --- SEXO DEL ASEGURADO
  SROLE_INSURED                         VARCHAR2(50 CHAR), --- ROL DEL ASEGURADO
  DBIRTHDATE                            DATE,               --- FECHA DE NACIMIENTO
  NAGE                                  NUMBER(5),           --- EDAD ASEGURADO
  SPERSONTYPE                           VARCHAR2(100 CHAR), --- TIPO DE PERSONA
  NTYPCLIENTDOC                         NUMBER(10) ,         --- COD TIPO DE DOCUMENTO
  SCLINUMDOC                            VARCHAR(50 CHAR),       --- NRO DE DOCUMENTO
  SIDCOMPLE                             VARCHAR(10 CHAR),       --- COMPLEMENTO
  SSTATE_INSURED                        VARCHAR(50 CHAR),       --- ESTADO ASEGURADO
  SCITY_RESIDENCE                       VARCHAR(50 CHAR),       --- CIUDAD DE RESIDENCIA
  SCOUNTRY_RESIDENCE                    VARCHAR(50 CHAR),       --- PAIS DE RESIDENCIA
  DEFFECDATE                            DATE,                   --- FECHA INGRESO ASEGURADO
  DNULLDATE                             DATE,                   --- FECHA EGRESO ASEGURADO
  SMAIL_INSURED                         VARCHAR2(150 CHAR),     --- EMAIL ASEGURADO
  DCREATE_INSURED                       DATE,                   --- FECHA CREACION USUARIO
  SUSERNAME_CREATEINSURED               VARCHAR2(200 CHAR),     --- USUARIO QUE CREO AL ASEGURADO
  DUPDATE_INSURED                       DATE,                   --- FECHA CREACION USUARIO
  SUSERNAME_UPDATEINSURED               VARCHAR2(200 CHAR),     --- USUARIO QUE MODIFICO AL ASEGURADO
  NINTERTYP					            NUMBER(5),		--- COD. TIPO INTERMEDIARIO
  SDESINTERTYP			                VARCHAR2(30 CHAR),	--- DESC. TIPO INTERMEDIARIO
  NINTERMED					            NUMBER(15),		--- COD.  INTERMEDIARIO
  SDESINTERMED				            VARCHAR2(100 CHAR),	--- NOMBRE INTERMEDIARIO
  SSTATUSVA_CERTIF                      VARCHAR2(100 CHAR)       --- ESTADO CERTIFICADO
  
)
TABLESPACE DATA1
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;

COMMENT ON TABLE TIMETMP.TMP_INT512 IS 'Tabla temporal para almacenar los datos de asegurados ';
COMMENT ON COLUMN TIMETMP.TMP_INT512.NCERTIF IS 'Número de certificado';
COMMENT ON COLUMN TIMETMP.TMP_INT512.DNULLDATE IS 'Fecha de anulacion o exclusion del asegurado';


CREATE OR REPLACE PUBLIC SYNONYM TMP_INT512 FOR TIMETMP.TMP_INT512;
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON TIMETMP.TMP_INT512 TO INSUDB;
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON TIMETMP.TMP_INT512 TO INSUDBGEN;
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON TIMETMP.TMP_INT512 TO VTAPPS;
