CREATE OR REPLACE FUNCTION public.cs_destinosturisticos_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- GK 16-05-2022 - Agrego fecha facturación
-- GK 17-10-2022 - Cambios solicitados por usuario importe total / unitario y diferentes cobertueas
CREATE TEMP TABLE temp_cs_destinosturisticos_contemporal
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
