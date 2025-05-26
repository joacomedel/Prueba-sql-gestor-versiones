CREATE OR REPLACE FUNCTION public.cd_destinosturisticos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 --cantidad de consumos de turismo en cada administrador apartir de una fecha dada

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
CREATE TEMP TABLE temp_cd_destinosturisticos_contemporal
AS (
	SELECT *,
	  '1-CantidadConsumos#cantidad@2-Descripcion#tadescripcion'::text as mapeocampocolumna 
	FROM (
			SELECT  COUNT(*) AS cantidad,tadescripcion
FROM
consumoturismo
NATURAL JOIN turismounidad
NATURAL JOIN turismoadmin
WHERE
tuactiva
AND ctfehcingreso>=rfiltros.ctfehcingreso
GROUP BY tadescripcion
ORDER BY
cantidad DESC
	) as resumenfacturacion 
);
  

return true;
END;
$function$
