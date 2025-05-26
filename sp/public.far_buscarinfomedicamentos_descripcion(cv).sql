CREATE OR REPLACE FUNCTION public.far_buscarinfomedicamentos_descripcion(character varying)
 RETURNS SETOF far_infomedicamento_2
 LANGUAGE sql
AS $function$--SELECT * FROM (

-- ULTIMA MOFICACION GK 16-09-2022
SELECT  a.idarticulo
,a.idcentroarticulo
,0 as idrubro  
,concat(a.adescripcion,' --- PRECIO ',pa.pavalor+pa.pimporteiva,' --- STOCK ', lstock,' --- LAB ',lnombre)  as adescripcion
,CASE WHEN p.tabla ilike 'far_preciocompra' THEN pc.preciocompra ELSE pa.pavalor END as precio
,m.mnroregistro::bigint
, null as rdescripcion 
, null::double precision  as astockmin 
, null::double precision as  astockmax
, null as acomentario
,  idiva 
, null::double precision as adescuento
, null::bigint  as acodigointerno
,a.acodigobarra as acodigobarra
,concat(a.adescripcion,' --- PRECIO ',pa.pavalor,' --- VTO ',fechavto,' --- STOCK ', lstock,' --- LAB ',lnombre) as detalle 
--, a.adescripcion as detalle 
, CASE WHEN nullvalue(lstock) THEN 0 ELSE lstock END as lstock
, null::integer  as troquel
, null as  presentacion
,lnombre as laboratorio
,idlaboratorio 
,monnombre as monodroga 
,mx.idmonodroga 
,iva.porcentaje as porciva
,pa.pafechaini
FROM far_articulo as a LEFT join tipoiva as iva using(idiva)
LEFT JOIN far_articulocontrolvto as facv USING(idarticulo,idcentroarticulo) 
LEFT JOIN far_medicamento as m on a.idarticulo=m.idarticulo and a.idcentroarticulo = m.idcentroarticulo
LEFT JOIN far_precioarticulo as pa on a.idarticulo=pa.idarticulo and a.idcentroarticulo = pa.idcentroarticulo and nullvalue(pa.pafechafin)
LEFT JOIN far_preciocompra as pc on a.idarticulo=pc.idarticulo and a.idcentroarticulo = pc.idcentroarticulo and nullvalue(pc.pcfechafin)
LEFT JOIN medicamento as me ON me.mnroregistro=m.mnroregistro 
LEFT join manextra as mx on me.mnroregistro=mx.mnroregistro
LEFT JOIN laboratorio as la USING(idlaboratorio)
left join monodroga as d on mx.idmonodroga=d.idmonodroga
LEFT JOIN far_lote ON (a.idarticulo=far_lote.idarticulo  AND a.idcentroarticulo=far_lote.idcentroarticulo and  far_lote.idcentrolote=centro()) 
LEFT JOIN far_precioxcentro as p ON (centro=centro())
WHERE aactivo AND (concat(a.acodigobarra,adescripcion,a.idarticulo,'-',a.idcentroarticulo)  ilike  $1)
UNION
SELECT  m.idarticulo
, m.idcentroarticulo
, 0 as idrubro 
, concat(mnombre ,' ',mpresentacion,' --- PRECIO ',pa.pavalor+pa.pimporteiva,' --- STOCK ', lstock,' --- LAB ',lnombre) as adescripcion   
, CASE WHEN p.tabla ilike 'far_preciocompra' 
              THEN (case when nullvalue(pc.preciocompra) THEN vm.vmimporte ELSE  pc.preciocompra END) 
              ELSE (case when nullvalue(pa.pavalor) THEN vm.vmimporte ELSE  pa.pavalor END)
              END as precio
,me.mnroregistro::bigint
,null as rdescripcion 
,null as astockmin
,null as astockmax
,null as acomentario 
,idiva 
,null as adescuento
,null as acodigointerno
,me.mcodbarra::text as acodigobarra 
,concat(mnombre ,' ',mpresentacion,' --- PRECIO ',pa.pavalor,' --- VTO ',fechavto,' --- STOCK  ', lstock,' --- LAB ',lnombre)as detalle 
--,concat(mnombre ,' ',mpresentacion) as detalle 
, CASE WHEN nullvalue(lstock) THEN 0 ELSE lstock END as lstock
,null as troquel 
,null as presentacion
,lnombre as laboratorio
,idlaboratorio 
,monnombre as monodroga 
,mx.idmonodroga 
,case when nullvalue(iva.porcentaje) then 0 else iva.porcentaje end as porciva
,pa.pafechaini
FROM medicamento as me
LEFT join manextra as mx on me.mnroregistro=mx.mnroregistro
LEFT JOIN laboratorio as la USING(idlaboratorio)
left join monodroga as d on mx.idmonodroga=d.idmonodroga
LEFT JOIN valormedicamento as vm ON me.mnroregistro = vm.mnroregistro AND me.nomenclado= vm.nomenclado and nullvalue(vmfechafin)
LEFT JOIN far_medicamento as m on me.mnroregistro=m.mnroregistro 
LEFT JOIN far_articulo as a USING(idarticulo,idcentroarticulo) 
LEFT JOIN far_articulocontrolvto as facv USING(idarticulo,idcentroarticulo) 
LEFT JOIN far_preciocompra as pc on a.idarticulo=pc.idarticulo and a.idcentroarticulo = pc.idcentroarticulo and nullvalue(pc.pcfechafin)
LEFT JOIN far_precioarticulo as pa on a.idarticulo=pa.idarticulo and a.idcentroarticulo = pa.idcentroarticulo and nullvalue(pa.pafechafin)
LEFT JOIN far_lote ON (a.idarticulo=far_lote.idarticulo  AND a.idcentroarticulo=far_lote.idcentroarticulo and  far_lote.idcentrolote=centro()) 
LEFT JOIN tipoiva as iva using(idiva)
LEFT JOIN far_precioxcentro as p ON (centro=centro())
WHERE (nullvalue(a.idarticulo) OR aactivo) AND  (concat(me.mnombre,me.mcodbarra,me.mtroquel,me.mnroregistro) ilike  $1)

--) as t
--ORDER BY idarticulo$function$
