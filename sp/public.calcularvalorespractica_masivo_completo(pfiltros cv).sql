CREATE OR REPLACE FUNCTION public.calcularvalorespractica_masivo_completo(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
     --  cvalores refcursor;
     --  unvalor record;
        rfiltros RECORD;
		rverifica RECORD;
      --  vfiltroid varchar;
		--vusuario INTEGER;
BEGIN 

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;


SELECT INTO rverifica  count(*),text_concatenar(concat(fechaingreso,'<',cantidad,'>' , '#')) FROM (SELECT DISTINCT pcvfechamodifica as fechaingreso,count(*) as cantidad from practconvval  where pcvfechamodifica >=rfiltros.fechadesde GROUP BY pcvfechamodifica  
   ) as t  ;


 RAISE NOTICE 'Llamo a calcularvalorespractica_masivo (%) ',rverifica;
 
   PERFORM calcularvalorespractica_masivo(fechaingreso::timestamp) 
   FROM (SELECT DISTINCT pcvfechamodifica as fechaingreso,count(*) as cantidad from practconvval  where pcvfechamodifica >=rfiltros.fechadesde GROUP BY pcvfechamodifica  
   ) as t ORDER BY fechaingreso;


DROP TABLE  temporal_valores;

 RAISE NOTICE 'Llamo a calcularvalorespracticaxcategoria_masivo (%) ',rverifica;
 
 PERFORM calcularvalorespracticaxcategoria_masivo(fechaingreso::timestamp) 
 FROM (SELECT DISTINCT pcvfechamodifica as fechaingreso,count(*) as cantidad from practconvval  where pcvfechamodifica >=rfiltros.fechadesde GROUP BY pcvfechamodifica  
) as t ORDER BY fechaingreso ;
				
	RAISE NOTICE 'Listo... termine';
				
     return 'Listo';
END;
$function$
