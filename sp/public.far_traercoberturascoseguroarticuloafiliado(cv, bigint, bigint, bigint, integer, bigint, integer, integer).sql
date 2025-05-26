CREATE OR REPLACE FUNCTION public.far_traercoberturascoseguroarticuloafiliado(character varying, bigint, bigint, bigint, integer, bigint, integer, integer)
 RETURNS SETOF far_plancoberturamedicamentoafiliado
 LANGUAGE sql
AS $function$
--DECLARE

--rparam RECORD;
--respuesta far_plancoberturamedicamentoafiliado;

--BEGIN
--EXECUTE sys_dar_filtros($1) INTO rparam;

/* $1 vmnroregistro - 
$2 vidafiliadoos
$3 vidafiliadososunc - 
$4 vidafiliadoamuc -
$5 vidvalidacioncoseguro
$6 vidcentrovalidacioncoseguro
*/

--GK 02-06-2022 Se buscan los coseguros Sosunc ( de tener) y a cargo afiliado

SELECT  
	o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
	far_afiliado.idafiliado::bigint as idafiliado,
	m.mnroregistro::text,
	3 as prioridad,
	 multiplicadoramuc as porcCob,
	'0.0'::double precision as montoFijo,    	
	o.osdescripcion as pdescripcion,	
	concat(ov.idvalorescaja , '-' , o.osdescripcion) as detalle,
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
SELECT  
	o.idobrasocial::bigint,
	63::bigint as idvalorescaja,	
	$3 as idafiliado,
	m.mnroregistro::text,
	4 as prioridad,
	CASE WHEN nullvalue(porcentajecobertura) THEN 0 ELSE porcentajecobertura*0.01 END::double precision as porcCob,    	
   '0.0'::double precision as montoFijo,    	
	o.osdescripcion as pdescripcion,	
	concat(63 , '-' , o.osdescripcion) as detalle,
	codautorizacion::text as codautorizacion

FROM far_validacionitems as v
LEFT JOIN medicamento AS m ON (m.mcodbarra = v.Codbarras)
LEFT JOIN far_articulo as a ON (a.acodigobarra = v.codbarras)
JOIN far_validacion AS avr USING(idvalidacion)
JOIN adesfa_prepagas AS ap ON(avr.fincodigo=ap.idadesfa_prepagas)
JOIN far_obrasocial AS o USING(idobrasocial)
JOIN far_obrasocialvalorescaja AS ov USING(idobrasocial)

WHERE  
 mnroregistro = $1  
AND idvalidacion = $5 AND avr.idcentrovalidacion= $8
--AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre

UNION

SELECT 	

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

ORDER BY prioridad;
	
--END;
$function$
