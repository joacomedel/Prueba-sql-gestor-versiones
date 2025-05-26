CREATE OR REPLACE FUNCTION public.restartipodiasafechas(pparametros character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$  DECLARE

--REGISTROS
 rfiltros RECORD;
--VARIABLE
 cantdias INTEGER;
 diassabados INTEGER;
 diasdomingos INTEGER;
 cantferiados INTEGER;
 
BEGIN

 EXECUTE sys_dar_filtros(pparametros) INTO rfiltros;
 
 IF(rfiltros.tipodia ILIKE '%sabado%')   THEN
      SELECT INTO cantdias count (*) FROM ca.dardiasx(rfiltros.fechadesde::date, rfiltros.fechahasta::date, 6); 
 END IF;
 IF(rfiltros.tipodia ILIKE '%domingo%')   THEN   
       SELECT INTO cantdias count (*) FROM ca.dardiasx(rfiltros.fechadesde::date, rfiltros.fechahasta::date, 0);  
 END IF;
 IF(rfiltros.tipodia ILIKE '%feriado%')   THEN   
       SELECT INTO cantdias count (*) FROM ca.feriado WHERE fefecha >=  rfiltros.fechadesde AND fefecha <= rfiltros.fechahasta;
 END IF;
 
RETURN cantdias;
  END;
$function$
