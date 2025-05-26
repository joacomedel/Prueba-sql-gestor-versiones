CREATE OR REPLACE FUNCTION public.reporteasociaciones_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_reporteasociaciones_contemporal 
AS (
            SELECT idasocconv,asdescripext,idconvenio,acdecripcion,
            acfechaini,acfechafin,'1-cod.Asociacion#idasocconv@2-DescripcionAsocacion#asdescripext@3-cod.Convenio#idconvenio@4- DescripcionConvenio#acdecripcion@5-Inicio Vig.#acfechaini@6-Fin Vig.#acfechafin'::text as mapeocampocolumna
	
          from asocconvenio
	       NATURAL JOIN convenio 
               where   acdecripcion ilike concat('%',rfiltros.acdecripcion,'%')
                       or rfiltros.acdecripcion=null
          order by acdecripcion 

);
     

return true;
END;
$function$
