CREATE OR REPLACE FUNCTION public.ampractconvval_solounidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*Ingresa o Actualiza los valores de una practica en un convenio */
/*ampractconvval()*/
DECLARE
	alta refcursor; -- FOR SELECT * FROM temppractconvval WHERE nullvalue(temppractconvval.error) ORDER BY temppractconvval.idasocconv;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	rconvenio RECORD;
	resultado boolean;
	idconvenio bigint;
	verificar RECORD;
	deno_anterior bigint;
	idpracticavalor bigint;
	errores boolean;
        rusuario RECORD; 
BEGIN


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

UPDATE asistencial_practicavalores SET apverror = '' WHERE apvsolounidad AND nullvalue(apvprocesado);

--Por si usaron comas para los decimales en lugar de puntos, los arreglos
UPDATE asistencial_practicavalores SET apvvalorunidad=replace(apvvalorunidad,',','.')
WHERE apvsolounidad AND nullvalue(apvprocesado);

--Busco el id del convenio y lo cargo
UPDATE asistencial_practicavalores SET apvidconvenio=t.idconvenio
FROM (SELECT convenio.idconvenio,idpracticavalores 
       FROM asistencial_practicavalores
       JOIN  convenio ON trim(apvconvenio) = trim(cdenominacion)
      WHERE  not nullvalue(apvconvenio) AND nullvalue(apvprocesado) 
 ) as t
WHERE t.idpracticavalores = asistencial_practicavalores.idpracticavalores
	AND apvsolounidad AND nullvalue(apvprocesado);

--Pongo en todas las tuplas el convenio
UPDATE asistencial_practicavalores SET apvidconvenio=t.apvidconvenio
FROM (
select DISTINCT apvidconvenio
from asistencial_practicavalores
WHERE not nullvalue(apvidconvenio) AND nullvalue(apvprocesado)
) as t
WHERE nullvalue(asistencial_practicavalores.apvidconvenio)
	AND apvsolounidad AND nullvalue(apvprocesado);

-- Solo se modifican valores en caso de que estos ya existan y sean modificados
--NO se pueden cargar nuevoas unidades, las primeras veces hay que darlas de alta
DELETE FROM temptablavalores;
INSERT INTO temptablavalores (pcategoria,accion,idconvenio,idtablavalor,idtipounidad,idtipovalor,tvinivigencia,tvfinvigencia) 			
(select DISTINCT apvcategoriaunidad as pcategoria,'Modificar' as accion,tablavalores.idconvenio,idtablavalor,idtipounidad,replace(apvvalorunidad,',','.')::float as idtipovalor,Current_date as tvinivigencia,null::date as tvfinvigencia
from tablavalores
NATURAL JOIN tipounidad 
LEFT JOIN asistencial_practicavalores ON trim(tipounidad.tudescripcion) = trim(apvdescunidad)
WHERE (nullvalue(tvfinvigencia) OR tvfinvigencia > current_Date) AND 
	tablavalores.idconvenio = apvidconvenio
		AND nullvalue(apvprocesado) 
		AND replace(apvvalorunidad,',','.')::float <> idtipovalor
);
PERFORM amtablavaloresv2();

--Para todos los valores con unidades, le asocio la unidad que corresponde usar en el calculo de valores
UPDATE asistencial_practicavalores SET apvidtipounidad = t.idtipounidad
FROM (
select *
from tablavalores
NATURAL JOIN tipounidad 
LEFT JOIN asistencial_practicavalores ON trim(tipounidad.tudescripcion) = trim(apvdescunidad)
WHERE (nullvalue(tvfinvigencia) OR tvfinvigencia > current_Date) AND 
	tablavalores.idconvenio = apvidconvenio
		AND nullvalue(apvprocesado) 
		AND replace(apvvalorunidad,',','.')::float = idtipovalor
		AND apvsolounidad 
) as t
WHERE t.idpracticavalores = asistencial_practicavalores.idpracticavalores
AND not nullvalue(asistencial_practicavalores.apvdescunidad)
AND asistencial_practicavalores.apvsolounidad ;


UPDATE asistencial_practicavalores SET apverror = concat(apverror,'/No se encontro un convenio con esa descripcion')
WHERE nullvalue(apvidconvenio) 
AND nullvalue(apvprocesado)
AND apvsolounidad;

UPDATE asistencial_practicavalores SET apverror = concat(apverror,'/La descripcion de la unidad, no se encontro configurada')
WHERE not nullvalue(apvdescunidad)  AND nullvalue(apvidtipounidad)
AND nullvalue(apvprocesado)
AND apvsolounidad;

UPDATE asistencial_practicavalores SET apvprocesado =  now(),apvidusuario=rusuario.idusuario; --WHERE nullvalue(apverror);

resultado = 'true';
RETURN resultado;
END;
$function$
