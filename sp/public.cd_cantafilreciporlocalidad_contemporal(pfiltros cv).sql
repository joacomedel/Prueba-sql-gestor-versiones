CREATE OR REPLACE FUNCTION public.cd_cantafilreciporlocalidad_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--cantidad de titulares de reciprocidad activos  
CREATE TEMP TABLE temp_cd_cantafilreciporlocalidad_contemporal
AS (

  
	select count(*) as cantidad,abreviatura as osreci,descrip,
	'1-CantidadTitulares#cantidad@2-Reciprocidad#osreci@3-Descripcion#descrip'::text as mapeocampocolumna 
	from afilreci
	natural  join osreci 
	where
	afilreci.fechavtoreci>=current_date
	group by idosreci,abreviatura,descrip
	
  );

return true;
END;
$function$
