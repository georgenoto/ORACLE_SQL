create or replace FUNCTION NS_fnBusquedaInteligente
( 
    sNombreCompleto varchar2 , sCadenaBusqueda varchar2
)
RETURN smallint AUTHID CURRENT_USER AS

    NombreCompleto varchar2(255):=sNombreCompleto;
    strCadenaBusqueda varchar2(255):=sCadenaBusqueda;
    bolResult SMALLINT:=1;
    Separator varchar2(1):=' ';
    StrLine VARCHAR2(255);
    nSize number:=1;
    nStart number:=1;
BEGIN	
             
    strCadenaBusqueda:=trim(strCadenaBusqueda);
    strCadenaBusqueda:=translate(strCadenaBusqueda,'áéíóúÁÉÍÓÚñÑäëïöüÄËÏÖÜ','aeiouAEIOUnNaeiouAEIOU');
    NombreCompleto:=translate(NombreCompleto,'áéíóúÁÉÍÓÚñÑäëïöüÄËÏÖÜ','aeiouAEIOUnNaeiouAEIOU');
    if length(strCadenaBusqueda)>0 then
        WHILE (nStart < LENGTH(strCadenaBusqueda) + 1) LOOP
            nSize := INSTR(SUBSTR(strCadenaBusqueda, nStart, LENGTH(strCadenaBusqueda)), Separator, 1);
            IF nSize = 0 then nSize := LENGTH(strCadenaBusqueda) - nStart + 1; end if;
            StrLine := SUBSTR(SUBSTR(strCadenaBusqueda, nStart, LENGTH(strCadenaBusqueda)), 1, nSize);
            StrLine := REPLACE(StrLine,Separator,'');
  
            if NOT REGEXP_LIKE(NombreCompleto,StrLine,'i') then
                bolResult:=0;
                exit;
            end if;
            nStart := nStart + nSize;
        END LOOP;
    end if;
   return bolResult;
END NS_fnBusquedaInteligente;