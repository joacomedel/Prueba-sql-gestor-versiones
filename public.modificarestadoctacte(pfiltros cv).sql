CREATE OR REPLACE FUNCTION public.modificarestadoctacte(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$

DECLARE
--VARIABLES
elnumeroregistro VARCHAR;
estado VARCHAR;
--RECORD
rfiltros RECORD;
restadoctacte RECORD;
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

IF (rfiltros.accion = 'guardar') THEN
    estado='';

-- Si existe un movimiento, coloca al último (El que tiene nulo el upfechafincambio), con
    UPDATE usuariopersona
    SET upfechafincambio=now()
    WHERE nrodoc = rfiltros.nrodoc AND nullvalue(upfechafincambio); 

    IF (rfiltros.ctacteexpendio) THEN
        estado='HABILITADO';
    ELSE
        estado='DESHABILITADO';
    END IF;

    INSERT INTO usuariopersona(idusuario,fechacambio,nrodoc,tipodoc,motivo, estadoctacte) 
    VALUES(rfiltros.idusuario, rfiltros.fechacambio, rfiltros.nrodoc, rfiltros.tipodoc, rfiltros.motivo, estado);

END IF;


return true;
END;
$function$
