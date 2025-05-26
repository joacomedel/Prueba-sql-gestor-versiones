CREATE OR REPLACE FUNCTION public.calcularvalorespractica_masivo(ppcvfechaingreso timestamp without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Calcula los valores de la practica segun la configuracion establecida
en la tabla practconvval
SELECT calcularvalorespractica_masivo('2022-10-21 01:11:49'::timestamp);
*/

DECLARE
	--alta refcursor; 
	--elem RECORD;
	--anterior RECORD;
	--aux RECORD;
	--rpracticavalor RECORD;
	resultado boolean;
	--valorh1 float4;
	--valorh2 float4;
	--valorh3 float4;    	
	--valorgs float4;	
	--importeprac float4;
	--verificar RECORD;
    vidusuario INTEGER;   
	errores boolean;
	vcuantas integer;
	--rsindecimal  RECORD;
	rfiltros RECORD;
BEGIN

--EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vidusuario = sys_dar_usuarioactual();

IF iftableexists('temporal_valores') THEN 
   DELETE FROM temporal_valores;
ELSE 
CREATE TEMP TABLE temporal_valores ( importeprac double precision,
    idusuario integer,     idnomenclador character varying,     idcapitulo character varying,     idsubcapitulo character varying,
    idpractica character varying,     valorh1 double precision,    idtvh1 integer,    valorh2 double precision,    idtvh2 integer,    valorh3 double precision,
    idtvh3 integer,     valorgs double precision, idtvgs integer, internacion boolean,  idasocconv bigint,    pcvfechainicio date,
    acvalorsindecimal boolean,    importe double precision,     pvfechainivigencia date,     pvfechafinvigencia date,
    tvactivo boolean
);
END IF;
--- VAS 22102024 se debe tomar la cantidad que se encuentra en la tabla practconvvalcantidad para los ay1 ay2 y los gastos de la misma manera que se hace ahora con h1

/* cantidad2 
(CASE WHEN not nullvalue(practconvvalcantidad.cantidadh2 ) 
				AND practconvvalcantidad.cantidadh2 > 1 
				AND not practconvval.fijoh2 --Si el valor es fijo ya se multiplico por la cantidad
				THEN practconvvalcantidad.cantidadh2 ELSE nomen.cantidad2 END)

cantidad3 
(CASE WHEN not nullvalue(practconvvalcantidad.cantidadh3 ) 
				AND practconvvalcantidad.cantidadh3 > 1 
				AND not practconvval.fijoh3 --Si el valor es fijo ya se multiplico por la cantidad
				THEN practconvvalcantidad.cantidadh3 ELSE nomen.cantidad3 END)

cantigasto 
(CASE WHEN not nullvalue(practconvvalcantidad.cantidadgasto ) 
				AND practconvvalcantidad.cantidadgasto > 1 
				AND not practconvval.fijogs --Si el valor es fijo ya se multiplico por la cantidad
				THEN practconvvalcantidad.cantidadgasto ELSE nomen.cantigasto END)
*/

INSERT INTO temporal_valores (importeprac, idusuario, idnomenclador, idcapitulo, idsubcapitulo, idpractica, valorh1, idtvh1, valorh2, idtvh2, valorh3, idtvh3, valorgs, idtvgs, internacion, idasocconv, pcvfechainicio, acvalorsindecimal, importe, pvfechainivigencia, pvfechafinvigencia,tvactivo) (
 SELECT CASE WHEN acvalorsindecimal THEN  round(valorh1 + valorh2 +  valorh3 + valorgs) ELSE round((valorh1 + valorh2 +  valorh3 + valorgs)::numeric,2) END as importeprac,25 as idusuario
 ,idnomenclador, tm.idcapitulo, tm.idsubcapitulo, tm.idpractica, valorh1, idtvh1, valorh2, idtvh2, valorh3, idtvh3, valorgs, idtvgs, tm.internacion, tm.idasocconv, pcvfechainicio, acvalorsindecimal
 ,pv.importe,pv.pvfechainivigencia,pv.pvfechafinvigencia,tm.activo
 FROM ( select nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,nomen.idpractica
                ,CASE WHEN practconvval.fijoh1 THEN practconvval.h1 
                      ELSE --VAS 2024-11-25 honorario1 * 
                           (CASE WHEN not nullvalue(practconvvalcantidad.cantidadh1) 
			              AND practconvvalcantidad.cantidadh1 > 1 
				 THEN practconvvalcantidad.cantidadh1 --- tiene conf dif NN
                                 ELSE nomen.cantidad1 * honorario1 END
                            )  * obtenervalorxcategoria('*',h1,idasocconv) end::double precision as valorh1
                 ,practconvval.idtvh1
                 ,CASE WHEN practconvval.fijoh2 THEN practconvval.h2   -- El valor es fijo y ya viene multiplicado por la cantidad
                       ELSE --VAS 2024-11-25 honorario2 * 
                            (CASE WHEN not nullvalue(practconvvalcantidad.cantidadh2 ) 
			               AND practconvvalcantidad.cantidadh2 > 1 				
				  THEN practconvvalcantidad.cantidadh2 --- tiene conf dif NN
                                  ELSE nomen.cantidad2 *honorario2 END
                             ) * obtenervalorxcategoria('*',h2,idasocconv) end::double precision as valorh2
                 ,practconvval.idtvh2
                 ,CASE WHEN practconvval.fijoh3 then practconvval.h3 
                       ELSE --VAS 2024-11-25 honorario3 *
                            (CASE WHEN not nullvalue(practconvvalcantidad.cantidadh3 ) 
			               AND practconvvalcantidad.cantidadh3 > 1
				  THEN practconvvalcantidad.cantidadh3 --- tiene conf dif NN
                                  ELSE nomen.cantidad3 *honorario3 END
                             ) * obtenervalorxcategoria('*',h3,idasocconv) end::double precision as valorh3
                     ,practconvval.idtvh3
                    
                 ,CASE WHEN practconvval.fijogs then practconvval.gasto 
                       ELSE  --VAS 2024-11-25 honorariogs * 
                             (CASE WHEN not nullvalue(practconvvalcantidad.cantidadgasto ) 
				        AND practconvvalcantidad.cantidadgasto > 1 --- tiene conf dif NN
                            
				   THEN practconvvalcantidad.cantidadgasto 

                              ELSE nomen.cantigasto * honorariogs END -- VAS en este caso no deberia entrar xq se debería habr cargado en la tabla practconvvalcantidad
                              ) * obtenervalorxcategoria('*',gasto,idasocconv) end::double precision as valorgs
		     ,practconvval.idtvgs
                     ,practconvval.internacion
                     ,practconvval.idasocconv::bigint as idasocconv
                     ,practconvval.pcvfechainicio
		     ,activo
                     ,acvalorsindecimal
                     from nomenclador_config as nomen
		     NATURAL JOIN practica
                     Natural Join practconvval
                     NATURAL JOIN ( SELECT idasocconv::varchar, CASE WHEN nullvalue(acvalorsindecimal) THEN false ELSE acvalorsindecimal END as acvalorsindecimal FROM asocconvenio  WHERE acactivo AND (acfechafin >= current_date OR nullvalue(acfechafin) ) GROUP BY idasocconv, acvalorsindecimal ) as asocconvenio 
                     JOIN practconvvalcantidad USING(idpractconvval, idasocconv, idsubcapitulo, idcapitulo, idpractica, idnomenclador, internacion)
                    WHERE 
                          practconvval.tvvigente
                          and pcvcfechafin is null --VAS 19-11-2024 Tomo solo la configuracion vigente. Tambien cambio el LEFT JOIN por JOIN

--                    AND idasocconv = 129 AND idnomenclador = '14'  
                         AND (pcvfechamodifica ilike concat('%',ppcvfechaingreso,'%') )
) as tm
LEFT JOIN practicavalores as pv ON (pv.idasocconv = tm.idasocconv AND pv.idsubespecialidad = tm.idnomenclador AND pv.idcapitulo = tm.idcapitulo 
                                                                 AND pv.idsubcapitulo = tm.idsubcapitulo
                                                                 AND pv.idpractica = tm.idpractica
                                                                 AND pv.internacion = tm.internacion)

);

SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
	 ) as c;
