CREATE OR REPLACE FUNCTION public.ampractconvval_configura()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Ingresa o Actualiza los valores de una practica en un convenio */
 
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

--Cargo la estructura necesaria para ingresar los valores como fijos
--idnomenclador,idcapitulo,idsubcapitulo,idpractica,idasocconv

IF iftableexists('temppractconvval') THEN 

ELSE

CREATE TEMP TABLE temppractconvval ( idpractconvval bigint,idsubcapitulo character varying,idcapitulo character varying,idpractica character varying,idnomenclador character varying,
					    idtvh1 integer default 0,
					    fijoh1 boolean default true,
					    h1 real, -- Es el que se va a usar para setear el valor fijo
					    idtvh2 integer default 0,
					    fijoh2 boolean default true,
					    h2 real default 0,
					    idtvh3 integer default 0,
					    fijoh3 boolean default true,
					    h3 real default 0,
					    idtvgs integer default 0,
					    fijogs boolean default true,
					    gasto real default 0,
					    internacion boolean default false,
					    error character varying,
					    idasocconv bigint,
					    cantidadh1 real,
						cantidadh2 real,
						cantidadh3 real,
						cantidadgs real,									
                        iniciovigencia date,
                        idtvgs2 integer , 
			                    fijogs2 boolean, 
			                    gasto2 real, 
			                    idtvgs3 integer , 
			                    fijogs3 boolean, 
			                    gasto3 real, 
			                    idtvgs4 integer, 
			                    fijogs4 boolean, 
			                    gasto4 real,
			                    idtvgs5 integer, 
			                    fijogs5 boolean, 
			                    gasto5 real
                            
);
					
END IF;

--MaLaPi 05-05-2023 Verifico si solo se envio la asociaiocn, completo el convenio
/*
UPDATE asistencial_practicavalores SET apvidconvenio = t.idconvenio 
FROM (
    SELECT  max(idconvenio) as idconvenio ,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE acactivo AND (acfechafin >= current_date OR (acfechafin)is null)
				AND (cfinvigencia >= current_date OR (cfinvigencia)is null)
GROUP BY idasocconv
) as t
WHERE soloidasocconv = 'si' AND nullvalue(apvidconvenio) 
AND t.idasocconv = apidasocconv
AND nullvalue(apvprocesado)  AND nullvalue(apverror);

*/

OPEN alta FOR SELECT  DISTINCT idasocconv,count(*) 
             FROM asistencial_practicavalores
             JOIN asocconvenio ON asocconvenio.idconvenio = apvidconvenio AND (asocconvenio.idasocconv = apidasocconv OR /*nullvalue*/(apidasocconv)is null)
             WHERE /*nullvalue*/(apvprocesado)is null  AND /*nullvalue*/(apverror)is null
              AND ((idasocconv <> 89 AND idasocconv <> 95 AND idasocconv <> 92) --Saco NEUQUEN, RIO NEGRO y RIO NEGRO Y NEUQUEN 
                  OR soloidasocconv = 'si')
               
             GROUP BY idasocconv;
FETCH alta INTO elem;
RAISE NOTICE 'RAISE FACU TEST ELEM ===================== (%)', elem.idasocconv;
WHILE  found LOOP

RAISE NOTICE '_configura:: Voy a configurar elem.idasocconv (%) ',elem.idasocconv;

DELETE FROM temppractconvval;
--Cargo las practicas con valores fijos
INSERT INTO temppractconvval (idpractconvval,idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica,h1,cantidadh1,iniciovigencia, internacion)  (
             SELECT ROW_NUMBER () OVER (ORDER BY idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica) as idpractconvval
,idasocconv::bigint,idnomenclador,idcapitulo,idsubcapitulo,idpractica,max(apvvalorfijo)::float*apvcantunidades::float as h1,apvcantunidades::real as cantidadh1,min(apviniciovigencia::date) as apviniciovigencia
,apvinternacion
             FROM asistencial_practicavalores
             NATURAL JOIN practica
             JOIN asocconvenio ON asocconvenio.idconvenio = apvidconvenio
             WHERE /*nullvalue*/(apvprocesado)is null AND /*nullvalue*/(apverror)is null AND practica.activo
                   AND asocconvenio.idasocconv = elem.idasocconv
		   AND not /*nullvalue*/(asistencial_practicavalores.apvvalorfijo)is null
	     GROUP BY idasocconv::bigint,idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvcantunidades ,apvinternacion
);

