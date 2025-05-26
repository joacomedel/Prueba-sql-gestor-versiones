CREATE OR REPLACE FUNCTION public.calcularvalorespracticaxcategoria_masivo(pechaingreso timestamp without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Calcula los valores de la practica segun la configuracion establecida
en la tabla practconvval*/

DECLARE
	alta refcursor;
    curcateg refcursor;
	elem RECORD;
    rcateg RECORD;
	anterior RECORD;
	aux RECORD;
	rpracticavalor RECORD;
	resultado boolean;
	valorh1 float4;
	valorh2 float4;
	valorh3 float4;    	
	valorgs float4;	
	importeprac float4;
	verificar RECORD;
	errores boolean;
        rusuario RECORD;    
        rsindecimal  RECORD;
		
   vidusuario INTEGER;   
	--errores boolean;
	vcuantas integer;
	
BEGIN

vidusuario = sys_dar_usuarioactual();

IF iftableexists('temporal_valores') THEN 
   DELETE FROM temporal_valores;
ELSE 
CREATE TEMP TABLE temporal_valores ( importeprac double precision,
    idusuario integer,     idnomenclador character varying,     idcapitulo character varying,     idsubcapitulo character varying,
    idpractica character varying,     valorh1 real,    idtvh1 integer,    valorh2 real,    idtvh2 integer,    valorh3 real,
    idtvh3 integer,     valorgs real, idtvgs integer, internacion boolean,  idasocconv bigint,    pcvfechainicio date,
    acvalorsindecimal boolean,    importe double precision,     pvfechainivigencia date,     pvfechafinvigencia date
   ,pcategoria character varying
);
END IF;

INSERT INTO temporal_valores (importeprac, idusuario, idnomenclador, idcapitulo, idsubcapitulo, idpractica, valorh1, idtvh1, valorh2, idtvh2, valorh3, idtvh3, valorgs, idtvgs, internacion, idasocconv, pcvfechainicio, acvalorsindecimal, importe, pvfechainivigencia, pvfechafinvigencia,pcategoria) (
 SELECT CASE WHEN acvalorsindecimal THEN  round(tm.valorh1 + tm.valorh2 +  tm.valorh3 + tm.valorgs) ELSE round((tm.valorh1 + tm.valorh2 +  tm.valorh3 + tm.valorgs)::numeric,2) END as importeprac,25 as idusuario
 ,idnomenclador, tm.idcapitulo, tm.idsubcapitulo, tm.idpractica, tm.valorh1, idtvh1, tm.valorh2, idtvh2, tm.valorh3, idtvh3, tm.valorgs, idtvgs, tm.internacion, tm.idasocconv, pcvfechainicio, acvalorsindecimal
 ,pv.importe,pv.pvxcfechainivigencia,pv.pvxcfechafinvigencia,tm.pcategoria
 FROM ( select nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,nomen.idpractica
                ,case when practconvval.fijoh1 then practconvval.h1 else honorario1 * (CASE WHEN not nullvalue(practconvvalcantidad.cantidadh1) 
				AND practconvvalcantidad.cantidadh1 > 1 
				AND not practconvval.fijoh1 --Si el valor es fijo ya se multiplico por la cantidad
				THEN practconvvalcantidad.cantidadh1 ELSE nomen.cantidad1 END)  * obtenervalorxcategoria(pcategoria,h1,idasocconv) end as valorh1
                     ,practconvval.idtvh1
                     ,case when practconvval.fijoh2 then practconvval.h2 else honorario2 * cantidad2 * obtenervalorxcategoria(pcategoria,h2,idasocconv) end as valorh2
                     ,practconvval.idtvh2
                     ,case when practconvval.fijoh3 then practconvval.h3 else honorario3 * cantidad3 * obtenervalorxcategoria(pcategoria,h3,idasocconv) end as valorh3
                     ,practconvval.idtvh3
                     ,case when practconvval.fijogs then practconvval.h3 else honorariogs * cantigasto * obtenervalorxcategoria(pcategoria,gasto,idasocconv) end as valorgs
		     ,practconvval.idtvgs
                     ,practconvval.internacion
                     ,practconvval.idasocconv::bigint as idasocconv
                     ,practconvval.pcvfechainicio
		     ,acvalorsindecimal
--,false as acvalorsindecimal
	                 ,pcategoria
                     from nomenclador_config as nomen
		             NATURAL JOIN practica
                     Natural Join practconvval
                     NATURAL JOIN ( SELECT idasocconv::varchar, CASE WHEN /*nullvalue*/(acvalorsindecimal)is null  THEN false ELSE acvalorsindecimal END as acvalorsindecimal FROM asocconvenio  WHERE acactivo AND (acfechafin >= current_date OR /*nullvalue*/(acfechafin)is null ) GROUP BY idasocconv, acvalorsindecimal ) as asocconvenio 
                     LEFT JOIN practconvvalcantidad USING(idpractconvval, idasocconv, idsubcapitulo, idcapitulo, idpractica, idnomenclador, internacion)
                     ,prestadorcategoria           
	        WHERE practica.activo 
		    AND practconvval.tvvigente
                    AND (pcvfechamodifica ilike concat('%',pechaingreso,'%')  )
                    --AND idasocconv = 129 AND idnomenclador = '14'  
) as tm
LEFT JOIN practicavaloresxcategoria as pv ON (pv.idasocconv = tm.idasocconv AND pv.idsubespecialidad = tm.idnomenclador AND pv.idcapitulo = tm.idcapitulo 
                                                                 AND pv.idsubcapitulo = tm.idsubcapitulo
                                                                 AND pv.idpractica = tm.idpractica
                                                                 AND pv.internacion = tm.internacion
			                                         AND pv.pcategoria = tm.pcategoria
													            
													            )

);

SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
	 ) as c;
