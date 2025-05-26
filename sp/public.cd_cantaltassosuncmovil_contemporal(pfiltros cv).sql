CREATE OR REPLACE FUNCTION public.cd_cantaltassosuncmovil_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;



CREATE TEMP TABLE temp_cd_cantaltassosuncmovil_contemporal
AS (
	
	

   SELECT COUNT(pe.nrodoc) as cantidad,
      TO_CHAR(DATE_TRUNC('month', uw.uwfechacreacion), 'YYYY-MM') AS mescreacion,
 '1-CantidadUsuariosCreados#cantidad@2-FechaCreacion#mescreacion'::text as mapeocampocolumna 


FROM persona pe
LEFT JOIN w_usuariorolwebsiges us ON pe.nrodoc = us.dni
LEFT JOIN w_usuarioafiliado wa ON pe.nrodoc = wa.nrodoc
LEFT JOIN personacentroregional pcr ON (pe.nrodoc = pcr.nrodoc AND pe.tipodoc = pcr.tipodoc)
LEFT JOIN centroregional cr ON pcr.idcentroregional = cr.idcentroregional
LEFT JOIN w_usuarioweb uw ON COALESCE(us.idusuarioweb, wa.idusuarioweb) = uw.idusuarioweb
JOIN nrobarratipo AS nbt ON nbt.nrobarra = pe.barra
NATURAL JOIN barratipo AS bt
WHERE (us.idusuarioweb IS NOT NULL OR wa.idusuarioweb IS NOT NULL)
 AND fechafinos >= now()
 AND (pcfechafin IS NULL OR pcfechafin >= now())
GROUP BY TO_CHAR(DATE_TRUNC('month', uw.uwfechacreacion), 'YYYY-MM')
ORDER BY mescreacion DESC
  );

return true;
END;
$function$
