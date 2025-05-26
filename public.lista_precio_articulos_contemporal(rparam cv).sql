CREATE OR REPLACE FUNCTION public.lista_precio_articulos_contemporal(rparam character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
arr varchar[];
	array_len integer;
	rfiltros record;
        vquery varchar;
	
BEGIN
 

EXECUTE sys_dar_filtros(rparam) INTO rfiltros;


CREATE TEMP TABLE temp_lista_precio_articulos_contemporal
AS (
    SELECT *, 
    '1-CódigoBarra#acodigobarra@2-Articulo#adescripcion@3-Rubro#rdescripcion@4-pcfechafini#pcfechafini@5-Valor Compra#preciocompra'::text as mapeocampocolumna  
--@6-pafechaini#pafechaini@7-$Venta s/IVA#pavalor@8-IVA#pimporteiva@9-$Venta c/IVA#pvalorcompra'::text as mapeocampocolumna  
     FROM

(select
acodigobarra, adescripcion, rdescripcion,pcfechafini,preciocompra
/*
idrubro,far_articulo.idarticulo,far_articulo.idcentroarticulo,pcfechafini,
pcfechafin,preciocompra,
pdescripcion,
adescripcion,acodigointerno,acodigobarra,rdescripcion
*/

from
 far_articulo
 natural join far_preciocompra
natural join far_rubro

left join prestador using (idprestador)



where -- nullvalue(pafechafin) 
       --and nullvalue(pcfechafin)
       --AND  pafechaini::varchar>='2023-11-01' AND   pcfechafini::varchar>='2023-11-01'  
      --- AND idarticulo =68071 

pcfechafini::varchar>=rfiltros.fechadesde
and (pcfechafin::varchar<=rfiltros.fechahasta )-- or rfiltros.fechahasta='')

order by  idrubro,idarticulo,pcfechafini) as tprecios

);
return true;
END;$function$