RAISE NOTICE 'calcularvalorespracticaxcategoria_masivo: Tengo que procesar (%)',vcuantas;


-- Si importeprac <> importe Hay que guardar historico y agregar el nuevo
SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE t.importeprac <> t.importe
	 ) as c;
RAISE NOTICE 'calcularvalorespracticaxcategoria_masivo: Voy a Modificar existentes (%)',vcuantas;

IF vcuantas > 0 THEN

--MaLaPi 06-10-2022 Se empieza a guardar el orden de los historicos para saber cuales son los ultimos N. 
UPDATE practicavaloresxcategoriahistorico SET pvxchordenhistorico = pvxchordenhistorico + 1 
WHERE (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,pcategoria,internacion)
IN (
   SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.pcategoria,t.internacion
   FROM temporal_valores as t
   WHERE  t.importeprac <> t.importe
);

--Guardo en el Historico: el nuevo se deja como el ultimo historico, es decir, con fecha pvxchfechafin en null y el anterior se coloca fecha actual. 
UPDATE practicavaloresxcategoriahistorico SET pvxchfechafin = now(),pvxchfechafinvigencia = tt.pcvfechainicio
FROM 
(SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.pcategoria,t.internacion,t.pcvfechainicio
     FROM temporal_valores as t
     WHERE  t.importeprac <> t.importe
) as tt
WHERE practicavaloresxcategoriahistorico.idasocconv = tt.idasocconv AND practicavaloresxcategoriahistorico.idsubespecialidad = tt.idnomenclador 
  AND practicavaloresxcategoriahistorico.idcapitulo = tt.idcapitulo
  AND practicavaloresxcategoriahistorico.idsubcapitulo = tt.idsubcapitulo 
  AND practicavaloresxcategoriahistorico.idpractica = tt.idpractica
  AND practicavaloresxcategoriahistorico.internacion = tt.internacion
  AND practicavaloresxcategoriahistorico.pcategoria = tt.pcategoria
  AND nullvalue(practicavaloresxcategoriahistorico.pvxchfechafin)
  ;

