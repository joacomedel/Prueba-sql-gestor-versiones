CREATE OR REPLACE FUNCTION public.controles_reporteconveniosunidades_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_controles_reporteconveniosunidades_contemporal 
AS (
	SELECT 
	idconvenio,convenio.cdenominacion,idtipounidad,tudescripcion,round(idtipovalor::numeric,2) as monto,tvinivigencia,tvfinvigencia,CASE WHEN nullvalue(tvfinvigencia) THEN 'Vigente' ELSE 'Historico' END as vigencia 
	,'1-cod.Convenio#idconvenio@2-Descripcion#cdenominacion@3-Cod.Unidad#idtipounidad@4-Unidad#tudescripcion@5-Importe#monto@6-Inicio Vig.#tvinivigencia@7-Fin Vig.#tvfinvigencia@8-Vigente#vigencia'::text as mapeocampocolumna
	from tablavalores
	NATURAL JOIN convenio 
	natural join tipounidad  
	where  idconvenio IN (267,287,269,280,264) 
	order by idconvenio,tvinivigencia


);
     

return true;
END;
$function$