--Cuando el valor es por unidad deben estar seteados los valores apvidtipounidadh1,apvidtipounidadh2,apvidtipounidadh3 o apvidtipounidadgs
INSERT INTO temppractconvval (idpractconvval,idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica,
							  fijoh1,h1,cantidadh1,
							  fijoh2,h2,cantidadh2,
							  fijoh3,h3,cantidadh3,
							  fijogs,gasto,cantidadgs
							  ,iniciovigencia
                                                          , internacion    ----- VAS 2024-11-19
)  (
            SELECT ROW_NUMBER () OVER (ORDER BY idasocconv,idnomenclador,idcapitulo,idsubcapitulo,idpractica) as idpractconvval
                 ,idasocconv::bigint,idnomenclador,idcapitulo,idsubcapitulo,idpractica
	         ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadh1)is null  THEN true ELSE false END as fijoh1
	         ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadh1)is null  THEN 0    ELSE apv.apvidtipounidadh1 END as h1
	         ,(CASE WHEN /*nullvalue*/(apv.apvcantunidadesh1)is null THEN 0.0  ELSE apv.apvcantunidadesh1 END)::real as cantidadh1
	 	 
                 ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadh2)is null  THEN true ELSE false END as fijoh2
	         ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadh2)is null  THEN 0    ELSE apv.apvidtipounidadh2 END as h1
	         ,(CASE WHEN /*nullvalue*/(apv.apvcantunidadesh2)is null THEN 0.0  ELSE apv.apvcantunidadesh2 END)::real as cantidadh2
	 	 
                 ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadh3)is null  THEN true ELSE false END as fijoh3
	         ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadh3)is null  THEN 0    ELSE apv.apvidtipounidadh3 END as h3
	         ,(CASE WHEN /*nullvalue*/(apv.apvcantunidadesh3)is null THEN 0.0  ELSE apv.apvcantunidadesh3 END)::real as cantidadh3
	         
                 ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadgs)is null  THEN true ELSE false END as fijogs
	         ,CASE WHEN /*nullvalue*/(apv.apvidtipounidadgs)is null  THEN 0    ELSE apv.apvidtipounidadgs END as gasto
	         ,(CASE WHEN /*nullvalue*/(apv.apvcantunidadesgs)is null THEN 0.0  ELSE apv.apvcantunidadesgs END)::real as cantidadgs
	         
                 ,min(apviniciovigencia::date) as apviniciovigencia
                ,apvinternacion ------ VAS 2024-11-19
             FROM asistencial_practicavalores as apv
             NATURAL JOIN practica
             JOIN asocconvenio ON asocconvenio.idconvenio = apvidconvenio AND (asocconvenio.idasocconv = apidasocconv OR /*nullvalue*/(apidasocconv)is null)
             WHERE /*nullvalue*/(apvprocesado)is null
                   AND asocconvenio.idasocconv = elem.idasocconv AND /*nullvalue*/(apverror)is null
                   AND practica.activo
                   AND /*nullvalue*/(apv.apvvalorfijo)is null    --Verifico que no este configurada como valor fijo
                   AND (not nullvalue(apv.apvidtipounidadh1) OR not nullvalue(apv.apvidtipounidadh2) 
				 OR not nullvalue(apv.apvidtipounidadh3) OR not nullvalue(apv.apvidtipounidadgs) )
	     GROUP BY idasocconv::bigint,idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvidtipounidadh1,apvcantunidadesh1
								  ,apvidtipounidadh2,apvcantunidadesh2,apvidtipounidadh3,apvcantunidadesh3,apvidtipounidadgs,apvcantunidadesgs
,apvinternacion -- VAS 19-11-2024
);

          SELECT INTO verificar count(*) as cant FROM temppractconvval;
          RAISE NOTICE '_configura:: Voy a llamar a ampractconvval con (%) elementos ',verificar.cant;

          --MaLapi 11-11-2022 Solo envio la configurar las configuraciones que son distintas a la actual

          --Llamo para que se carguen los valores
          SELECT INTO errores * FROM ampractconvval();

FETCH alta INTO elem;
END LOOP;
CLOSE alta;

UPDATE asistencial_practicavalores SET apvprocesado =  now(),apvidusuario=rusuario.idusuario WHERE /*nullvalue*/(apvprocesado)is null;

resultado = 'true';
RETURN resultado;
END;
$function$
