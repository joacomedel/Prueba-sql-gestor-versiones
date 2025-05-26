CREATE OR REPLACE FUNCTION public.generaarchivodetalle(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  ptipoarchivo alias for $1;
  respuesta varchar;
  rtipoarchivo RECORD;
  rfiltros RECORD;
 
   
BEGIN

EXECUTE sys_dar_filtros(ptipoarchivo) INTO rfiltros;

respuesta = '';
SELECT INTO rtipoarchivo * FROM far_archivotrazabilidadtipos WHERE atratipoarchivo = rfiltros.tipoarchivo;

IF FOUND THEN 

IF rtipoarchivo.atradiscriminante = 3 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivopadronbeneficiarios_solidez(rfiltros.tipoarchivo); 
END IF;

IF rtipoarchivo.atradiscriminante = 2 THEN
	SELECT INTO respuesta * FROM far_generaarchivoliquidacionrecetas(rfiltros.tipoarchivo); 
END IF;

IF rtipoarchivo.atradiscriminante = 1 THEN
	SELECT INTO respuesta * FROM far_generaarchivotrazabilidad(rfiltros.tipoarchivo); 
END IF;

IF rtipoarchivo.atradiscriminante = 4 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivopadronbeneficiarios_sumas__(ptipoarchivo); 
END IF;

IF rtipoarchivo.atradiscriminante = 5 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivosueldos(ptipoarchivo); 
END IF;
IF rtipoarchivo.atradiscriminante = 6 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivopadronbeneficiarios_ras(ptipoarchivo); 
END IF;
IF rtipoarchivo.atradiscriminante = 7 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivoconyugebaja(ptipoarchivo); 
END IF;
IF rtipoarchivo.atradiscriminante = 8 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivoconyugealta(ptipoarchivo); 
END IF;
IF rtipoarchivo.atradiscriminante = 9 THEN
	SELECT INTO respuesta * FROM afiliaciones_generaarchivopadronbeneficiarios_observer(ptipoarchivo); 
END IF;
ELSE 
     RAISE EXCEPTION 'Error en el formato de los Filtros (%)', $1;
END IF;
return respuesta;
END;
$function$
