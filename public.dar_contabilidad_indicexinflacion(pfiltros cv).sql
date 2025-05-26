CREATE OR REPLACE FUNCTION public.dar_contabilidad_indicexinflacion(pfiltros character varying)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* retorna el indice actual aplicado a un determinado mes
*/
DECLARE
      valor double precision;
	  rfiltros  RECORD;
	  rcuenta RECORD;
     
BEGIN
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     valor = 0;
	 SELECT INTO valor cixivalor 
	 FROM contabilidad_indicexinflacion 
	 WHERE ciximes_numero = rfiltros.mes_numero
	    	AND cixifechadesde <= rfiltros.fecha_indice
			AND cixifechahasta >= rfiltros.fecha_indice;
		
	 IF nullvalue(valor) THEN 
	       valor = 0; 
	 END IF;
	 
	 return valor;

END;
$function$
