CREATE OR REPLACE FUNCTION public.far_traerinfocoberturas_unificado()
 RETURNS SETOF far_plancoberturainfomedicamentoafiliado_2
 LANGUAGE plpgsql
AS $function$DECLARE
/*
CREATE TEMP TABLE tfar_articulo (			mnroregistro VARCHAR,			idarticulo BIGINT,			idcentroarticulo BIGINT,			convale BOOLEAN,			idafiliado VARCHAR,			idobrasocial INTEGER,			cantvendida INTEGER,			idvalidacion INTEGER,			idcentrovalidacion INTEGER			) ;
INSERT INTO tfar_articulo(mnroregistro,idarticulo,idcentroarticulo, nrodoc,tipodoc,idobrasocial,idvalidacion, idcentrovalidacion)	    
VALUES(	'24583',		88475,		99,		'28272137',1,9,null,null);
select *,articulodetalle as detalle from far_traerinfocoberturas_unificado();*/
       --carticulo CURSOR FOR SELECT * FROM tfar_articulo;
       carticulo refcursor;
       cnrosafiliado refcursor;
       rarticulo RECORD;
       rnrosafiliado RECORD;
       rarticuloinicial  RECORD;
       
       rpersona RECORD;
       rafiliado RECORD;
       rafil RECORD;
       rafiloso RECORD;
       rmutual RECORD;
       rafilmutu RECORD;
       
       elafiliado bigint;
       vidafiliadomutual bigint;
       vquemutual integer;
       vnrodoc varchar;
       vtipodoc integer;
       vidafiliadoos bigint;
       vidafiliadososunc bigint;
       vidafiliadoamuc bigint;
       vidvalidacion integer;
       vidcentrovalidacion integer;
       vmnroregistro varchar;
       tieneamuc boolean;
       respuestaafiliacion boolean;
       rcob far_plancoberturamedicamentoafiliado;
       rcobinfomedi far_plancoberturainfomedicamentoafiliado_2;

begin


CREATE TEMP TABLE far_plancoberturamedicamentoafiliadounificado (
  idarticulo BIGINT,
  idcentroarticulo INTEGER,
  idobrasocial BIGINT,
  idplancobertura BIGINT,
  idafiliado BIGINT,
  idcentroafiliado INTEGER,
  mnroregistro VARCHAR,
  prioridad INTEGER,
  porccob DOUBLE PRECISION,
  montofijo DOUBLE PRECISION,
  pcdescripcion VARCHAR,
  detalle VARCHAR,
  codautorizacion VARCHAR
);


SELECT INTO rarticuloinicial * FROM tfar_articulo WHERE not nullvalue(tfar_articulo.nrodoc) LIMIT 1;
IF FOUND THEN
	--vidvalidacion = rarticulo.idvalidacion;
	--vidcentrovalidacion = rarticulo.idcentrovalidacion;
        SELECT INTO respuestaafiliacion * FROM far_verificaingresaafiliacion(rarticuloinicial.nrodoc,rarticuloinicial.tipodoc,rarticuloinicial.idobrasocial,rarticuloinicial.idvalidacion,rarticuloinicial.idcentrovalidacion);

END IF;


OPEN carticulo FOR SELECT * FROM far_dararticulosparacoberturas();
FETCH carticulo into rarticulo;
WHILE  found LOOP

OPEN cnrosafiliado FOR SELECT * FROM far_darnumeromutualesafiliado(rarticuloinicial.nrodoc,rarticuloinicial.tipodoc,rarticuloinicial.idobrasocial);
FETCH cnrosafiliado into rnrosafiliado;
WHILE  found LOOP