RAISE NOTICE 'calcularvalorespractica_masivo: Tengo que procesar (%)',vcuantas;

-- Si importeprac <> importe Hay que guardar historico y modificar el existente
SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE importeprac <> t.importe AND t.tvactivo
	 ) as c;
RAISE NOTICE 'calcularvalorespractica_masivo: Voy a Modificar existentes (%)',vcuantas;

IF vcuantas > 0 THEN
INSERT INTO practicavaloresmodificados(idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,fechamodif,pvmidusuario,pvmfechainivigencia,pvmfechafinvigencia)
( SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importe,t.internacion,now(),vidusuario,t.pvfechainivigencia,t.pvfechafinvigencia
   FROM temporal_valores as t
   WHERE  importeprac <> t.importe AND t.tvactivo
);

 UPDATE practicavalores SET importe = tt.importeprac,pvidusuario = vidusuario,pvfechainivigencia = tt.pcvfechainicio
 FROM ( 
 SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion,t.pcvfechainicio
   FROM temporal_valores as t
   WHERE  importeprac <> t.importe AND t.tvactivo
 ) as tt
 WHERE practicavalores.idasocconv = tt.idasocconv AND practicavalores.idsubespecialidad = tt.idnomenclador 
  AND practicavalores.idcapitulo = tt.idcapitulo
  AND practicavalores.idsubcapitulo = tt.idsubcapitulo AND practicavalores.idpractica = tt.idpractica AND practicavalores.internacion = tt.internacion;

