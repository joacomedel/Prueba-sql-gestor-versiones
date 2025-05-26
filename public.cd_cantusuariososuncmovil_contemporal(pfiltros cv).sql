CREATE OR REPLACE FUNCTION public.cd_cantusuariososuncmovil_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--Cantidad de lsgh activas por unidad académica 
CREATE TEMP TABLE temp_cd_cantusuariososuncmovil_contemporal
AS (
	
  SELECT COUNT(pe.nrodoc) AS cantidad, bt.bttitulo AS tipobarra,
 '1-CantidadUsuarios#cantidad@2-TipoBarra#tipobarra'::text as mapeocampocolumna 
FROM persona pe
LEFT JOIN w_usuariorolwebsiges us ON pe.nrodoc = us.dni
LEFT JOIN w_usuarioafiliado wa ON pe.nrodoc = wa.nrodoc
LEFT JOIN personacentroregional pcr ON (pe.nrodoc = pcr.nrodoc AND pe.tipodoc = pcr.tipodoc)
LEFT JOIN centroregional cr ON pcr.idcentroregional = cr.idcentroregional
LEFT JOIN w_usuarioweb uw ON COALESCE(us.idusuarioweb, wa.idusuarioweb) = uw.idusuarioweb
JOIN nrobarratipo AS nbt ON nbt.nrobarra = pe.barra
NATURAL JOIN barratipo AS bt
WHERE  (us.idusuarioweb IS NOT NULL OR  wa.idusuarioweb IS NOT NULL) AND fechafinos >= now() AND (pcfechafin IS NULL OR pcfechafin >= now())
GROUP BY tipobarra 
ORDER BY cantidad DESC
  );

return true;
END;
$function$