-- El articulo que esta validado, recupera la cobertura de la validacion
INSERT INTO far_plancoberturamedicamentoafiliadounificado(idarticulo,idcentroarticulo,idobrasocial,idplancobertura,idafiliado,idcentroafiliado,mnroregistro,prioridad,porccob,montofijo,pcdescripcion,detalle,codautorizacion) (
select  a.idarticulo, 
	a.idcentroarticulo, 
        o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
        rnrosafiliado.idafiliado as idafiliado,
        rnrosafiliado.idcentroafiliado as idcentroafiliado,
        m.mnroregistro as mnroregistro,
	1 as prioridad,
        CASE WHEN nullvalue(porcentajecobertura) THEN 0 ELSE porcentajecobertura*0.01 END::double precision as porcCob,    	
	CASE WHEN nullvalue(impotecobertura) THEN 0 ELSE impotecobertura END::double precision as montoFijo,    	
	ap.pdescripcion as pdescripcion,
	concat(3 , '-' , ap.pdescripcion) as detalle,
	codautorizacion::text as codautorizacion
from far_validacionitems as v
JOIN far_articulo as a ON (a.acodigobarra = v.codbarras)
LEFT JOIN medicamento as m ON m.mcodbarra = v.Codbarras
JOIN far_validacion AS avr USING(idvalidacion,idcentrovalidacion)
JOIN adesfa_prepagas AS ap ON(avr.fincodigo=ap.idadesfa_prepagas)
JOIN far_obrasocial AS o USING(idobrasocial)
JOIN far_obrasocialvalorescaja AS ov USING(idobrasocial)
where idarticulo = rarticulo.idarticulo  AND idcentroarticulo = rarticulo.idcentroarticulo
AND v.idvalidacion = rarticuloinicial.idvalidacion AND v.idcentrovalidacion = rarticuloinicial.idcentrovalidacion
AND o.idobrasocial = rnrosafiliado.idobrasocial
);
-- Recupero la cobertura de la mutual, vinculada a la obra social que valida. 
--- LAS OTRAS MUTUALES, siempre que la obra social asociada la cubra, la mutual lo cobre.
INSERT INTO far_plancoberturamedicamentoafiliadounificado(idarticulo,idcentroarticulo,idobrasocial,idplancobertura,idafiliado,idcentroafiliado,mnroregistro,prioridad,porccob,montofijo,pcdescripcion,detalle,codautorizacion) (
select  a.idarticulo, 
	a.idcentroarticulo, 
	fosm.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
        fa.idafiliado as idafiliado,
        fa.idcentroafiliado as idcentroafiliado,
        m.mnroregistro as mnroregistro,
	2 as prioridad,
        CASE WHEN nullvalue(osmmultiplicador) THEN 0 ELSE osmmultiplicador END::double precision as porcCob,    	
	'0.0'::double precision as montoFijo,    	
	fosm.osdescripcion as pdescripcion,
	concat(fosm.idobrasocial , '-' , fosm.osdescripcion) as detalle,
	codautorizacion::text as codautorizacion
from far_validacionitems as v
JOIN far_articulo as a ON (a.acodigobarra = v.codbarras)
LEFT JOIN medicamento as m ON m.mcodbarra = v.Codbarras
JOIN far_validacion AS avr USING(idvalidacion,idcentrovalidacion)
JOIN adesfa_prepagas AS ap ON(avr.fincodigo=ap.idadesfa_prepagas)
JOIN far_obrasocial AS o USING(idobrasocial)
JOIN far_obrasocialmutual as osm ON osm.idobrasocial = o.idobrasocial AND osm.idmutual = rnrosafiliado.idobrasocial
JOIN far_afiliado as fa ON fa.idafiliado = rnrosafiliado.idafiliado 
                         AND fa.idcentroafiliado = rnrosafiliado.idcentroafiliado 
                         AND fa.idobrasocial = rnrosafiliado.idobrasocial 
JOIN far_obrasocialvalorescaja AS ov ON osm.idmutual = ov.idobrasocial
JOIN far_obrasocial as fosm ON fosm.idobrasocial = osm.idmutual
where idarticulo = rarticulo.idarticulo  AND idcentroarticulo = rarticulo.idcentroarticulo
AND v.idvalidacion = rarticuloinicial.idvalidacion AND v.idcentrovalidacion = rarticuloinicial.idcentrovalidacion
--AND o.idobrasocial = rarticuloinicial.idobrasocial
);


