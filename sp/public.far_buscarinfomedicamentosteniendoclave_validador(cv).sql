CREATE OR REPLACE FUNCTION public.far_buscarinfomedicamentosteniendoclave_validador(character varying)
 RETURNS SETOF far_infomedicamento_2
 LANGUAGE sql
AS $function$
-- ULTIMA MOFICACION GK 16-09-2022
SELECT  a.idarticulo,a.idcentroarticulo  
  ,case when nullvalue(a.idrubro) then 4 else a.idrubro end as idrubro
  ,case when nullvalue(a.adescripcion) then concat(mnombre , ' ' , mpresentacion) else a.adescripcion end as adescripcion  
  --,case when nullvalue(pa.pavalor) THEN vm.vmimporte ELSE  pa.pavalor END as precioventa  
  --,case when nullvalue(pc.preciocompra) THEN vm.vmimporte ELSE  pc.preciocompra END as preciocompra
  ,(case when nullvalue(pa.pavalor) THEN vm.vmimporte ELSE  pa.pavalor END) as precio
  ,me.mnroregistro
  ,ra.rdescripcion
  ,a.astockmin
  ,a.astockmax
  ,a.acomentario
  ,case when nullvalue(a.idiva) then 1 else a.idiva end as idiva
  ,a.adescuento
  ,a.acodigointerno  
  ,case when nullvalue(a.acodigobarra) THEN me.mcodbarra::text ELSE a.acodigobarra END as acodigobarra
  , (case when nullvalue(a.adescripcion) then concat(mnombre , ' ' , mpresentacion , ' $ ' , vm.vmimporte::text, ' ' ,me.mtroquel::text ) ELSE concat(a.adescripcion , ' $ ' , pa.pavalor::text) END)  as articulodetalle 
  ,far_darcantidadarticulostock(a.idarticulo,a.idcentroarticulo)::bigint as lstock  
  ,me.mtroquel as troquel
  ,me.mpresentacion as presentacion
  ,la.lnombre as laboratorio
  ,la.idlaboratorio as idlaboratorio
  ,d.monnombre as monodroga
  ,d.idmonodroga as idmonodroga
  ,case when nullvalue(iva.porcentaje) then 0 else iva.porcentaje end as porciva
  --,pc.pcfechafini 
  ,pa.pafechaini 
  FROM medicamento as me  
  LEFT join manextra as mx on me.mnroregistro=mx.mnroregistro
  LEFT JOIN laboratorio as la USING(idlaboratorio)
  left join monodroga as d on mx.idmonodroga=d.idmonodroga
  LEFT JOIN valormedicamento as vm ON me.mnroregistro = vm.mnroregistro AND me.nomenclado= vm.nomenclado and nullvalue(vmfechafin)  
  LEFT JOIN far_medicamento as m  on m.mnroregistro = me.mnroregistro and m.nomenclado = me.nomenclado
  left join far_articulo as a on a.idarticulo=m.idarticulo  and a.idcentroarticulo = m.idcentroarticulo
  LEFT join tipoiva as iva using(idiva)
  LEFT JOIN far_precioarticulo as pa on a.idarticulo=pa.idarticulo and a.idcentroarticulo = pa.idcentroarticulo and nullvalue(pa.pafechafin) 
  LEFT JOIN far_preciocompra as pc on a.idarticulo=pc.idarticulo and a.idcentroarticulo = pc.idcentroarticulo and nullvalue(pc.pcfechafin)
  left join far_rubro as ra ON (ra.idrubro = a.idrubro OR (nullvalue(a.idrubro) AND ra.idrubro = 4))  
  --LEFT JOIN far_precioxcentro as p ON (centro=centro())
  /* Malapi 20-05-2015 Comento, pues es mas rapida la consulta usando la funcion far_darcantidadarticulostock
  left join (select idarticulo,idcentroarticulo,sum(lstock) as lstock  from far_lote  where idcentrolote = centro() GROUP BY idcentroarticulo,idarticulo ) as l on a.idarticulo = l.idarticulo  and a.idcentroarticulo = l.idcentroarticulo
  */
  WHERE (me.mnroregistro::text =  $1)
  UNION 
  SELECT  a.idarticulo,a.idcentroarticulo,  case when nullvalue(a.idrubro) then 4 else a.idrubro end as idrubro  
  ,a.adescripcion as adescripcion
  ,pa.pavalor  as precio
  ,me.mnroregistro::bigint,ra.rdescripcion
  ,a.astockmin,a.astockmax,a.acomentario
  ,a.idiva  
  ,a.adescuento,a.acodigointerno  
  ,a.acodigobarra as acodigobarra  
  , ( case when nullvalue(a.adescripcion) then concat(mnombre , ' ', mpresentacion, ' $ ' , pa.pavalor::text , ' ' ,me.mtroquel::text) ELSE concat(a.adescripcion , ' $ ', pa.pavalor::text) END  ) as articulodetalle
  ,far_darcantidadarticulostock(a.idarticulo,a.idcentroarticulo)::bigint as lstock  
  ,me.mtroquel as troquel
  ,me.mpresentacion as presentacion
  ,la.lnombre as laboratorio
  ,la.idlaboratorio as idlaboratorio
  ,d.monnombre as monodroga
  ,d.idmonodroga as idmonodroga
  ,iva.porcentaje as porciva
  --,pc.pcfechafini 
  ,pa.pafechaini 
  FROM far_articulo as a  
  LEFT JOIN far_medicamento as m on a.idarticulo=m.idarticulo  and a.idcentroarticulo = m.idcentroarticulo 
  LEFT JOIN medicamento as me on a.acodigobarra = me.mcodbarra::text

  LEFT JOIN laboratorio as la USING(idlaboratorio)

  LEFT join manextra as mx on me.mnroregistro=mx.mnroregistro
  LEFT JOIN monodroga as d on mx.idmonodroga=d.idmonodroga
  LEFT join tipoiva as iva using(idiva)
  LEFT JOIN far_precioarticulo as pa on a.idarticulo=pa.idarticulo and a.idcentroarticulo = pa.idcentroarticulo and nullvalue(pa.pafechafin)  
  LEFT JOIN far_preciocompra as pc on a.idarticulo=pc.idarticulo and a.idcentroarticulo = pc.idcentroarticulo and nullvalue(pc.pcfechafin)
  left join far_rubro as ra ON (ra.idrubro = a.idrubro)  
  --LEFT JOIN far_precioxcentro as p ON (centro=centro())
  /* Malapi 20-05-2015 Comento, pues es mas rapida la consulta usando la funcion far_darcantidadarticulostock
  left join (select idarticulo,idcentroarticulo,sum(lstock) as lstock  from far_lote  where idcentrolote = centro() GROUP BY idcentroarticulo,idarticulo ) as l on a.idarticulo = l.idarticulo  and a.idcentroarticulo = l.idcentroarticulo
  */
  WHERE a.idarticulo::text = trim(split_part($1,'-',1))  AND a.idcentroarticulo = trim(split_part($1,'-',2))$function$
