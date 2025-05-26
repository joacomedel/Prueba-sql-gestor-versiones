CREATE OR REPLACE FUNCTION public.far_traercoberturasarticuloafiliado_coseguros(character varying, bigint, bigint, bigint, integer, bigint, integer, integer)
 RETURNS SETOF far_plancoberturamedicamentoafiliado
 LANGUAGE sql
AS $function$
	
	--COSEGURO SOSUNC 
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
		AND idvalidacion = $5 
		AND avr.idcentrovalidacion= $8
		AND  	porcentajecobertura<>0.00

ORDER BY prioridad;
	
--END;
$function$
