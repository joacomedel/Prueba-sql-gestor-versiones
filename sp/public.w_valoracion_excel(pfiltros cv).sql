CREATE OR REPLACE FUNCTION public.w_valoracion_excel(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_w_valoracion_excel
AS (
	 
--KR 19-12-22 Modifique la consulta para sacar info irrelevante y colocar info del afiliado y orden
SELECT  concat(nroorden,'-', centro) as laorden, concat(nrodoc, '-', barra) as nroafiliado, concat(apellido, ' ', nombres) as afiliado, fechaemision,  vfecha as fechavaloracion, vobservacion as observacionvaloracion,
	tvnombre as tipovaloracion, tvdesc as preguntavaloracion, CASE vtppuntaje WHEN 'true' THEN 'SI' WHEN 'false' THEN 'NO' ELSE vtppuntaje END AS puntaje,
	  p.pcuit as cuitprestador, p.pdescripcion,  
	m.nromatricula, m.mespecialidad	,'1-Nroorden#laorden@2-Nro.Afiliado#nroafiliado@3-Afiliado#afiliado@4-Fecha Emision#fechaemision@5-Fecha Valoracion#fechavaloracion@6-Observacion#observacionvaloracion@7-TipoValoracion#tipovaloracion@8-Valoracion#preguntavaloracion@8-Puntaje#puntaje@9-CuitPrestador#cuitprestador@11-Razonsocial#pdescripcion@12-Matricula#nromatricula@13-Especialidad#mespecialidad'::text as mapeocampocolumna   
 
FROM w_valoracion NATURAL JOIN orden NATURAL JOIN consumo NATURAL JOIN persona 
	NATURAL JOIN w_valoraciontipopuntaje
	NATURAL JOIN w_tipovaloracion
	NATURAL JOIN prestador as p
	LEFT JOIN matricula as m on m.idprestador = p.idprestador
where vfecha >= rfiltros.fechadesde AND vfecha <=  rfiltros.fechahasta
/*group by idvaloracion, vobservacion, vfecha, nroorden, centro, tipo,
tvnombre, tvdesc,puntaje,p.idprestador, p.pcuit, p.pdescripcion, m.nromatricula, m.mespecialidad	*/
order by idvaloracion, nroorden, vfecha,p.pdescripcion
);

return true;
END;
$function$
