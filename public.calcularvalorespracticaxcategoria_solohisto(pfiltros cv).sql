CREATE OR REPLACE FUNCTION public.calcularvalorespracticaxcategoria_solohisto(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Calcula los valores de la practica segun la configuracion establecida
en la tabla practconvval*/

DECLARE
	--alta refcursor;
    --curcateg refcursor;
	--elem RECORD;
   -- rcateg RECORD;
	--anterior RECORD;
	--aux RECORD;
	--rpracticavalor RECORD;
	
	--valorh1 float4;
	--valorh2 float4;
	--valorh3 float4;    	
	--valorgs float4;	
	--importeprac float4;
--	verificar RECORD;
	--errores boolean;
   --     rusuario RECORD;    
     
	rfiltros  RECORD;
	resultado boolean;	
   	vidusuario INTEGER;   
	vcuantas RECORD;
	rfechafinvigencia DATE;
	vhisotorico INTEGER;
	vhisotoricovigente INTEGER;
	
	
BEGIN
--Vamos a calcular historicos solo para Categora A, pues parece que ya no se van a usar mas las categorias
--Se debe saber el historico de que asociacion y con que vigencia se quiere calcular
--Por el momento solo se puede usar para arreglar valores hisotiricos que son por unidad
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vidusuario = sys_dar_usuarioactual();

IF iftableexists('temporal_valores') THEN 
   DELETE FROM temporal_valores;
ELSE 
CREATE TEMP TABLE temporal_valores ( importeprac double precision,
    idusuario integer,     idnomenclador character varying,     idcapitulo character varying,     idsubcapitulo character varying,
    idpractica character varying,     valorh1 real,    idtvh1 integer,    valorh2 real,    idtvh2 integer,    valorh3 real,
    idtvh3 integer,     valorgs real, idtvgs integer, internacion boolean,  idasocconv bigint,    pcvfechainicio date,
    acvalorsindecimal boolean,    importe double precision,     pvfechainivigencia date,     pvfechafinvigencia date
   ,pcategoria character varying,fechainiciocalculado date,idtipounidadh1 real
);
END IF;

INSERT INTO temporal_valores (importeprac, idusuario, idnomenclador, idcapitulo, idsubcapitulo, idpractica, valorh1, idtvh1, valorh2, idtvh2, valorh3, idtvh3, valorgs, idtvgs, internacion, idasocconv, pcvfechainicio, acvalorsindecimal, importe, pvfechainivigencia, pvfechafinvigencia
							  ,pcategoria,fechainiciocalculado,idtipounidadh1) (
 SELECT CASE WHEN acvalorsindecimal THEN  round(tm.valorh1 + tm.valorh2 +  tm.valorh3 + tm.valorgs) ELSE round((tm.valorh1 + tm.valorh2 +  tm.valorh3 + tm.valorgs)::numeric,2) END as importeprac,vidusuario as idusuario
 ,idnomenclador, tm.idcapitulo, tm.idsubcapitulo, tm.idpractica, tm.valorh1, idtvh1, tm.valorh2, idtvh2, tm.valorh3, idtvh3, tm.valorgs, idtvgs, tm.internacion, tm.idasocconv, pcvfechainicio, acvalorsindecimal
 ,pv.importe,pv.pvxcfechainivigencia,pv.pvxcfechafinvigencia,tm.pcategoria,tm.fechainiciocalculado,tm.idtipounidadh1
 FROM ( select nomen.idnomenclador,nomen.idcapitulo,nomen.idsubcapitulo,nomen.idpractica
                ,case when practconvval.fijoh1 then practconvval.h1 else honorario1 * cantidad1  * obtenervalorxcategoria_convigencia(pcategoria,h1,idasocconv,rfiltros.fechavigencia) end as valorh1
                     ,practconvval.idtvh1
                     ,case when practconvval.fijoh2 then practconvval.h2 else honorario2 * cantidad2 * obtenervalorxcategoria_convigencia(pcategoria,h2,idasocconv,rfiltros.fechavigencia) end as valorh2
                     ,practconvval.idtvh2
                     ,case when practconvval.fijoh3 then practconvval.h3 else honorario3 * cantidad3 * obtenervalorxcategoria_convigencia(pcategoria,h3,idasocconv,rfiltros.fechavigencia) end as valorh3
                     ,practconvval.idtvh3
                     ,case when practconvval.fijogs then practconvval.h3 else honorariogs * cantigasto * obtenervalorxcategoria_convigencia(pcategoria,gasto,idasocconv,rfiltros.fechavigencia) end as valorgs
		             ,practconvval.idtvgs
                     ,practconvval.internacion
                     ,practconvval.idasocconv::bigint as idasocconv
                     ,practconvval.pcvfechainicio
		             ,acvalorsindecimal
 	                 ,pcategoria
	      			 ,rfiltros.fechavigencia as fechainiciocalculado
	   				 ,case when not practconvval.fijoh1 then practconvval.h1 else 0 END as idtipounidadh1
                     from nomenclador_config as nomen
		             NATURAL JOIN practica
                     Natural Join practconvval
                     NATURAL JOIN ( SELECT idasocconv::varchar, CASE WHEN nullvalue(acvalorsindecimal) THEN false ELSE acvalorsindecimal END as acvalorsindecimal FROM asocconvenio  WHERE acactivo AND (acfechafin >= current_date OR nullvalue(acfechafin) ) GROUP BY idasocconv, acvalorsindecimal ) as asocconvenio 
                     --LEFT JOIN practconvvalcantidad USING(idpractconvval, idasocconv, idsubcapitulo, idcapitulo, idpractica, idnomenclador, internacion)
                     ,(SELECT * FROM prestadorcategoria WHERE pcategoria = 'A') as pc
	        WHERE practica.activo 
		    AND practconvval.tvvigente
                    --AND (pcvfechamodifica ilike concat('%',pechaingreso,'%')  )
                    AND idasocconv = rfiltros.idasocconv 
) as tm
LEFT JOIN practicavaloresxcategoria as pv ON (pv.idasocconv = tm.idasocconv AND pv.idsubespecialidad = tm.idnomenclador AND pv.idcapitulo = tm.idcapitulo 
	AND pv.idsubcapitulo = tm.idsubcapitulo
	AND pv.idpractica = tm.idpractica
	AND pv.internacion = tm.internacion
	AND pv.pcategoria = tm.pcategoria
													            
													            )

);

--MaLaPi 13-11-2023 Comento porque para bioquimicos no me da la unidad 140
--SELECT INTO vcuantas COUNT(*) as cuantas,max(idtipounidadh1) as ptipounidad
--FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion,t.idtipounidadh1
--   	   FROM temporal_valores as t
--	   WHERE t.importeprac > 0
--	 ) as c;