-- Busco la cobertura de SOSUNC / AMUC

INSERT INTO far_plancoberturamedicamentoafiliadounificado(idarticulo,idcentroarticulo,idobrasocial,idplancobertura,idafiliado,idcentroafiliado,mnroregistro,prioridad,porccob,montofijo,pcdescripcion,detalle,codautorizacion) (
select  a.idarticulo, 
	a.idcentroarticulo, 
        o.idobrasocial::bigint,
	ov.idvalorescaja::bigint,	
	fa.idafiliado as idafiliado,
        fa.idcentroafiliado as idcentroafiliado,
	m.mnroregistro::text,
	CASE WHEN fa.idobrasocial = 1 THEN 20 ELSE 3 END as prioridad, -- Sosunc tiene la prioridad mas baja
	CASE WHEN fa.idobrasocial = 1 THEN multiplicador ELSE multiplicadoramuc END  as porcCob,
	'0.0'::double precision as montoFijo,    	
	o.osdescripcion as pdescripcion,	
	concat(ov.idvalorescaja , '-' , o.osdescripcion) as detalle,
	'0' as codautorizacion
FROM medicamento AS m
NATURAL JOIN  manextra
NATURAL JOIN plancoberturafarmacia
NATURAL JOIN far_medicamento
NATURAL JOIN far_articulo as a
CROSS JOIN (select * from far_obrasocial WHERE idobrasocial = rnrosafiliado.idobrasocial) as o
NATURAL JOIN far_obrasocialvalorescaja AS ov --USING(idobrasocial)
JOIN far_afiliado as fa ON fa.idafiliado = rnrosafiliado.idafiliado 
                         AND fa.idcentroafiliado = rnrosafiliado.idcentroafiliado 
                         AND fa.idobrasocial = rnrosafiliado.idobrasocial 
LEFT JOIN far_mutual as mutu ON o.idobrasocial = mutu.idmutual
LEFT JOIN far_validacionitems as vi ON a.acodigobarra = vi.codbarras AND vi.idvalidacion = rarticuloinicial.idvalidacion AND vi.idcentrovalidacion = rarticuloinicial.idcentrovalidacion
LEFT JOIN far_validacion as v USING(idvalidacion,idcentrovalidacion)
LEFT JOIN adesfa_prepagas AS ap ON(v.fincodigo=ap.idadesfa_prepagas)
WHERE  idarticulo = rarticulo.idarticulo  AND idcentroarticulo = rarticulo.idcentroarticulo
and nullvalue(fechafinvigencia)
AND idfarmtipoventa <> 1 --MALAPI 04-11-2013 SOSUNC y AMUC no cubren los medicamentos de venta libre
AND (rnrosafiliado.idobrasocial = 1 OR not nullvalue(mutu.idmutual))
AND (ap.idobrasocial <> 1 OR nullvalue(ap.idobrasocial)) 
--Si se valida por sosunc, la cobertura se cubre usando el item de validacion

);

-- Ingreso la cobertura SIN OBRA SOCIAL

