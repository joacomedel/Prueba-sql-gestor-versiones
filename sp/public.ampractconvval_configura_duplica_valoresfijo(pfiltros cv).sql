CREATE OR REPLACE FUNCTION public.ampractconvval_configura_duplica_valoresfijo(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los datos de una nomenclador */
/*ampractconvval()*/
DECLARE
	alta refcursor; 
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
	--rpracticas RECORD;
	rconveniodestino RECORD;
        rusuario RECORD; 
        rfiltros RECORD;
BEGIN

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

		
SELECT INTO rconveniodestino * FROM asocconvenio  WHERE idasocconv = rfiltros.idasocconvdestino 
			AND (nullvalue(acfechafin) OR acfechafin >= current_date) LIMIT 1;

--MaLaPi 25-10-2019 Cargo el incremento para los valores que estan configurados como fijos
INSERT INTO asistencial_practicavalores (idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvdescripcionpractica,apviniciovigencia
,apvidconvenio
,apvvalorfijo
,apvcantunidades
,apvidusuario
,apidasocconv ) 
(
SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion as apvdescripcionpractica,pcvfechainicio as apviniciovigencia
,rconveniodestino.idconvenio as apvidconvenio
,CASE WHEN idtvh1 = 0 AND fijoh1 THEN h1 
	WHEN idtvh2 = 0 AND fijoh2 THEN h2
	WHEN idtvh3 = 0 AND fijoh3 THEN h3  
	WHEN idtvgs = 0 AND fijogs THEN gasto  
ELSE 0 END as apvvalorfijo
,1 as apvcantunidades
,rusuario.idusuario as apvidusuario
,rconveniodestino.idasocconv as apidasocconv
FROM practconvval
NATURAL JOIN practica 
WHERE activo AND CASE WHEN idtvh1 = 0 AND fijoh1 THEN h1 
	WHEN idtvh2 = 0 AND fijoh2 THEN h2
	WHEN idtvh3 = 0 AND fijoh3 THEN h3  
	WHEN idtvgs = 0 AND fijogs THEN gasto  
ELSE 0 END <> 0 AND practconvval.idasocconv = rfiltros.idasocconvorigen 
	AND tvvigente AND fijoh1 AND fijoh2 AND fijoh3 AND fijogs
);


-- Determino si hay incremento
IF rfiltros.idvaloricremento > 0 THEN 
UPDATE asistencial_practicavalores SET apvvalorfijo = round((apvvalorfijo::float * (1::float + rfiltros.idvaloricremento::float))::numeric,2) 
	WHERE  nullvalue(apvprocesado) AND nullvalue(apverror) AND apvvalorfijo::float > 0.01
	             AND apvidconvenio = rconveniodestino.idconvenio
	             AND not nullvalue(asistencial_practicavalores.apvvalorfijo);

END IF;
	

resultado = 'true';
RETURN resultado;
END;
$function$