INSERT INTO practicavaloresxcategoriahistorico(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion
,pvxchfechainivigencia,pvxchidusuario)
(SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
 ,t.pcvfechainicio,vidusuario
     FROM temporal_valores as t
     WHERE  t.importeprac <> t.importe AND t.importeprac > 0
);  

--Hasy que Modificar el valor de la categoria

 UPDATE practicavaloresxcategoria SET pvxcfechaini = now(), importe = tt.importeprac ,pvxcidusuario = vidusuario , pvxcfechainivigencia = tt.pcvfechainicio  
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.pcategoria,t.internacion,t.pcvfechainicio,t.importeprac 
     FROM temporal_valores as t
     WHERE  t.importeprac <> t.importe  AND t.importeprac > 0
) as tt
  WHERE practicavaloresxcategoria.idasocconv = tt.idasocconv
  AND practicavaloresxcategoria.idsubespecialidad = tt.idnomenclador
  AND practicavaloresxcategoria.idcapitulo = tt.idcapitulo
  AND practicavaloresxcategoria.idsubcapitulo = tt.idsubcapitulo
  AND practicavaloresxcategoria.idpractica = tt.idpractica
  AND practicavaloresxcategoria.pcategoria = tt.pcategoria
  AND practicavaloresxcategoria.internacion = tt.internacion;



 
END IF;
-- Si nullvalue(importe)  Hay que insertar la practica por primera vez
SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE /*nullvalue*/(t.importe)is null AND t.importeprac > 0 
	 ) as c;
RAISE NOTICE 'calcularvalorespracticaxcategoria_masivo: Voy a insertar las nuevas (%)',vcuantas;

IF vcuantas > 0 THEN
  INSERT INTO practicavaloresxcategoriahistorico(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion
,pvxchfechainivigencia,pvxchidusuario)
 (SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
 ,t.pcvfechainicio,vidusuario
     FROM temporal_valores as t
     WHERE  /*nullvalue*/(t.importe)is null AND t.importeprac > 0
);  
  

 INSERT INTO practicavaloresxcategoria(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,pvxcfechainivigencia,pvxcidusuario)
                  (SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
 ,t.pcvfechainicio,vidusuario
     FROM temporal_valores as t
     WHERE  /*nullvalue*/(t.importe)is null AND t.importeprac > 0
);
            
  
END IF;

SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE  t.importeprac = 0	) as c;
RAISE NOTICE 'calcularvalorespracticaxcategoria_masivo: Voy a Eliminar las que tienen importe en cero (%)',vcuantas;

IF vcuantas > 0 THEN 
-- Si importeprac = 0 No se hace nada, pues ya coloco fecha al ultimo historico

UPDATE practicavaloresxcategoria SET  pvxcfechafin = now(), pvxcfechafinvigencia  = tt.pcvfechainicio  
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.pcategoria,t.internacion,t.pcvfechainicio,t.importeprac 
     FROM temporal_valores as t
     WHERE  t.importeprac <> t.importe  AND t.importeprac > 0
) as tt
  WHERE practicavaloresxcategoria.idasocconv = tt.idasocconv
  AND practicavaloresxcategoria.idsubespecialidad = tt.idnomenclador
  AND practicavaloresxcategoria.idcapitulo = tt.idcapitulo
  AND practicavaloresxcategoria.idsubcapitulo = tt.idsubcapitulo
  AND practicavaloresxcategoria.idpractica = tt.idpractica
  AND practicavaloresxcategoria.pcategoria = tt.pcategoria
  AND practicavaloresxcategoria.internacion = tt.internacion;



END IF;


RAISE NOTICE 'calcularvalorespracticaxcategoria_masivo: Listo Termine ';

resultado = 'true';
RETURN resultado;
END;
$function$
