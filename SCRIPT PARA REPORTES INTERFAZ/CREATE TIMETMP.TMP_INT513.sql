DROP TABLE TIMETMP.TMP_INT513 CASCADE CONSTRAINTS;

CREATE TABLE TIMETMP.TMP_INT513
(
SKEY                                      	VARCHAR2(20 CHAR),
NCODRAMO                                  	NUMBER(5),             ---  NBRANCH
SCOD_TIPO_CERTIFICADO             			VARCHAR2(1 CHAR),      --   SCERTYPE
NNRO_TOTAL_ASEGURADO                      	NUMBER(10),
NNRO_TOTAL_ASEGURADOXCUENTA               	NUMBER(10),
NCOD_PRODUCTO                             	NUMBER(10),
SPRODUCTO                                 	VARCHAR2(100 CHAR),    -- NPRODUCT
SPLAN                                     	VARCHAR2(100 CHAR),
STIPO_POLIZA                              	VARCHAR2(50 CHAR),
STIPO_FACT_COLECTIVO                      	VARCHAR2(100 CHAR),	
STIPO_DISTRIBUCION                    		VARCHAR2(100 CHAR),	     
NNRO_POLIZA                               	NUMBER(10),             --NPOLICY
NCOD_MONEDA_POL                        		NUMBER(10),
SMONEDA_POL                            		VARCHAR2(20 CHAR),
DFEC_EMISION_POL							DATE,
DFEC_INIVIGENCIA_POL						DATE,
DFEC_FINVIGENCIA_POL						DATE,
NCOD_ESTADO_POL 							NUMBER(4),
SESTADO_POL									VARCHAR(30 CHAR),
NCOD_REGIONAL_POL							NUMBER(4),
SREGIONAL_POL								VARCHAR(20 CHAR),
NCOD_TIPO_INTERMEDIARIO						NUMBER(5),		
STIPO_INTERMEDIARIO	    	            	VARCHAR2(30 CHAR),	
NCOD_INTERMEDIARIO					    	NUMBER(15),		
SINTERMEDIARIO        				    	VARCHAR2(100 CHAR),	
NCAPITAL_ASEGURADO_MO                     	NUMBER(10),
NCAPITAL_ASEGURADO_LO                     	NUMBER(10),
NDEDUCIBLE_MO                             	VARCHAR2(30 CHAR),
NDEDUCIBLE_LO                             	VARCHAR2(30 CHAR),  
SAMBITO_GEOGRAFICO                        	VARCHAR2(100 CHAR),
STIPO_RED_MEDICA                          	VARCHAR2(200 CHAR),  
SCONTRATANTE                              	VARCHAR2(150 CHAR),
NNRO_CERTIFICADO                          	NUMBER(5),             
NCOD_ASEGURADO                            	VARCHAR2(20 CHAR),
SNOMBRE_ASEG                         		VARCHAR2(150 CHAR),
SAPELLIDOS_ASEG                       		VARCHAR2(150 CHAR),
SESTADO_ASEG                         		VARCHAR2(50 CHAR),
SGENERO_ASEG                              	VARCHAR2(20 CHAR),  
SRELACION_ASEG                            	VARCHAR2(50 CHAR),
STIPO_PERSONA_ASEG                        	VARCHAR2(100 CHAR), 
STIPO_DOCUMENTO_ASEG                      	VARCHAR2(20 CHAR),  
SNRO_DOCUMENTO_ASEG                       	VARCHAR2(50 CHAR),
SNRO_COMPLEMENTO_ASEG						VARCHAR(10 CHAR),
DFEC_NAC_ASEG                    			DATE,
NEDAD_ASEG                                	NUMBER(3),  
SCIUDAD_RESIDENCIA_ASEG                   	VARCHAR2(100 CHAR),
DFEC_INGRESO_ASEG                         	DATE,
DFEC_EGRESO_ASEG                          	DATE,
DFEC_ANTIGUEDAD_ASEG                      	DATE,  
NCAPITAL_ANTIGUEDAD_ASEG                  	NUMBER(10),
SCORREO_ASEG                        		VARCHAR2(200 CHAR),    
SEXCLUSIONES_PARTICULARES                 	VARCHAR2(200 CHAR),
SOTRO_SEGURO                              	VARCHAR2(100 CHAR),
SCOB_MATERNIDAD                           	VARCHAR2(100 CHAR),
SCOB_PORC_AMBULATORIA                     	VARCHAR2(20 CHAR),
SCOB_PORC_HOSPITALARIA                    	VARCHAR2(20 CHAR),
SCOB_PORC_MED_AMBULATORIOS                	VARCHAR2(20 CHAR),
SCOB_ADICIONAL_ODONTOLOGICA               	VARCHAR2(20 CHAR),
SCOA_ODONTOLOGICO                         	VARCHAR2(50 CHAR),
SCLINICA_ODONTOLOGICA                     	VARCHAR2(100 CHAR),
SSEGURO_VIAJERO                           	VARCHAR2(5 CHAR),
SEMERGENCIA_MEDICA                        	VARCHAR2(100 CHAR),
SMUERTE_ACCIDENTAL                        	VARCHAR2(5 CHAR),
SSEPELIO                                  	VARCHAR2(5 CHAR),  
DFECHAFIN_CREDENCIAL                      	DATE,
SCONDICIONES_COASEGURO_CONSULTA           	VARCHAR2(300 CHAR),  
SOBSERVACIONES                            	VARCHAR2(300 CHAR)
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

COMMENT ON TABLE TIMETMP.TMP_INT513 IS 'Tabla temporal para almacenar los datos para el reporte de asegurados vigentes';



CREATE OR REPLACE PUBLIC SYNONYM TMP_INT513 FOR TIMETMP.TMP_INT513;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON TIMETMP.TMP_INT513 TO INSUDB;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON TIMETMP.TMP_INT513 TO INSUDBGEN;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON TIMETMP.TMP_INT513 TO VTAPPS;
