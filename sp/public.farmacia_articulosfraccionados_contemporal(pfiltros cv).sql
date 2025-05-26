CREATE OR REPLACE FUNCTION public.farmacia_articulosfraccionados_contemporal(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_farmacia_articulosfraccionados_contemporal
AS (


select af.acodigobarra,af.adescripcion,af.afraccion,CASE WHEN nullvalue(af.afactorcorreccion) THEN 0 
ELSE af.afactorcorreccion END,far_darcantidadarticulostock(af.idarticulo,af.idcentroarticulo) as stockactualfraccionado

,ap.acodigobarra as codigobarraarticulopadre, ap.adescripcion as articulopadre, 
far_darcantidadarticulostock(ap.idarticulo,ap.idcentroarticulo) as stockactualpadre
--,'1-Fecha Desde#fechadesde@2-Fecha Hasta#fechahasta'::text as mapeocampocolumna
from far_articulo as af
LEFT JOIN far_articulo as ap ON ap.idarticulo = af.idarticulopadre 
AND ap.idcentroarticulo = af.idcentroarticulopadre
where not nullvalue(af.idarticulopadre) AND ap.aactivo AND af.aactivo

);
     

return true;
END;
$function$
