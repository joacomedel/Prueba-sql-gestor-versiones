CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_asoc_desv(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
  alta refcursor;
  elem RECORD;

 

--VARIABLES
  vquery VARCHAR; 
  respuesta varchar;
  vcolumnas varchar;
  vwhere varchar;
  vreferencias varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;
  rrespuesta varchar;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

RAISE NOTICE 'rfiltros: (%) tuplas',rfiltros;
UPDATE asistencial_practicavalores SET apvprocesado =  now() WHERE nullvalue(apvprocesado);--Marco como procesado todo lo anterior

--1 - Limpio la tabla 
DELETE FROM migrarnomencladoryvalores_des;
--tabla = nomenclador_valorfijo_para_migrar, hoja=kinesio,fechainiciovigencia=2023-03-01

IF (rfiltros.tabla = 'nomenclador_valorfijo_para_migrar') THEN

--2 - Cargo la tabla para saber que limpiuar
OPEN alta FOR select concat('{codigopractica=',idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica,',asociaciones_siges=',asociaciones_siges,',accion=lala}') as param 
			FROM nomenclador_valorfijo_para_migrar
 			where nvfpmhoja_excel ilike rfiltros.hoja  
				AND fechainiciovigencia = rfiltros.fechainiciovigencia;
FETCH alta INTO elem;
WHILE  found LOOP

PERFORM convenios_migrarnomencladoryvalores_asoc_desv_inter(elem.param);

SELECT INTO respuesta count(*) FROM migrarnomencladoryvalores_des;

RAISE NOTICE 'Termine el pasos 2,asistencial_cargarvaloresasocexpendio Respuesta: (%,%) tuplas',elem.param,respuesta;

FETCH alta INTO elem;
END LOOP;
CLOSE alta;

END IF;

IF (rfiltros.tabla = 'nomenclador_para_migrar') THEN

--2 - Cargo la tabla para saber que limpiuar
OPEN alta FOR select DISTINCT concat('{codigopractica=',idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica,',asociaciones_siges=',asociaciones_siges,',accion=lala}') as param 
			FROM nomenclador_para_migrar
 			where idnomenclador = rfiltros.idnomenclador
			    AND idcapitulo = rfiltros.idcapitulo
				AND (idsubcapitulo = rfiltros.idsubcapitulo OR rfiltros.idsubcapitulo = '**')
				AND (idpractica = rfiltros.idpractica OR rfiltros.idpractica = '**')
				AND npmfechainiciovigencia = rfiltros.fechainiciovigencia;
FETCH alta INTO elem;
WHILE  found LOOP

PERFORM convenios_migrarnomencladoryvalores_asoc_desv_inter(elem.param);

SELECT INTO respuesta count(*) FROM migrarnomencladoryvalores_des;

RAISE NOTICE 'Termine el pasos 2,asistencial_cargarvaloresasocexpendio Respuesta: (%,%) tuplas',elem.param,respuesta;

FETCH alta INTO elem;
END LOOP;
CLOSE alta;

END IF;

IF (rfiltros.tabla = 'nomenclador_tipounidad_para_migrar') THEN

--2 - Cargo la tabla para saber que limpiuar
OPEN alta FOR select DISTINCT concat('{codigopractica=',idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica,',asociaciones_siges=',asociaciones_siges,',accion=lala}') as param 
			FROM nomenclador_tipounidad_para_migrar
                        JOIN tipounidad ON tudescripcion = trim(tipounidad)
                        JOIN practconvval ON (tvvigente AND not internacion AND fechainiciovigencia = pcvfechainicio AND ((not fijoh1 AND h1 = idtipounidad) OR (not fijogs AND gasto = idtipounidad)) )
 			where idnomenclador = rfiltros.idnomenclador
			    AND idcapitulo = rfiltros.idcapitulo
				AND (idsubcapitulo = rfiltros.idsubcapitulo OR rfiltros.idsubcapitulo = '**')
			        AND (idpractica = rfiltros.idpractica OR rfiltros.idpractica = '**')
				AND  fechainiciovigencia = rfiltros.fechainiciovigencia;
FETCH alta INTO elem;
WHILE  found LOOP

PERFORM convenios_migrarnomencladoryvalores_asoc_desv_inter(elem.param);

SELECT INTO respuesta count(*) FROM migrarnomencladoryvalores_des;

RAISE NOTICE 'Termine el pasos 2,asistencial_cargarvaloresasocexpendio Respuesta: (%,%) tuplas',elem.param,respuesta;

FETCH alta INTO elem;
END LOOP;
CLOSE alta;

END IF;


--select * from nomenclador_para_migrar where idcapitulo = '34' and activo ilike 'si' AND npmfechainiciovigencia = '2023-03-01'


--2 -  -- Para cargar la configuracion del histórico de valores

INSERT INTO asistencial_practicavalores (soloidasocconv,idnomenclador, idcapitulo, idsubcapitulo, idpractica, apvpdescripcion, apvcantunidades, apviniciovigencia, apvidconvenio,apidasocconv,apvcodigososunc,apvdescripcionpractica,apvvalorfijo,apvfechaingreso,apvtexto) (
select 'si' as soloidasocconv,c.idnomenclador, c.idcapitulo, c.idsubcapitulo, c.idpractica, c.pdescripcion as apvpdescripcion,1 as apvcantunidades
,CASE WHEN nullvalue(c.fechainivigencia) THEN now() ELSE fechainivigencia END as apviniciovigencia
, null as apvidconvenio, c.idasocconv::bigint as apidasocconv
, concat(c.idnomenclador,'.',c.idcapitulo,'.',c.idsubcapitulo,'.',c.idpractica) as apvcodigososunc
,pdescripcion as apvdescripcionpractica,valorexpendio as apvvalorfijo, now() as apvfechaingreso,c.asocinvolucradas
from migrarnomencladoryvalores_des as c
where  idcvpprimary > 1

);

RAISE NOTICE 'Termine el pasos 2, cargue en la tabla migrarnomencladoryvalores_des : (%)',respuesta;

--MaLaPi 05-05-2023 Verifico si solo se envio la asociaiocn, completo el convenio

UPDATE asistencial_practicavalores SET apvidconvenio = t.idconvenio 
FROM (
    SELECT  max(idconvenio) as idconvenio ,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE acactivo AND (acfechafin >= current_date OR nullvalue(acfechafin))
				AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
GROUP BY idasocconv
) as t
WHERE soloidasocconv = 'si' AND nullvalue(apvidconvenio) 
AND t.idasocconv = apidasocconv
AND nullvalue(apvprocesado)  AND nullvalue(apverror);


SELECT INTO respuesta * from ampractconvval_configura();

RAISE NOTICE 'Termine el pasos 3, ampractconvval_configura : (%)',respuesta;

vquery = concat('select * from  calcularvalorespractica();','select * from   calcularvalorespracticaxcategoria();');

RAISE NOTICE 'Termine los primeros 3 pasos, recordar que falta: (%)',vquery;

return respuesta;
END;
$function$
