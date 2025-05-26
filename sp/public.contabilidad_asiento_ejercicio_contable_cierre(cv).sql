CREATE OR REPLACE FUNCTION public.contabilidad_asiento_ejercicio_contable_cierre(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
	
        rfiltros RECORD;
        rejercicio  RECORD;
        rasiento RECORD;
        resp character varying;
 

BEGIN
/**
Este SP retorna la fecha correspondiente al cierre del ejericio contable al que pertenece el asiento
Si el ejericio contable retorna null es que aun se encuentra abierto, caso contrario retorna la facha de cierre
*/
        -- recupero los parámetros
         EXECUTE sys_dar_filtros($1) INTO rfiltros;
  
        -- Busco informacion del asiento
         SELECT INTO rasiento *
         FROM asientogenerico
         WHERE idasientogenerico = rfiltros.idasientogenerico 
               AND idcentroasientogenerico = rfiltros.idcentroasientogenerico; 	
		 
         SELECT INTO rejercicio *
         FROM contabilidad_ejerciciocontable
         WHERE ecfechadesde <= rasiento.agfechacontable  -- la fecha contable se encuentra dentro del rango de fechas del ejercicio contable
            and ecfechahasta >= rasiento.agfechacontable;

         resp = concat('{eccerrado=',rejercicio.eccerrado::date,',idejerciciocontable=',rejercicio.idejerciciocontable,'}');



return resp;
END;
$function$
