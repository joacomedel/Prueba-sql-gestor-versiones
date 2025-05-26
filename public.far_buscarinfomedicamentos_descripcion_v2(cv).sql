CREATE OR REPLACE FUNCTION public.far_buscarinfomedicamentos_descripcion_v2(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

rparam RECORD;
aux character varying;

BEGIN
RAISE NOTICE 'far_buscarinfomedicamentos_descripcion_v2 (%)', $1;
aux = REPLACE ($1,'%','');
EXECUTE sys_dar_filtros(aux) INTO rparam; 
--      18/05/23 BelenA:     Se crea la tabla temporal ya que antes la funcion original devolvia un elemento de tipo far_infomedicamento_2, las consultas futuras se hacen en esta tabla temporal

    IF NOT iftableexists('temp_info_medicamento_desc_v2') THEN

        CREATE TEMP TABLE temp_info_medicamento_desc_v2 (
            idarticulo bigint,
            idcentroarticulo integer,
            idrubro integer,
            adescripcion character varying,
            precio double precision,
            mnroregistro bigint,
            rdescripcion character varying,
            astockmin double precision,
            astockmax double precision,
            acomentario text,
            idiva bigint,
            adescuento double precision,
            acodigointerno bigint,
            acodigobarra text,
            detalle text,
            lstock bigint,
            troquel integer,
            presentacion character varying,
            laboratorio character varying,
            idlaboratorio integer,
            monodroga character varying,
            idmonodroga integer,
            porciva double precision,
            pafechaini date
        );
    ELSE
     DROP TABLE temp_info_medicamento_desc_v2;

      CREATE TEMP TABLE temp_info_medicamento_desc_v2 (
            idarticulo bigint,
            idcentroarticulo integer,
            idrubro integer,
            adescripcion character varying,
            precio double precision,
            mnroregistro bigint,
            rdescripcion character varying,
            astockmin double precision,
            astockmax double precision,
            acomentario text,
            idiva bigint,
            adescuento double precision,
            acodigointerno bigint,
            acodigobarra text,
            detalle text,
            lstock bigint,
            troquel integer,
            presentacion character varying,
            laboratorio character varying,
            idlaboratorio integer,
            monodroga character varying,
            idmonodroga integer,
            porciva double precision,
            pafechaini date
        );
    END IF;
RAISE NOTICE 'far_buscarinfomedicamentos_descripcion_v2 (%)', rparam.parametro::character varying;
INSERT INTO temp_info_medicamento_desc_v2
        ( 
            idarticulo ,
            idcentroarticulo ,
            idrubro ,
            adescripcion ,
            precio ,
            mnroregistro ,
            rdescripcion ,
            astockmin ,
            astockmax ,
            acomentario ,
            idiva ,
            adescuento ,
            acodigointerno ,
            acodigobarra ,
            detalle ,
            lstock ,
            troquel ,
            presentacion ,
            laboratorio ,
            idlaboratorio ,
            monodroga ,
            idmonodroga ,
            porciva ,
            pafechaini 
            )  



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
, mtroquel  as troquel
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
--      18/05/23 BelenA:     En el caso que el parametro iscodbarra sea true, busca de forma mas rapida, si es false busca con el ilike
WHERE aactivo AND 
    CASE WHEN rparam.iscodbarra THEN 
        acodigobarra=rparam.parametro        
    ELSE
        (concat(a.acodigobarra,adescripcion,a.idarticulo,'-',a.idcentroarticulo)  ilike  concat('%',rparam.parametro,'%'))
    END
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
,mtroquel as troquel 
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
--      18/05/23 BelenA:     En el caso que el parametro iscodbarra sea true, busca de forma mas rapida, si es false busca con el ilike
WHERE (nullvalue(a.idarticulo) OR aactivo) AND 
    CASE WHEN rparam.iscodbarra THEN mcodbarra=rparam.parametro
    ELSE
        (concat(me.mnombre,me.mcodbarra,me.mtroquel,me.mnroregistro)  ilike  concat('%',rparam.parametro,'%'))
    END;

return true;

end;
$function$