END IF;
-- Si nullvalue(importe)  Hay que insertar la practica por primera vez

SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE /*nullvalue*/(t.importe)is null  AND t.importeprac > 0 AND t.tvactivo
	 ) as c;
RAISE NOTICE 'calcularvalorespractica_masivo: Voy a insertar las nuevas (%)',vcuantas;

IF vcuantas > 0 THEN
 INSERT INTO practicavalores (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,pvidusuario,pvfechainivigencia)
  (
	  SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion,vidusuario,t.pcvfechainicio
   	   FROM temporal_valores as t
       WHERE  /*nullvalue*/(t.importe)is null  AND t.importeprac > 0 AND t.tvactivo
  );
END IF;

SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE  t.importeprac = 0	 ) as c;
RAISE NOTICE 'calcularvalorespractica_masivo: Voy a Eliminar las que tienen importe en cero (%)',vcuantas;

IF vcuantas > 0 THEN 
-- Si importeprac = 0 Hay que eliminar la practica para la asociacion
DELETE FROM practicavalores WHERE (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,internacion) 
IN ( SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE  t.importeprac = 0	
);
END IF;

--Verifico las practicas que tienen valor pero para las que no existe una configuracion vigente, y las elimino

SELECT INTO vcuantas COUNT(*) 
FROM (SELECT * FROM practicavalores 
      LEFT JOIN  (
           select idpractconvval, idasocconv::integer, idsubcapitulo, idcapitulo, idpractica, idnomenclador as idsubespecialidad, internacion 
          from practconvval 
          NATURAL JOIN practica 
          where  tvvigente 
                 ) as config USING(idasocconv, idsubcapitulo, idcapitulo, idpractica, idsubespecialidad, internacion)
          WHERE /*nullvalue*/(config.idasocconv)is null 
 ) as c;

RAISE NOTICE 'calcularvalorespractica_masivo: Voy a Eliminar las que no tienen una configuracion vigente (%)',vcuantas;

IF vcuantas > 0 THEN 
--Guardo el ultimo valor en valores modificados
INSERT INTO practicavaloresmodificados(idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,fechamodif,pvmidusuario,pvmfechainivigencia,pvmfechafinvigencia)
( SELECT t.idasocconv,t.idsubespecialidad,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importe,t.internacion,now(),vidusuario,t.pvfechainivigencia,t.pvfechafinvigencia
   FROM practicavalores as t
      LEFT JOIN  (
           select idpractconvval, idasocconv::integer, idsubcapitulo, idcapitulo, idpractica, idnomenclador as idsubespecialidad, internacion 
          from practconvval 
          NATURAL JOIN practica 
          where  tvvigente 
                 ) as config USING(idasocconv, idsubcapitulo, idcapitulo, idpractica, idsubespecialidad, internacion)
          WHERE /*nullvalue*/(config.idasocconv)is null 
);

---- Luego lo elimino

DELETE FROM practicavalores WHERE (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,internacion) 
IN ( SELECT t.idasocconv,t.idsubespecialidad,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
      FROM practicavalores as t
      LEFT JOIN  (
           select idpractconvval, idasocconv::integer, idsubcapitulo, idcapitulo, idpractica, idnomenclador as idsubespecialidad, internacion 
          from practconvval 
          NATURAL JOIN practica 
          where  tvvigente 
                 ) as config USING(idasocconv, idsubcapitulo, idcapitulo, idpractica, idsubespecialidad, internacion)
          WHERE /*nullvalue*/(config.idasocconv)is null 

);
END IF;

RAISE NOTICE 'calcularvalorespractica_masivo: Listo Termine ';

resultado = 'true';
RETURN resultado;
END;
$function$