SELECT INTO vcuantas  cantidadxunidad as cuantas,idtipounidadh1 as ptipounidad
FROM (SELECT t.idasocconv,t.idtipounidadh1,count(*) as cantidadxunidad
   	   FROM temporal_valores as t
	   WHERE t.importeprac > 0
           AND idtipounidadh1  > 0
           GROUP BY  t.idasocconv,t.idtipounidadh1 
	 ) as c
ORDER BY cantidadxunidad DESC
limit 1;


RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: Tengo que procesar (%)',vcuantas;

SELECT INTO rfechafinvigencia min(tvinivigencia)
                         FROM tablavalores
                         NATURAL JOIN convenio
                         NATURAL JOIN asocconvenio
                         WHERE tablavalores.idtipounidad = vcuantas.ptipounidad
                               AND asocconvenio.idasocconv = rfiltros.idasocconv 
                               AND (nullvalue(convenio.cfinvigencia) OR convenio.cfinvigencia > CURRENT_DATE)
                               AND (nullvalue(asocconvenio.acfechafin) OR asocconvenio.acfechafin > CURRENT_DATE)
                               AND (nullvalue(tablavalores.tvfinvigencia) OR tablavalores.tvfinvigencia > rfiltros.fechavigencia)
							   AND  (tablavalores.tvinivigencia > rfiltros.fechavigencia );
RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: Fecha Fin si modifico Historico (%)',rfechafinvigencia;

--Obtengo el max de Historico antes de eliminarlo
SELECT INTO vhisotorico max(pvxchordenhistorico) FROM practicavaloresxcategoriahistorico
WHERE (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,pvxchfechainivigencia)
IN (
	SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.fechainiciocalculado
   	   FROM temporal_valores as t
	 WHERE t.importeprac > 0
);
IF FOUND THEN  --El historico existe
	RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: Existe Historico (%)',vhisotorico;
	
	 		   
	--Necesito saber si es el historico vigente
	SELECT INTO vhisotoricovigente min(pvxchordenhistorico) FROM practicavaloresxcategoriahistorico
	WHERE (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica)
	IN (
		SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica
		   FROM temporal_valores as t
		 WHERE t.importeprac > 0
	);
	RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: El Historico Vigente (%)',vhisotoricovigente;
	DELETE FROM practicavaloresxcategoriahistorico WHERE (idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,pvxchfechainivigencia)
	IN (
		SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.fechainiciocalculado
		   FROM temporal_valores as t
			WHERE t.importeprac > 0 
	);

	IF vhisotoricovigente = vhisotorico THEN --Es el Ultimo Vigente, por lo que hay que dejarlo Vigente
		INSERT INTO practicavaloresxcategoriahistorico(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion
		,pvxchfechainivigencia,pvxchidusuario,pvxchordenhistorico,pvxchfechafinvigencia)
		(SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
		 ,t.fechainiciocalculado,vidusuario,vhisotoricovigente,rfechafinvigencia
			 FROM temporal_valores as t
			 WHERE  t.importeprac > 0
		);  

	ELSE --No era el ulitmo, hay que dejarlo con el mismo valor de hisotorico que tenia antes
	     --Necesito saber cual es la fechafin del historico, pues no era el vigente
		INSERT INTO practicavaloresxcategoriahistorico(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion
		,pvxchfechainivigencia,pvxchidusuario,pvxchordenhistorico,pvxchfechafinvigencia)
		(SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
		 ,t.fechainiciocalculado,vidusuario,vhisotorico,rfechafinvigencia
			 FROM temporal_valores as t
			 WHERE  t.importeprac > 0
		); 

	END IF;

ELSE -- El historico no existe

INSERT INTO practicavaloresxcategoriahistorico(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion
		,pvxchfechainivigencia,pvxchidusuario,pvxchordenhistorico,pvxchfechafinvigencia)
		(SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
		 ,t.fechainiciocalculado,vidusuario,1 as historicovigente,rfechafinvigencia
			 FROM temporal_valores as t
			 WHERE  t.importeprac > 0
		); 
END IF;

--Hasy que Modificar el valor de la categoria
/*
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
*/
 

-- Si nullvalue(importe)  Hay que insertar la practica por primera vez
/*SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE nullvalue(t.importe) AND t.importeprac > 0 
	 ) as c;
RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: Voy a insertar las nuevas (%)',vcuantas;
IF vcuantas > 0 THEN
* INSERT INTO practicavaloresxcategoria(pcategoria,idasocconv,idsubespecialidad,idcapitulo,idsubcapitulo,idpractica,importe,internacion,pvxcfechainivigencia,pvxcidusuario)
                  (SELECT t.pcategoria,t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.importeprac,t.internacion
 ,t.pcvfechainicio,vidusuario
     FROM temporal_valores as t
     WHERE  nullvalue(t.importe) AND t.importeprac > 0
);
END IF;
*/
/*SELECT INTO vcuantas COUNT(*) 
FROM (SELECT t.idasocconv,t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,t.internacion
   	   FROM temporal_valores as t
       WHERE  t.importeprac = 0	) as c;
RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: Voy a Eliminar las que tienen importe en cero (%)',vcuantas;

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
*/

RAISE NOTICE 'calcularvalorespracticaxcategoria_solohisto: Listo Termine ';

resultado = 'true';
RETURN resultado;
END;
$function$
