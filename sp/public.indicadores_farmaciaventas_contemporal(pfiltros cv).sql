CREATE OR REPLACE FUNCTION public.indicadores_farmaciaventas_contemporal(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       --RECORD
	rfiltros RECORD;
/*
Que incluya TODOS los artículos de la farmacia
Columnas: 
Rubro, 
Artículo (codigo-descripcion), 
Precio de Venta,
Cantidad Vendida, 
Cantidad Recibida, 
Cantidad de Órdenes de Venta Con el articulo
Fecha desde 01-11-2019 al 31-01-2020

*/

BEGIN
 
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE temp_indicadores_farmaciaventas_contemporal (
acodigobarra varchar,
adescripcion varchar,
codigosiges varchar,
rdescripcion varchar,
cantidadvendida INTEGER,
cantidadcomprada INTEGER,
cantidadpedidos INTEGER,
precioventa double precision,
cantidadordenes INTEGER,
mapeocampocolumna varchar
);


INSERT INTO temp_indicadores_farmaciaventas_contemporal (acodigobarra,adescripcion,codigosiges,rdescripcion,precioventa,cantidadvendida,cantidadcomprada,cantidadpedidos,cantidadordenes) (
SELECT acodigobarra,adescripcion,concat(idarticulo,'-',idcentroarticulo) as codigosiges,rdescripcion
,far_precioventafecha(idarticulo,idcentroarticulo,current_date) as precioventa
,CASE WHEN nullvalue(cantidadvendida) THEN 0 ELSE cantidadvendida END as cantidadvendida
,CASE WHEN nullvalue(cantidadcomprada) THEN 0 ELSE cantidadcomprada END as cantidadcomprada
,CASE WHEN nullvalue(cantidadpedidos) THEN 0 ELSE cantidadpedidos END as cantidadpedidos
,CASE WHEN nullvalue(cantidadordenes) THEN 0 ELSE cantidadordenes END as cantidadordenes
FROM far_articulo 
NATURAL JOIN far_rubro
LEFT JOIN (
select sum(ovicantidad) as cantidadvendida,idarticulo,idcentroarticulo,count(idordenventa) as cantidadordenes
from far_ordenventa 
natural join far_ordenventaitem 
NATURAL JOIN far_ordenventaestado 
where ovfechaemision >=rfiltros.fechadesde
AND ovfechaemision <=rfiltros.fechahasta 
AND (idordenventatipo < 3 )
AND nullvalue(ovefechafin)
AND idordenventaestadotipo <> 2
GROUP BY idarticulo,idcentroarticulo
) as ventas USING(idarticulo,idcentroarticulo)
LEFT JOIN (
select idarticulo,idcentroarticulo,sum(picantidadentregada) as cantidadcomprada,count(idpedido) as cantidadpedidos	
from far_pedido 
natural join far_pedidoitems
WHERE pefechacreacion >=rfiltros.fechadesde
AND pefechacreacion <=rfiltros.fechahasta 
AND not nullvalue(picantidadentregada) AND picantidadentregada > 0
GROUP BY idarticulo,idcentroarticulo
) as pedidos  USING(idarticulo,idcentroarticulo)
WHERE aactivo 
AND (pedidos.cantidadcomprada > 0 OR ventas.cantidadvendida > 0)
);


UPDATE temp_indicadores_farmaciaventas_contemporal SET mapeocampocolumna = '1-CodBarra#acodigobarra@2-Articulo#adescripcion@3-Cod.Siges#codigosiges@4-Rubro#rdescripcion@5-PrecioVenta#precioventa@6-Cant.Vendida#cantidadvendida@7-Cant.Comprada#cantidadcomprada@8-Cant.Pedidos#cantidadpedidos@9-Cant.Ordenes#cantidadordenes';

return 'true';
END;
$function$
