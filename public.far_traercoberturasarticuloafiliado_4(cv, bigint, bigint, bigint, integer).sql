CREATE OR REPLACE FUNCTION public.far_traercoberturasarticuloafiliado_4(character varying, bigint, bigint, bigint, integer)
 RETURNS SETOF far_plancoberturamedicamentoafiliado
 LANGUAGE sql
AS $function$-- Cobertura del medicamento para el Afiliado y la OSocial del Recetario

--Busca la cobertura de amuc

SELECT  o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
	far_afiliado.idafiliado::bigint as idafiliado,
	m.mnroregistro::text,
	2 as prioridad,
	 multiplicadoramuc as porcCob,
	'0.0'::double precision as montoFijo,    	
	o.osdescripcion as pdescripcion,	
	concat(ov.idvalorescaja::text , '-' , o.osdescripcion) as detalle,
	'0' as codautorizacion
	
FROM medicamento AS m
NATURAL JOIN  manextra
NATURAL JOIN plancoberturafarmacia
CROSS JOIN (select * from far_obrasocial WHERE idobrasocial = 3 ) as o
NATURAL JOIN far_afiliado
NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)
WHERE  idobrasocial = 3 and mnroregistro = $1 and nullvalue(fechafinvigencia)
AND idafiliado = $4
AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre

UNION

--Busca la cobertura en sosunc
SELECT  o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
	far_afiliado.idafiliado::bigint as idafiliado,
	 m.mnroregistro::text,
	 3 as prioridad,
	 multiplicador as porcCob,
	'0.0'::double precision as montoFijo,    	
	o.osdescripcion as pdescripcion,	
	concat(ov.idvalorescaja::text , '-' , o.osdescripcion) as detalle,
	'0' as codautorizacion
FROM medicamento AS m
NATURAL JOIN  manextra
NATURAL JOIN plancoberturafarmacia
CROSS JOIN (select * from far_obrasocial WHERE idobrasocial = 1 ) as o
NATURAL JOIN far_afiliado
NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)

LEFT JOIN far_validacion AS fv ON(fincodigo =1 AND idvalidacion = $5)	
WHERE  idobrasocial = 1 and mnroregistro = $1 and nullvalue(fechafinvigencia)
AND idafiliado = $3  AND (NULLVALUE(fv.fincodigo) or  fv.fincodigo <> idobrasocial)
AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre

UNION

--Busca la cobertura de la otra obra social

select  o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
        $2 as idafiliado,
        -- CASE WHEN nullvalue(m.mnroregistro) THEN a.idarticulo ELSE m.mnroregistro END::text,
        $1 as mnroregistro,
	1 as prioridad,
        CASE WHEN nullvalue(porcentajecobertura) THEN 0 ELSE porcentajecobertura*0.01 END::double precision as porcCob,    	
	CASE WHEN nullvalue(impotecobertura) THEN 0 ELSE impotecobertura END::double precision as montoFijo,    	
	ap.pdescripcion as pdescripcion,
	concat('3' , '-' , ap.pdescripcion) as detalle,
	codautorizacion::text as codautorizacion

from far_validacionitems as v
LEFT JOIN medicamento as m ON m.mcodbarra = v.Codbarras
LEFT JOIN far_articulo as a ON (a.acodigobarra = v.codbarras)
JOIN far_validacion AS avr USING(idvalidacion)
JOIN adesfa_prepagas AS ap ON(avr.fincodigo=ap.idadesfa_prepagas)
JOIN far_obrasocial AS o USING(idobrasocial)
JOIN far_obrasocialvalorescaja AS ov USING(idobrasocial)
where (mnroregistro = $1  OR  (idarticulo = trim(split_part($1,'-',1))  AND idcentroarticulo = trim(split_part($1,'-',2)) ) ) AND idvalidacion = $5

UNION

select 	

	999::bigint as idobrasocial,
	0::bigint as idplancobertura,
	$2::bigint as idafiliado,
	$1 as mnroregistro,	
 	99 as prioridad,	
	1::double precision as porcCob,
	0.0::double precision as montoFijo,
	'A cargo del Afiliado' as pcdescripcion,
	'0-A Cargo del Afiliado' as detalle,
	'0' as codautorizacion
order by prioridad





;
$function$