INSERT INTO far_plancoberturamedicamentoafiliadounificado(idarticulo,idcentroarticulo,idobrasocial,idplancobertura,idafiliado,idcentroafiliado,mnroregistro,prioridad,porccob,montofijo,pcdescripcion,detalle,codautorizacion) (
select  m.idarticulo, 
	m.idcentroarticulo, 
	999::bigint as idobrasocial,
	0::bigint as idplancobertura,
	rnrosafiliado.idafiliado,
	rnrosafiliado.idcentroafiliado,
	m.mnroregistro,	
 	99 as prioridad,	
	1::double precision as porcCob,
	0.0::double precision as montoFijo,
	'A cargo del Afiliado' as pcdescripcion,
	'0-A Cargo del Afiliado' as detalle,
	'0' as codautorizacion
FROM far_afiliado  as fa
CROSS JOIN (select * from far_articulo
            LEFT JOIN far_medicamento USING(idarticulo,idcentroarticulo)
            WHERE idarticulo = rarticulo.idarticulo  AND idcentroarticulo = rarticulo.idcentroarticulo) as m
WHERE fa.idafiliado = rnrosafiliado.idafiliado 
      AND fa.idcentroafiliado = rnrosafiliado.idcentroafiliado 
      AND fa.idobrasocial = rnrosafiliado.idobrasocial 
      AND rnrosafiliado.idobrasocial  = 9 -- Sin Obra Social

);

FETCH cnrosafiliado into rnrosafiliado;
END LOOP;
CLOSE cnrosafiliado;

-- Para los casos donde solo se estan verificando precios, no se envia nrodoc,tipodoc

IF nullvalue(rarticuloinicial.nrodoc) THEN

INSERT INTO far_plancoberturamedicamentoafiliadounificado(idarticulo,idcentroarticulo,idobrasocial,idplancobertura,idafiliado,idcentroafiliado,mnroregistro,prioridad,porccob,montofijo,pcdescripcion,detalle,codautorizacion) (
select  fa.idarticulo, 
	fa.idcentroarticulo, 
	999::bigint as idobrasocial,
	0::bigint as idplancobertura,
	null as idafiliado,
	null as idcentroafiliado,
	m.mnroregistro,	
 	99 as prioridad,	
	1::double precision as porcCob,
	0.0::double precision as montoFijo,
	'A cargo del Afiliado' as pcdescripcion,
	'0-A Cargo del Afiliado' as detalle,
	'0' as codautorizacion
FROM far_articulo  as fa
LEFT JOIN far_medicamento as m USING(idarticulo,idcentroarticulo)
WHERE idarticulo = rarticulo.idarticulo  
AND idcentroarticulo = rarticulo.idcentroarticulo

);

END IF;


FETCH carticulo into rarticulo;
END LOOP;
CLOSE carticulo;

for rcobinfomedi in SELECT 
  coberturas.idobrasocial,
  idplancobertura ,
  idafiliado ,
  coberturas.mnroregistro,
  prioridad ,
  porccob ,
  montofijo ,
  pcdescripcion ,
  coberturas.detalle as detallecob ,
  coberturas.codautorizacion ,
  case when nullvalue(tfar_articulo.cantvendida) then CASE WHEN nullvalue(vi.cantidadaprobada) THEN 0 ELSE vi.cantidadaprobada END else tfar_articulo.cantvendida END as cantidadaprobada,
  idarticulo ,
  idcentroarticulo ,
  idrubro ,
  adescripcion ,
  precio ,
  rdescripcion ,
  astockmin ,
  astockmax ,
  acomentario ,
  idiva ,
  adescuento ,
  acodigointerno ,
  acodigobarra ,
  f.detalle ,
  lstock ,
  troquel ,
  presentacion ,
  laboratorio ,
  idlaboratorio ,
  monodroga ,
  idmonodroga ,
  porciva  FROM far_plancoberturamedicamentoafiliadounificado as coberturas
           JOIN far_buscarinfomedicamentosteniendoclave(concat(coberturas.idarticulo,'-',coberturas.idcentroarticulo) ) as f
			USING(idarticulo,idcentroarticulo)
	   JOIN tfar_articulo USING(idarticulo,idcentroarticulo)
	   LEFT JOIN far_validacionitems as vi  ON  (f.acodigobarra = vi.codbarras 
                                                AND vi.idvalidacion = tfar_articulo.idvalidacion 
                                               AND vi.idcentrovalidacion = tfar_articulo.idcentrovalidacion )
ORDER BY prioridad


	loop
return next rcobinfomedi;
end loop;

end;$function$
