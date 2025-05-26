CREATE OR REPLACE FUNCTION public.ampractconvval_verifica()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los valores de una practica en un convenio */
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

--Por si usaron comas para los decimales en lugar de puntos, los arreglos
UPDATE asistencial_practicavalores SET apvcantunidades=replace(apvcantunidades,',','.'), apvvalorunidad=replace(apvvalorunidad,',','.'),apvvalorfijo = replace(apvvalorfijo,',','.') WHERE nullvalue(apvprocesado);

--Si las practicas estan en un solo bloque, las separo
UPDATE asistencial_practicavalores SET idnomenclador=t.idnomenclador,idcapitulo=t.idcapitulo,idsubcapitulo=t.idsubcapitulo,idpractica=t.idpractica
FROM (
select 
--lpad(idnomenclador,2,'0')  as idnomenclador,lpad(idcapitulo,2,'0')   as idcapitulo,lpad(idsubcapitulo,2,'0')  as idsubcapitulo,lpad(idpractica,2,'0')   as idpractica,idpracticavalores  
split_part(apvcodigososunc,',',1) as idnomenclador
,split_part(apvcodigososunc,',',2) as idcapitulo
,split_part(apvcodigososunc,',',3) as idsubcapitulo
,split_part(apvcodigososunc,',',4) as idpractica
,idpracticavalores 
FROM asistencial_practicavalores
WHERE not nullvalue(apvcodigososunc)
      AND nullvalue(apvprocesado)
) as t
WHERE t.idpracticavalores = asistencial_practicavalores.idpracticavalores
AND nullvalue(apvprocesado);
 
--Arreglo las practicas
UPDATE asistencial_practicavalores SET idnomenclador=t.idnomenclador,idcapitulo=t.idcapitulo,idsubcapitulo=t.idsubcapitulo,idpractica=t.idpractica
FROM (
select lpad(idnomenclador,2,'0')  as idnomenclador,lpad(idcapitulo,2,'0')   as idcapitulo,lpad(idsubcapitulo,2,'0')  as idsubcapitulo,lpad(idpractica,2,'0')   as idpractica,idpracticavalores  
from asistencial_practicavalores
WHERE (length(idnomenclador) < 2 OR length(idcapitulo) < 2 OR length(idsubcapitulo) < 2 OR length(idpractica) < 2)
AND nullvalue(apvprocesado)
) as t
WHERE t.idpracticavalores = asistencial_practicavalores.idpracticavalores
AND nullvalue(apvprocesado);

--Busco el id del convenio y lo cargo
UPDATE asistencial_practicavalores SET apvidconvenio=t.idconvenio
FROM (SELECT convenio.idconvenio,idpracticavalores 
       FROM asistencial_practicavalores
       JOIN  convenio ON trim(apvconvenio) = trim(cdenominacion)
      WHERE  not nullvalue(apvconvenio) AND nullvalue(apvprocesado) 
 ) as t
WHERE t.idpracticavalores = asistencial_practicavalores.idpracticavalores
AND nullvalue(apvprocesado);
--Pongo en todas las tuplas el convenio
UPDATE asistencial_practicavalores SET apvidconvenio=t.apvidconvenio
FROM (
select DISTINCT apvidconvenio
from asistencial_practicavalores
WHERE not nullvalue(apvidconvenio) AND nullvalue(apvprocesado)
) as t
WHERE nullvalue(asistencial_practicavalores.apvidconvenio)
AND nullvalue(asistencial_practicavalores.apvprocesado);

-- Solo se modifican valores en caso de que estos ya existan y sean modificados
--NO se pueden cargar nuevoas unidades, las primeras veces hay que darlas de alta
-- Solo se modifican valores en caso de que estos ya existan y sean modificados
--NO se pueden cargar nuevoas unidades, las primeras veces hay que darlas de alta
--MaLaPi 13-10-2022 No se cargan mas unidades,se deben dar de alta por otro lugar
--DELETE FROM temptablavalores;
--INSERT INTO temptablavalores (pcategoria,accion,idconvenio,idtablavalor,idtipounidad,idtipovalor,tvinivigencia,tvfinvigencia) 			
--(select DISTINCT 'A' as pcategoria,'Modificar' as accion,tablavalores.idconvenio,idtablavalor,idtipounidad,replace(apvvalorunidad,',','.')::float as --idtipovalor,Current_date as tvinivigencia,null::date as tvfinvigencia
--from tablavalores
--NATURAL JOIN tipounidad 
--LEFT JOIN asistencial_practicavalores ON trim(tipounidad.tudescripcion) = trim(apvdescunidad)
--WHERE (nullvalue(tvfinvigencia) OR tvfinvigencia > current_Date) AND 
--	tablavalores.idconvenio = apvidconvenio
--		AND nullvalue(apvprocesado) 
--		AND replace(apvvalorunidad,',','.')::float <> idtipovalor
--);
--IF FOUND THEN 
--    PERFORM amtablavaloresv2();
--END IF;


