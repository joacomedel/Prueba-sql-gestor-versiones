CREATE OR REPLACE FUNCTION public.farmacia_articulosfraccionados_contemporal()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

/*EXECUTE sys_dar_filtros('') INTO rfiltros;*/

CREATE TEMP TABLE farmacia_articulosfraccionados_contemporal
AS (


select af.acodigobarra,af.adescripcion,af.afraccion,CASE WHEN nullvalue(af.afactorcorreccion) THEN 0 
ELSE af.afactorcorreccion END,far_darcantidadarticulostock(af.idarticulo,af.idcentroarticulo) as stockactualfraccionado

,ap.acodigobarra as codigobarraarticulopadre, ap.adescripcion as articulopadre, 
far_darcantidadarticulostock(ap.idarticulo,ap.idcentroarticulo) as stockactualpadre,
'1-CodigoBarra#acodigobarra@2-Descripcion#adescripcion@3-AFraccion#afraccion@4-AFactorCorreccion#afactorcorreccion@5-N. StockActualFraccionado#stockactualfraccionado'::text as mapeocampocolumna
from far_articulo as af
LEFT JOIN far_articulo as ap ON ap.idarticulo = af.idarticulopadre 
AND ap.idcentroarticulo = af.idcentroarticulopadre
where not nullvalue(af.idarticulopadre) AND ap.aactivo AND af.aactivo

);
     

return true;
END;
$function$
