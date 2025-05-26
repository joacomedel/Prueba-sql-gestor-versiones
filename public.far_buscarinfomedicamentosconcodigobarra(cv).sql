CREATE OR REPLACE FUNCTION public.far_buscarinfomedicamentosconcodigobarra(character varying)
 RETURNS SETOF far_infomedicamento_2
 LANGUAGE sql
AS $function$
-- ULTIMA MOFICACION GK 16-09-2022
SELECT * FROM (
SELECT  a.idarticulo,a.idcentroarticulo  
,case when nullvalue(a.idrubro) then 4 else a.idrubro end as idrubro
,case when nullvalue(a.adescripcion) then concat(mnombre , ' ' , mpresentacion) else a.adescripcion end as adescripcion  
,case when nullvalue(p.pavalor) THEN vm.vmimporte ELSE  p.pavalor END as precio  
,me.mnroregistro
,ra.rdescripcion
,a.astockmin
,a.astockmax
,a.acomentario
,case when nullvalue(a.idiva) then 1 else a.idiva end as idiva
,a.adescuento
,a.acodigointerno  
,case when nullvalue(a.acodigobarra) THEN me.mcodbarra::text ELSE a.acodigobarra END as acodigobarra  
,case when nullvalue(a.adescripcion) then concat(mnombre , ' ' , mpresentacion , ' $ ' , vm.vmimporte::text, ' ' ,me.mtroquel::text )
                   ELSE concat(a.adescripcion , ' $ ' , p.pavalor::text) END as detalle  
,far_darcantidadarticulostock(a.idarticulo,a.idcentroarticulo)::bigint as lstock  
,me.mtroquel as troquel
,me.mpresentacion as presentacion
,la.lnombre as laboratorio
,la.idlaboratorio as idlaboratorio
,d.monnombre as monodroga
,d.idmonodroga as idmonodroga
,case when nullvalue(iva.porcentaje) then 0 else iva.porcentaje end as porciva
,p.pafechaini
FROM medicamento as me  
LEFT join manextra as mx on me.mnroregistro=mx.mnroregistro
LEFT JOIN laboratorio as la USING(idlaboratorio)
left join monodroga as d on mx.idmonodroga=d.idmonodroga
LEFT JOIN valormedicamento as vm ON me.mnroregistro = vm.mnroregistro AND me.nomenclado= vm.nomenclado and nullvalue(vmfechafin)  
LEFT JOIN far_medicamento as m  on m.mnroregistro = me.mnroregistro and m.nomenclado = me.nomenclado
left join far_articulo as a on a.idarticulo=m.idarticulo  and a.idcentroarticulo = m.idcentroarticulo
LEFT join tipoiva as iva using(idiva)
LEFT JOIN far_precioarticulo as p on a.idarticulo=p.idarticulo and a.idcentroarticulo = p.idcentroarticulo	and nullvalue(p.pafechafin) 
left join far_rubro as ra ON (ra.idrubro = a.idrubro OR (nullvalue(a.idrubro) AND ra.idrubro = 4))  
WHERE (me.mcodbarra::text ilike  $1) AND (nullvalue(acodigobarra) OR acodigobarra ilike  $1)
UNION 
SELECT  a.idarticulo,a.idcentroarticulo,  case when nullvalue(a.idrubro) then 4 else a.idrubro end as idrubro  
,a.adescripcion as adescripcion,p.pavalor  as precio  
,me.mnroregistro::bigint,ra.rdescripcion
,a.astockmin,a.astockmax,a.acomentario
,a.idiva  
,a.adescuento,a.acodigointerno  
,a.acodigobarra as acodigobarra  
,case when nullvalue(a.adescripcion) then concat(mnombre , ' ', mpresentacion, ' $ ' , p.pavalor::text , ' ' ,me.mtroquel::text) ELSE concat(a.adescripcion , ' $ ', p.pavalor::text) END as detalle    
,far_darcantidadarticulostock(a.idarticulo,a.idcentroarticulo)::bigint as lstock  
,me.mtroquel as troquel
,me.mpresentacion as presentacion
,la.lnombre as laboratorio
,la.idlaboratorio as idlaboratorio
,d.monnombre as monodroga
,d.idmonodroga as idmonodroga

,iva.porcentaje as porciva
,p.pafechaini
FROM far_articulo as a  
LEFT JOIN far_medicamento as m on a.idarticulo=m.idarticulo  and a.idcentroarticulo = m.idcentroarticulo 
LEFT JOIN medicamento as me on a.acodigobarra = me.mcodbarra::text

LEFT JOIN laboratorio as la USING(idlaboratorio)

LEFT join manextra as mx on me.mnroregistro=mx.mnroregistro
LEFT JOIN monodroga as d on mx.idmonodroga=d.idmonodroga
LEFT join tipoiva as iva using(idiva)
LEFT JOIN far_precioarticulo as p on a.idarticulo=p.idarticulo and a.idcentroarticulo = p.idcentroarticulo 	and nullvalue(p.pafechafin) 
left join far_rubro as ra ON (ra.idrubro = a.idrubro)  
WHERE a.acodigobarra ilike $1
) as t
ORDER BY precio DESC$function$
