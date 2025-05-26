CREATE OR REPLACE FUNCTION public.cd_cantafilporplan_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_cd_cantafilporplan_contemporal
AS (
	
select  count(nrodoc) as cantafil,descripcion,
	'1-Cantidad#cantafil@2-Descripcion#descripcion'::text as mapeocampocolumna 
 from 
persona
natural join plancobpersona
natural join plancobertura
where fechafinos>=rfiltros.fechafinos
and (nullvalue(pcpfechafin) or pcpfechafin>=rfiltros.fechafinos)
group by descripcion
order by descripcion
  );

return true;
END;
$function$
