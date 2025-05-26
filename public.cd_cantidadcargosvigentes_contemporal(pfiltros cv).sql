CREATE OR REPLACE FUNCTION public.cd_cantidadcargosvigentes_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

--Cantidad de cargos vigentes por unidad académica 
CREATE TEMP TABLE temp_cd_cantidadcargosvigentes_contemporal
AS (
	
		WITH UltimoCargo AS (
-- Busco todos los cargos y solo filtro por la más reciente en caso de que tenga dos
   SELECT nrodoc, iddepen, descrip, fechainilab,
       ROW_NUMBER() OVER
           (PARTITION BY nrodoc ORDER BY fechainilab DESC) as rn --Ordeno los cargos más recientes primero
       FROM cargo
       NATURAL JOIN depuniversitaria
           WHERE fechafinlab >= now()
           )
--Agrupo de la tabla temporal "UltimoCargo" y muestro resultado

SELECT COUNT(*) AS cantidad, descrip,
	  '1-CantidadCargos#cantidad@2-Descripcion#descrip'::text as mapeocampocolumna 
		
   FROM UltimoCargo
   WHERE rn = 1  --Me quedo con los cargos más recientes
       GROUP BY iddepen, descrip

  );

return true;
END;
$function$
