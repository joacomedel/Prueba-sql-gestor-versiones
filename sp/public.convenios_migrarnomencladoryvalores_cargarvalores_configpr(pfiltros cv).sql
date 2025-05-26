CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_cargarvalores_configpr(pfiltros character varying)
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
		
		vasocarray VARCHAR[];
BEGIN 

     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     --Vinculo la Unidad con las practicas
	 UPDATE asistencial_practicavalores SET apvprocesado =  now() WHERE nullvalue(apvprocesado);--Marco como procesado todo lo anterior
		
	 	OPEN cvalores FOR SELECT DISTINCT  array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion
                         ,valorfijo::double precision,asociaciones_siges::varchar
,idnomencladorparamigrar::bigint,idnomencladormapeaasociacion::bigint,idnomenclador,idcapitulo,idsubcapitulo,idpractica,pdescripcion,npmfechainiciovigencia::date
                         ,pmhonorario1,pmcantidad1,pmhonorario2,pmcantidad2,pmhonorario3,pmcantidad3,pmgastos,pmcantgastos
						 FROM  (
							SELECT GREATEST(hon,ayud_1,ayud_2,gastos) as valorfijo
							,asociaciones_siges			
							,idnomencladorparamigrar,idnomenclador,idcapitulo,idsubcapitulo,idpractica
							,idnomencladormapeaasociacion,pdescripcion,npmfechainiciovigencia
							FROM (
							/*SELECT DISTINCT 
							sys_dar_numero(hon,0.0) as hon
							,sys_dar_numero(ayud_1,0.0) as ayud_1
							,sys_dar_numero(ayud_2,0.0) as ayud_2
							,sys_dar_numero(gastos,0.0) as gastos
							,m.asociaciones_siges			
							,n.idnomencladorparamigrar,n.idnomenclador,n.idcapitulo,n.idsubcapitulo,n.idpractica
							,idnomencladormapeaasociacion,n.pdescripcion,npmfechainiciovigencia
							FROM nomenclador_mapea_asociacion_para_migrar as m
							JOIN nomenclador_para_migrar as n USING(idnomencladorparamigrar)
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'
							UNION
							SELECT DISTINCT 
							sys_dar_numero(hon,0.0) as hon
							,sys_dar_numero(ayud_1,0.0) as ayud_1
							,sys_dar_numero(ayud_2,0.0) as ayud_2
							,sys_dar_numero(gastos,0.0) as gastos
							,m.asociaciones_siges			
							,n.idnomencladorparamigrar,n.idnomenclador,n.idcapitulo,n.idsubcapitulo,n.idpractica
							,idnomencladormapeaasociacion,n.pdescripcion,npmfechainiciovigencia  
							FROM nomenclador_mapea_asociacion_para_migrar as m
							JOIN nomenclador_para_migrar as n ON (n.idnomencladorparamigrar = m.idnomencladorparamigrargasto)
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'
                                                        UNION*/
                                                        SELECT DISTINCT 
							sys_dar_numero(hon,0.0) as hon
							,sys_dar_numero(ayud_1,0.0) as ayud_1
							,sys_dar_numero(ayud_2,0.0) as ayud_2
							,sys_dar_numero(gastos,0.0) as gastos
							,n.asociaciones_siges			
							,n.idnomencladorparamigrar,n.idnomenclador,n.idcapitulo,n.idsubcapitulo,n.idpractica
							,0 as idnomencladormapeaasociacion,n.pdescripcion,npmfechainiciovigencia  
							FROM nomenclador_para_migrar as n 
							WHERE (tipounidadh1 = ''  OR nullvalue(tipounidadh1) AND (tipounidadgs = '' OR nullvalue(tipounidadgs)))  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'

							) as t
							) asoc_con_unidad
							NATURAL JOIN nomencladoruno
							WHERE trim(asociaciones_siges) = rfiltros.asociaciones_siges
								;
	 
	   FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
		  --Tengo que recorrrer las asociaciones
		  
		  vasocarray = string_to_array(unvalor.asociaciones_siges, '@');
		  RAISE NOTICE 'Listo con (%) , vasocarray ',unvalor.canti_asociacion;
		  FOR i IN 1..unvalor.canti_asociacion LOOP
		  RAISE NOTICE 'Valor Fijo:: La Asociacion (%) ',vasocarray[i];
				SELECT INTO rasocconv idconvenio,acdecripcion,acfechaini,acfechafin,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE idasocconv = vasocarray[i]::integer AND acactivo
					AND (acfechafin >= current_date OR nullvalue(acfechafin))
					AND (cfinvigencia >= current_date OR nullvalue(cfinvigencia))
					ORDER BY idasocconv,idconvenio DESC LIMIT 1; 
					
					IF NOT FOUND THEN 
					  -- No existe la asociacion a la que se necesita vincular, marcamos el error pero procesamos las otras
					  UPDATE nomenclador_mapea_asociacion_para_migrar SET nmaerrordecarga = concat(nmaerrordecarga,'/','Valor Fijo:: No existe la Asociacion',vasocarray[i]) WHERE idnomencladormapeaasociacion = unvalor.idnomencladormapeaasociacion;
					  RAISE NOTICE 'Valor Fijo:: No existe la Asociacion (%) ',vasocarray[i];
					ELSE
					  		INSERT INTO asistencial_practicavalores(idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvpdescripcion,apviniciovigencia
								,apvidconvenio,apvvalorfijo,apidasocconv,apvcantunidades
								) VALUES(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica,unvalor.pdescripcion,unvalor.npmfechainiciovigencia
								,rasocconv.idconvenio,unvalor.valorfijo,rasocconv.idasocconv,1 
								);
								UPDATE nomenclador_para_migrar SET npmfechacargavalorfijo = now(),npmtextoexito = concat(npmtextoexito,'/',rasocconv.idasocconv) WHERE idnomencladorparamigrar = unvalor.idnomencladorparamigrar;
								RAISE NOTICE 'Listo se Cargo (%) ',unvalor.idnomencladorparamigrar;
					END IF; --Verifica la asociacion
				RAISE NOTICE 'Listo con (%) , vasocarray ',vasocarray[i];
		  END LOOP; --Para cada Asociacion
               
		fetch cvalores into unvalor; --Para cada Practica
		END LOOP;
		CLOSE cvalores;
 UPDATE nomenclador_para_migrar SET npmfechacargavalorfijo = now() WHERE idnomencladorparamigrar
                                          IN (SELECT DISTINCT idnomencladorparamigrar
							FROM (
							SELECT DISTINCT 
							m.asociaciones_siges			
							,n.idnomencladorparamigrar
							FROM nomenclador_mapea_asociacion_para_migrar as m
							JOIN nomenclador_para_migrar as n USING(idnomencladorparamigrar)
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'
							UNION
							SELECT DISTINCT 
							m.asociaciones_siges			
							,n.idnomencladorparamigrar
							FROM nomenclador_mapea_asociacion_para_migrar as m
							JOIN nomenclador_para_migrar as n ON (n.idnomencladorparamigrar = m.idnomencladorparamigrargasto)
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'
UNION
                                                        SELECT DISTINCT 
							
 						         n.asociaciones_siges			
							,n.idnomencladorparamigrar
							FROM nomenclador_para_migrar as n 
							WHERE tipounidadh1 = ''  AND nullvalue(npmfechacargavalorfijo)
							AND trim(activo) ilike 'SI'

							) asoc_con_unidad
							WHERE trim(asociaciones_siges) = trim(rfiltros.asociaciones_siges)
								); 


		RAISE NOTICE 'Mando a Congiruar la practica (%)',now();
		PERFORM ampractconvval_configura();
		 
     return 'Listo';
END;
$function$
