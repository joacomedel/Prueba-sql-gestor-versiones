CREATE OR REPLACE FUNCTION public.amtablavaloresv2_practconvval(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$--Ingresa o Actualiza la tabla de valores de un convenio
--SELECT amtablavaloresv2_practconvval('{idconvenio = 265}')
--Malapi 19-07-2023 modifico parametro de entrada para no lo uso... ahora se llama desde convenios_migrarnomencladoryvalores_valoresunida
--SELECT amtablavaloresv2_practconvval('{fechainiciovigencia = 2023-06-01}')
--Asociación de Clínicas Sanatorios y Hospitales Privados de la Provincia de Neuquén

DECLARE
	
	elem RECORD;
	rfiltros RECORD;
        alta refcursor; 
	resultado boolean;
        aux RECORD;
        vtipodato varchar;
		vcuantas integer;
	
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

DROP TABLE practconvval_valores_unidad;
CREATE TABLE practconvval_valores_unidad as (
select idnomenclador,idcapitulo,idsubcapitulo,idpractica,idasocconv,tvvigente,h1,h2,h3,gasto,fijoh1,fijoh2,fijoh3,fijogs,internacion,pcvfechainicio from practconvval as p 
where tvvigente 
AND not nullvalue(pcvfechainicio)
AND pcvfechamodifica >=  '2022-10-01'
AND idasocconv <> 89 AND idasocconv <> 92 
AND (not p.fijoh1 
     OR not p.fijoh2 
     OR not p.fijoh3 
OR not p.fijogs 
	 )
);

IF iftableexistsparasp('temp_modifica') THEN
   DELETE FROM temp_modifica;
   INSERT INTO temp_modifica (idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,tvinivigencia,idconvenio,tudescripcion,idasocconv
		,apvidtipounidadh1,pmcantidad1,apvidtipounidadh2,pmcantidad2,apvidtipounidadh3,pmcantidad3,apvidtipounidadgs,pmcantgastos)  (
	SELECT 	idnomenclador,idcapitulo,idsubcapitulo,idpractica
	,''::varchar as pdescripcion --No lo usa, no lo cargo
	,tv.tvinivigencia
	,ac.idconvenio
	,''::varchar as tudescripcion --No se usa, tampoco lo cargo
	,p.idasocconv::integer
	,CASE WHEN not p.fijoh1 AND p.h1 = tv.idtipounidad THEN tv.idtipounidad ELSE null END as apvidtipounidadh1,0 as pmcantidad1 --No se usan por eso no lo cargo 
	,CASE WHEN not p.fijoh2 AND p.h2 = tv.idtipounidad THEN tv.idtipounidad ELSE null END AS apvidtipounidadh2,0 as pmcantidad2
	,CASE WHEN not p.fijoh3 AND p.h3 = tv.idtipounidad THEN tv.idtipounidad ELSE null END AS apvidtipounidadh3,0 as pmcantidad3
	,CASE WHEN not p.fijogs AND p.gasto = tv.idtipounidad THEN tv.idtipounidad ELSE null END AS apvidtipounidadgs,0 as pmcantgastos
FROM "public"."practconvval_valores_unidad"  as p
JOIN asocconvenio as ac ON (p.idasocconv = ac.idasocconv)
NATURAL JOIN convenio as c
JOIN tablavalores tv ON (tv.idconvenio = c.idconvenio::bigint AND (p.h1 = tv.idtipounidad OR p.h2 = tv.idtipounidad OR p.h3 = tv.idtipounidad OR p.gasto = tv.idtipounidad))
NATURAL JOIN tipounidad
where 
(tv.tvinivigencia >= p.pcvfechainicio or nullvalue(p.pcvfechainicio))
AND tvinivigencia >= '2023-06-01'
AND (nullvalue(c.cfinvigencia) OR c.cfinvigencia > CURRENT_DATE)
	   AND (nullvalue(ac.acfechafin) OR ac.acfechafin > CURRENT_DATE)
	   AND (nullvalue(tv.tvfinvigencia) OR tv.tvfinvigencia > CURRENT_DATE)
);

   
   
ELSE
CREATE TEMP TABLE temp_modifica AS (
SELECT 	idnomenclador,idcapitulo,idsubcapitulo,idpractica
	,''::varchar as pdescripcion --No lo usa, no lo cargo
	,tv.tvinivigencia
	,ac.idconvenio
	,''::varchar as tudescripcion --No se usa, tampoco lo cargo
	,p.idasocconv::integer
	,CASE WHEN not p.fijoh1 AND p.h1 = tv.idtipounidad THEN tv.idtipounidad ELSE null END as apvidtipounidadh1,0 as pmcantidad1 --No se usan por eso no lo cargo 
	,CASE WHEN not p.fijoh2 AND p.h2 = tv.idtipounidad THEN tv.idtipounidad ELSE null END AS apvidtipounidadh2,0 as pmcantidad2
	,CASE WHEN not p.fijoh3 AND p.h3 = tv.idtipounidad THEN tv.idtipounidad ELSE null END AS apvidtipounidadh3,0 as pmcantidad3
	,CASE WHEN not p.fijogs AND p.gasto = tv.idtipounidad THEN tv.idtipounidad ELSE null END AS apvidtipounidadgs,0 as pmcantgastos
FROM "public"."practconvval_valores_unidad"  as p
JOIN asocconvenio as ac ON (p.idasocconv = ac.idasocconv)
NATURAL JOIN convenio as c
JOIN tablavalores tv ON (tv.idconvenio = c.idconvenio::bigint AND (p.h1 = tv.idtipounidad OR p.h2 = tv.idtipounidad OR p.h3 = tv.idtipounidad OR p.gasto = tv.idtipounidad))
NATURAL JOIN tipounidad
where 
(tv.tvinivigencia >= p.pcvfechainicio or nullvalue(p.pcvfechainicio))
AND tvinivigencia >= '2023-06-01'
AND (nullvalue(c.cfinvigencia) OR c.cfinvigencia > CURRENT_DATE)
	   AND (nullvalue(ac.acfechafin) OR ac.acfechafin > CURRENT_DATE)
	   AND (nullvalue(tv.tvfinvigencia) OR tv.tvfinvigencia > CURRENT_DATE)

);
END IF;

	UPDATE asistencial_practicavalores SET apvprocesado =  now() WHERE nullvalue(apvprocesado);--Marco como procesado todo lo anterior

/*OPEN alta FOR SELECT * FROM temptablavalores 
                       ORDER BY temptablavalores.idconvenio,
                             temptablavalores.idtipounidad;
FETCH alta INTO elem;
WHILE  found LOOP
*/


resultado = true;
SELECT INTO vcuantas COUNT(*) 
FROM (SELECT idasocconv,idconvenio,idnomenclador,idcapitulo,idsubcapitulo,idpractica
   	   FROM temp_modifica as t
	  GROUP BY idasocconv,idconvenio,idnomenclador,idcapitulo,idsubcapitulo,idpractica
	 ) as c;
RAISE NOTICE 'amtablavaloresv2_practconvval: Tengo que procesar (%)',vcuantas;


--Vinculo la Unidad con las practicas
					    /*vtipounidadh1 = obtenerunidadxcategoria(unvalor.tipounidadh1::varchar,rasocconv.idconvenio::integer,'A'::varchar);
						IF (vtipounidadh1 <> '') THEN EXECUTE sys_dar_filtros(vtipounidadh1) INTO rtipounidadh1; END IF;
						vtipounidaday1 = obtenerunidadxcategoria(unvalor.tipounidaday1::varchar,rasocconv.idconvenio::integer,'A'::varchar);
						vtipounidadgs = obtenerunidadxcategoria(unvalor.tipounidadgs::varchar,rasocconv.idconvenio::integer,'A'::varchar);
						IF (vtipounidaday1 <> '') THEN EXECUTE sys_dar_filtros(vtipounidaday1) INTO rtipounidaday1; ELSE rtipounidaday1 = rtipounidadh1; END IF;
						IF (vtipounidadgs <> '') THEN EXECUTE sys_dar_filtros(vtipounidadgs) INTO rtipounidadgs; ELSE rtipounidadgs = rtipounidadh1; END IF;*/
						
						IF vcuantas > 0 THEN 
						
							INSERT INTO asistencial_practicavalores(idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvpdescripcion,apviniciovigencia
									,apvidconvenio,apvdescunidad,apvvalorfijo,apidasocconv
									,apvidtipounidadh1,apvcantunidadesh1,apvidtipounidadh2,apvcantunidadesh2,apvidtipounidadh3,apvcantunidadesh3,apvidtipounidadgs,apvcantunidadesgs
									) 
									(SELECT idnomenclador,idcapitulo,idsubcapitulo,idpractica,text_concatenar(concat('<-',apvidtipounidadh1,'-',apvidtipounidadh2,'-',apvidtipounidadh3,'-',apvidtipounidadgs,'->')) as pdescripcion ,max(tvinivigencia) as tvinivigencia
										,idconvenio,text_concatenar(tudescripcion) as tudescripcion,null,idasocconv
										,max(apvidtipounidadh1) as apvidtipounidadh1,max(pmcantidad1) as pmcantidad1
										,max(apvidtipounidadh2) as apvidtipounidadh2,max(pmcantidad2) as pmcantidad2
										,max(apvidtipounidadh3) as apvidtipounidadh3,max(pmcantidad3) as pmcantidad3
										,max(apvidtipounidadgs) as apvidtipounidadgs,max(pmcantgastos) as pmcantgastos
									FROM temp_modifica
									GROUP BY idasocconv,idconvenio,idnomenclador,idcapitulo,idsubcapitulo,idpractica);
							RAISE NOTICE 'Mando a Congiruar la practica (%)',now();
							PERFORM ampractconvval_configura();
							RAISE NOTICE 'Listo se Cargo';
					END IF;

RETURN resultado;

END;
$function$
