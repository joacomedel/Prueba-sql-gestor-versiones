CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_vincularasociacion_configpr(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
        cvalores refcursor;
        unvalor record;
        rfiltros RECORD;
	rasocconv RECORD;
	rverifica RECORD;
	ranexovalor RECORD;  
        vusuario INTEGER;
	vtipounidadh1 VARCHAR;
        vidconvenio INTEGER;
        vtudescripcion VARCHAR;
	vtipounidaday1 VARCHAR;
	vtipounidadgs VARCHAR;
	rtipounidadh1 RECORD;
	rtipounidaday1 RECORD;
	rtipounidadgs RECORD;
	vasocarray VARCHAR[];
BEGIN 

     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     
     --Vinculo la Unidad con las practicas
     UPDATE asistencial_practicavalores SET apvprocesado =  now() 
     WHERE nullvalue(apvprocesado);--Marco como procesado todo lo anterior
     -- vas 22102024 las cantidades las voy a sacar del aplicanomenclador si aplica la configuracion del nomenclador sino la saco de la tabla correspondiente a la planilla
     OPEN cvalores FOR SELECT DISTINCT  array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion
                         ,asoc_con_unidad.*
                          ,pmhonorario1
                       --  ,pmcantidad1
                         ,pmhonorario2
                      --   ,case when nullvalue(tipounidaday1) then 0 else  pmcantidad2 end as pmcantidad2
                         ,pmhonorario3
                     --    ,case when nullvalue(tipounidaday1) then 0 else pmcantidad3 end pmcantidad3
                         ,pmgastos
                      --   ,pmcantgastos
                         ,dequemanera
-- VAS 15112024  evaluo si debo tomar las cantidades de las unidades del nomenclador o de la planilla
                         ,CASE WHEN( not sys_dar_boolean(aplicanomenclador,false) ) THEN sys_dar_numero(hon  ,'0.0') -- aplica planilla
                               ELSE pmcantidad1 -- aplica nomenclador
                          END as pmcantidad1 

                          ,CASE WHEN( not sys_dar_boolean(aplicanomenclador,false) ) THEN  sys_dar_numero(ayud_1 ,'0.0') -- aplica planilla
                               ELSE pmcantidad2	-- aplica nomenclador
                          END as pmcantidad2	 

                          ,CASE WHEN( not sys_dar_boolean(aplicanomenclador,false) ) THEN sys_dar_numero(ayud_2 ,'0.0') -- aplica planilla
                               ELSE  pmcantidad3  -- aplica nomenclador
                          END as pmcantidad3
                         ,CASE WHEN( not sys_dar_boolean(aplicanomenclador,false) ) THEN sys_dar_numero(gastos	,'0.0') 
 -- aplica planilla
                               ELSE pmcantgastos  -- aplica nomenclador
                          END as pmcantgastos
     
                  	-- VAS 15112024
		       FROM  (
                                SELECT DISTINCT aplicanomenclador,n.idnomencladorparamigrar,n.idnomenclador,n.idcapitulo,n.idsubcapitulo,n.idpractica
                                     ,trim(upper(tipounidadh1)) as tipounidadh1,  sys_dar_numero(valordeunidadh1,'0.0') as valordeunidadh1
                                     ,trim(upper(tipounidaday1)) as tipounidaday1,sys_dar_numero(valordeunidaday1,'0.0') as valordeunidaday1
                                     ,trim(upper(tipounidadgs)) as tipounidadgs,  sys_dar_numero(valordeunidadgs,'0.0') as valordeunidadgs
                                     ,m.asociaciones_siges,idnomencladormapeaasociacion,n.pdescripcion,npmfechainiciovigencia,'contablamapeohonorario' as dequemanera
                                    ,  sys_dar_boolean(parainternacion,false) as internacion  -- VAS 22-10-2024
, hon,	ayud_1,	ayud_2,	gastos	-- VAS 15112024 incorporo la cantidad de honorarios/ayudant1/ayudante2/gastos para que se pueda evaluar si se toman de la planilla o de la configuracion del nomenclador
				FROM nomenclador_mapea_asociacion_para_migrar as m
				JOIN nomenclador_para_migrar as n USING(idnomencladorparamigrar)
				WHERE tipounidadh1 <> ''  AND nullvalue(nmafechaproceso)
					
                                UNION 
					
                                SELECT aplicanomenclador,n.idnomencladorparamigrar,n.idnomenclador,n.idcapitulo,n.idsubcapitulo,n.idpractica
                                     ,trim(upper(tipounidadh1)) as tipounidadh1,  sys_dar_numero(valordeunidadh1,'0.0') as valordeunidadh1
                                     ,trim(upper(tipounidaday1)) as tipounidaday1,sys_dar_numero(valordeunidaday1,'0.0') as                                      valordeunidaday1
                                     ,trim(upper(tipounidadgs)) as tipounidadgs,  sys_dar_numero(valordeunidadgs,'0.0') as valordeunidadgs
                                     ,m.asociaciones_siges,idnomencladormapeaasociacion,n.pdescripcion,npmfechainiciovigencia,'contablamapeogasto' as dequemanera 
                                    ,  sys_dar_boolean(parainternacion,false) as internacion  -- VAS 22-10-2024
, hon,	ayud_1,	ayud_2,	gastos	-- VAS 15112024 incorporo la cantidad de honorarios/ayudant1/ayudante2/gastos para que se pueda evaluar si se toman de la planilla o de la configuracion del nomenclador
				FROM nomenclador_mapea_asociacion_para_migrar as m
				JOIN nomenclador_para_migrar as n ON (n.idnomencladorparamigrar = m.idnomencladorparamigrargasto)
				WHERE tipounidadh1 <> '' AND not nullvalue(idnomencladorgasto) 
                                              AND nullvalue(nmafechaprocesogasto)
						
                                UNION

                                SELECT DISTINCT aplicanomenclador,n.idnomencladorparamigrar,n.idnomenclador,n.idcapitulo,n.idsubcapitulo,n.idpractica
                                     ,trim(upper(tipounidadh1)) as tipounidadh1,sys_dar_numero(valordeunidadh1,'0.0') as valordeunidadh1
                                     ,trim(upper(tipounidaday1)) as tipounidaday1,sys_dar_numero(valordeunidaday1,'0.0') as                                      valordeunidaday1
                                     ,trim(upper(tipounidadgs)) as tipounidadgs,sys_dar_numero(valordeunidadgs,'0.0') as valordeunidadgs
                                     ,CASE WHEN nullvalue(n.asociaciones_siges) THEN asociaciones_sigesgastos ELSE asociaciones_siges END ,0 as idnomencladormapeaasociacion,n.pdescripcion,npmfechainiciovigencia,'sintablamapeo' as dequemanera	
                                    ,  sys_dar_boolean(parainternacion,false) as internacion  -- VAS 22-10-2024	  
, hon,	ayud_1,	ayud_2,	gastos	-- VAS 15112024 incorporo la cantidad de honorarios/ayudant1/ayudante2/gastos para que se pueda evaluar si se toman de la planilla o de la configuracion del nomenclador                      
                                 FROM nomenclador_para_migrar as n 
				 WHERE (tipounidadh1 <> '' OR tipounidaday1 <> '' OR tipounidadgs <> '' ) 
                                              AND nullvalue(npmfechacargavalorunidad)
                                              AND (not nullvalue(asociaciones_siges) 
                                                    OR not nullvalue(asociaciones_sigesgastos))

                        ) asoc_con_unidad
			NATURAL JOIN nomencladoruno
                        WHERE asociaciones_siges = rfiltros.asociaciones_siges 
                          	AND asoc_con_unidad.dequemanera = rfiltros.dequemanera
								;
	 
	   FETCH cvalores INTO unvalor ;
	   WHILE  found LOOP 
		  --Tengo que recorrrer las asociaciones
		  vasocarray = string_to_array(unvalor.asociaciones_siges, '@');
		  FOR i IN 1..unvalor.canti_asociacion LOOP
				SELECT INTO rasocconv idconvenio,acdecripcion,acfechaini,acfechafin,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE idasocconv = vasocarray[i]::integer AND acactivo
					AND (acfechafin >= current_date OR nullvalue(acfechafin))
					AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
					ORDER BY idasocconv,idconvenio DESC LIMIT 1; 
				IF NOT FOUND THEN 
					  -- No existe la asociacion a la que se necesita vincular, marcamos el error pero procesamos las otras
					  UPDATE nomenclador_mapea_asociacion_para_migrar SET nmaerrordecarga = concat(nmaerrordecarga,'/','No existe la Asociacion',vasocarray[i]) WHERE idnomencladormapeaasociacion = unvalor.idnomencladormapeaasociacion;
					  RAISE NOTICE 'No existe la Asociacion (%) ',vasocarray[i];
				ELSE
					   --Vinculo la Unidad con las practicas
                                            -- HONORARIO
					    vtipounidadh1 = obtenerunidadxcategoria(unvalor.tipounidadh1::varchar,rasocconv.idconvenio::integer,'A'::varchar);
					    IF (vtipounidadh1 <> '') THEN 
                                                     EXECUTE sys_dar_filtros(vtipounidadh1) INTO rtipounidadh1; 
                                                     vidconvenio = rtipounidadh1.idconvenio; 
                                                     vtudescripcion = rtipounidadh1.tudescripcion; 
                                            END IF;

					    -- AYUDANTE 1
					    vtipounidaday1 = obtenerunidadxcategoria(unvalor.tipounidaday1::varchar,rasocconv.idconvenio::integer,'A'::varchar);

--MaLaPi 07-03-2-23 Lo comento... si no se carga la unidad en la columna indicada, no se pasa ese honorario				
                                            IF (vtipounidaday1 <> '') THEN 
                                                     EXECUTE sys_dar_filtros(vtipounidaday1) INTO rtipounidaday1;  
                                            ELSE --- si no se configuro ayudante 1 se asume que tiene la misma configuracion que el honorario
                                                     rtipounidaday1 = rtipounidadh1; 
                                            END IF;

--MaLaPi 07-03-2-23 Lo comento... si no se carga la unidad en la columna indicada, no se pasa ese honorario	

                                            -- GASTO
					    vtipounidadgs = obtenerunidadxcategoria(unvalor.tipounidadgs::varchar,rasocconv.idconvenio::integer,'A'::varchar);			
					    IF (vtipounidadgs <> '') THEN 
                                                     EXECUTE sys_dar_filtros(vtipounidadgs) INTO rtipounidadgs; 
                                                     vidconvenio = rtipounidadgs.idconvenio; 
                                                     vtudescripcion = rtipounidadgs.tudescripcion;
                                                     IF (vtipounidadh1 = '') THEN -- si no configuro honorario se asume que tiene las mismas caracteristica que los gastos
                                                             rtipounidadh1 = rtipounidadgs;
                                                             rtipounidaday1 = rtipounidadgs;
                                                     END IF;
                                            ELSE 
                                               rtipounidadgs = rtipounidadh1;

                                            END IF;

--pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos
RAISE NOTICE 'Un valor (%) unvalor.pmcantidad1 (%) unvalor.pmcantidad2 (%) unvalor.pmcantgastos (%)',unvalor,unvalor.pmcantidad1,unvalor.pmcantidad2,unvalor.pmcantgastos;
RAISE NOTICE 'CASE WHEN unvalor.pmcantidad1 = 0 THEN null ELSE rtipounidadh1.idtipounidad END  (%)',CASE WHEN unvalor.pmcantidad1 = 0 THEN null ELSE rtipounidadh1.idtipounidad END;
					  INSERT INTO asistencial_practicavalores( idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvpdescripcion,apviniciovigencia,apvidconvenio,apvdescunidad,apvvalorfijo,apidasocconv
								,apvidtipounidadh1,apvcantunidadesh1,
								apvidtipounidadh2,apvcantunidadesh2,
								apvidtipounidadh3,apvcantunidadesh3,
								apvidtipounidadgs,apvcantunidadesgs
,apvinternacion

					) VALUES( unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica,unvalor.pdescripcion,unvalor.npmfechainiciovigencia
								,vidconvenio,vtudescripcion,null,rasocconv.idasocconv
								,CASE WHEN unvalor.pmcantidad1 = 0 THEN null ELSE rtipounidadh1.idtipounidad END,unvalor.pmcantidad1
								,CASE WHEN unvalor.pmcantidad2 = 0 THEN null ELSE rtipounidaday1.idtipounidad END,unvalor.pmcantidad2
								,CASE WHEN unvalor.pmcantidad3 = 0 THEN null ELSE rtipounidaday1.idtipounidad END,unvalor.pmcantidad3
								,CASE WHEN unvalor.pmcantgastos = 0 THEN null ELSE rtipounidadgs.idtipounidad END,unvalor.pmcantgastos
								,unvalor.internacion);
					RAISE NOTICE 'Voy a ejecutar ampractconvval_verifica con (%) ',unvalor;
								
					UPDATE nomenclador_para_migrar SET npmfechacargavalorunidad = now(),fechaproceso = now(),npmtextoexito = concat(npmtextoexito,'/',rasocconv.idasocconv) 
					WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar 
						AND unvalor.dequemanera ilike 'sintablamapeo%'
						AND concat(idnomenclador,idcapitulo,idsubcapitulo,idpractica) =concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
								
					UPDATE nomenclador_mapea_asociacion_para_migrar SET nmafechaproceso = now(),nmatextoexito = concat(nmatextoexito,'/',rasocconv.idasocconv) 
					WHERE idnomencladormapeaasociacion = unvalor.idnomencladormapeaasociacion 
						AND unvalor.dequemanera ilike 'contablamapeo%'
						AND concat(idnomenclador,idcapitulo,idsubcapitulo,idpractica) =concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);

					UPDATE nomenclador_mapea_asociacion_para_migrar SET nmafechaprocesogasto = now(),nmatextoexito = concat(nmatextoexito,'/',rasocconv.idasocconv) 
					WHERE idnomencladormapeaasociacion = unvalor.idnomencladormapeaasociacion 
						AND unvalor.dequemanera ilike 'contablamapeo%'
						AND concat(idnomencladorgasto,idcapitulogasto,idsubcapitulogasto,idpracticagasto) =concat(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica);
								
								
					RAISE NOTICE 'Listo se Cargo (%) ',unvalor;
				END IF; --Verifica la asociacion
				RAISE NOTICE 'Listo con (%) , vasocarray ',vasocarray[i];
		  END LOOP; --Para cada Asociacion
		fetch cvalores into unvalor; --Para cada Practica
		END LOOP;
		CLOSE cvalores;
		RAISE NOTICE 'Mando a Congiruar la practica (%)',now();
		PERFORM ampractconvval_configura();
		 
     return 'Listo';
END;
$function$