--Para todos los valores con unidades, le asocio la unidad que corresponde usar en el calculo de valores
--MaLaPi 13-10-2022 Lo quito, pues cuando llamo me tengo que asegurar que la unidad es valida
--UPDATE asistencial_practicavalores SET apvidtipounidad = t.idtipounidad
--FROM (
--select *
--from tablavalores
--NATURAL JOIN tipounidad 
--LEFT JOIN asistencial_practicavalores ON trim(tipounidad.tudescripcion) = trim(apvdescunidad)
--WHERE (nullvalue(tvfinvigencia) OR tvfinvigencia > current_Date) AND 
--	tablavalores.idconvenio = apvidconvenio
--		AND nullvalue(apvprocesado) 
--		AND replace(apvvalorunidad,',','.')::float = idtipovalor
--) as t
--WHERE t.idpracticavalores = asistencial_practicavalores.idpracticavalores
--AND not nullvalue(asistencial_practicavalores.apvdescunidad);


--Pongo todos los valores de la unidades para 
--MaLaPi 17-10-2018 No se usa mas, puesto que si el valor es con unidades no se trata mas como un valor fijo
--UPDATE asistencial_practicavalores SET apvvalorunidad=t.idtipovalor
--FROM (
--select idtipovalor
--from tablavalores 
--LEFT JOIN asistencial_practicavalores ON tablavalores.idconvenio = apvidconvenio
--		WHERE (nullvalue(tvfinvigencia) OR tvfinvigencia < current_Date) AND 
--		nullvalue(apvprocesado) AND not nullvalue(apvidconvenio) AND 
--		replace(apvvalorunidad,',','.')::float = idtipovalor
--		AND nullvalue(asistencial_practicavalores.apvdescunidad)
--) as t;

--Pongo en cero las cantidades de las que hay que desactivar, para que el valor me de cero
UPDATE asistencial_practicavalores SET apvcantunidades=0
WHERE not nullvalue(apvdesactivar) AND nullvalue(apvprocesado);
--Pongo en 1 las cantidades que no estan cargadas para que no me afecten el valor de la practica
--Pongo en cero las cantidades de las que hay que desactivar, para que el valor me de cero
UPDATE asistencial_practicavalores SET apvcantunidades=1
WHERE nullvalue(apvdesactivar) 
AND nullvalue(apvcantunidades) AND nullvalue(apvprocesado);


--MaLaPi 23-09-2019 Cargo las practicas configuradas con asterisco. Por el momento solo soporta asterisco en  el idpractica
SELECT INTO aux * FROM asistencial_practicavalores WHERE not nullvalue(apvidconvenio) AND nullvalue(apvprocesado) LIMIT 1;
IF FOUND THEN
INSERT INTO asistencial_practicavalores (idnomenclador,idcapitulo,idsubcapitulo,idpractica,
apvcantunidades,apvvalorunidad,apviniciovigencia,apvprocesado,apvidconvenio,apvidusuario,
apvcodigososunc,apvcodigoconvenio,apvdescripcionpractica,apvdescunidad,apvvalorfijo,apvconvenio,
apvidtipounidad,apvsolounidad,apvcategoriaunidad,apvfechaingreso)
 (
SELECT t.idnomenclador,t.idcapitulo,t.idsubcapitulo,t.idpractica,
apvcantunidades,apvvalorunidad,apviniciovigencia,apvprocesado,apvidconvenio,apvidusuario,
concat(t.idnomenclador,',',t.idcapitulo,',',t.idsubcapitulo,',',t.idpractica) as apvcodigososunc,
apvcodigoconvenio,apvdescripcionpractica,apvdescunidad,apvvalorfijo,apvconvenio,
apvidtipounidad,apvsolounidad,apvcategoriaunidad,apvfechaingreso
FROM asistencial_practicavalores
JOIN (
SELECT idnomenclador,idsubcapitulo,idcapitulo,idpractica	
FROM practconvval 
JOIN asocconvenio ON asocconvenio.idasocconv = practconvval.idasocconv 
WHERE asocconvenio.idconvenio = aux.apvidconvenio 
AND (fijoh1 AND fijoh2 AND fijoh3 AND fijogs) AND tvvigente
) as t USING(idnomenclador,idsubcapitulo,idcapitulo)
WHERE  asistencial_practicavalores.idpractica = '**' AND apvfechaingreso = aux.apvfechaingreso
);

END IF;


--Marco los errores
UPDATE asistencial_practicavalores SET apverror = concat(apverror,'/La practica en Sosunc no se encontro')
WHERE nullvalue(idnomenclador) OR nullvalue(idcapitulo) OR nullvalue(idsubcapitulo) OR nullvalue(idpractica) OR idpractica = '**'
AND nullvalue(apvprocesado);

UPDATE asistencial_practicavalores SET apverror = concat(apverror,'/No se encontro un convenio con esa descripcion')
WHERE nullvalue(apvidconvenio) 
AND nullvalue(apvprocesado);

UPDATE asistencial_practicavalores SET apverror = concat(apverror,'/La descripcion de la unidad, no se encontro configurada')
WHERE not nullvalue(apvdescunidad)  AND nullvalue(apvidtipounidad)
AND nullvalue(apvprocesado);


UPDATE asistencial_practicavalores SET apverror = concat(apverror,'/Los datos necesarios para darle un valor a la practica, no se encontraron ')
WHERE nullvalue(apvvalorfijo)  AND nullvalue(apvidtipounidad)
AND nullvalue(apvprocesado);


resultado = 'true';
RETURN resultado;
END;
$function$
