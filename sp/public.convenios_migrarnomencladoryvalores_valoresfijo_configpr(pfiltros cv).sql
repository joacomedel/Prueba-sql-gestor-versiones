CREATE OR REPLACE FUNCTION public.convenios_migrarnomencladoryvalores_valoresfijo_configpr(pfiltros character varying)
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
		--vidprestador BIGINT;
		--vidasocconv INTEGER;
		--vidconvenio INTEGER;
		vasocarray VARCHAR[];
BEGIN 

 UPDATE asistencial_practicavalores SET apvprocesado =  now() WHERE (apvprocesado)is null ;--Marco como procesado todo lo anterior

--nullvalue(apvprocesado);--Marco como procesado todo lo anterior

     vusuario = sys_dar_usuarioactual();
     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
	 	OPEN cvalores FOR
SELECT asoc_con_unidad.*,array_length(string_to_array(asociaciones_siges, '@'), 1)  as canti_asociacion,pdescripcion
							FROM (
						SELECT 
							sys_dar_numero(hon,0.0) as valorfijo
							,trim(asociaciones_siges) as asociaciones_siges
							,fechainiciovigencia
							,idnomencladorvalorfijoparamigrar
                                                        ,m.idnomenclador,m.idcapitulo,m.idsubcapitulo,m.idpractica
							FROM nomenclador_valorfijo_para_migrar as m
							WHERE /*nullvalue*/(nvfpmfechaproceso)is null AND trim(asociaciones_siges) <> ''
							) asoc_con_unidad
                                                        LEFT JOIN nomencladoruno USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
                                                        LEFT JOIN practica USING(idnomenclador,idcapitulo,idsubcapitulo,idpractica)
WHERE asoc_con_unidad.asociaciones_siges = rfiltros.asociaciones_siges
AND fechainiciovigencia = rfiltros.fechainiciovigencia
ORDER BY asociaciones_siges
;
	    FETCH cvalores INTO unvalor ;
		WHILE  found LOOP 
		  IF nullvalue(unvalor.pdescripcion) THEN 
                      UPDATE nomenclador_valorfijo_para_migrar SET nvfpmfechaproceso = now(), nvfpmerrordecarga = 'La practica no existe en el Nomenclador' WHERE idnomencladorvalorfijoparamigrar = unvalor.idnomencladorvalorfijoparamigrar; 
                      RAISE NOTICE 'La practica no existe en el nomenclador (%) ',concat(unvalor.idnomenclador,'.',unvalor.idcapitulo,'.',unvalor.idsubcapitulo,'.',unvalor.idpractica);
                  ELSE 

		  --Tengo que recorrrer las asociaciones
		  IF unvalor.valorfijo > 0 THEN 
		  vasocarray = string_to_array(unvalor.asociaciones_siges, '@');
		  FOR i IN 1..unvalor.canti_asociacion LOOP
				SELECT INTO rasocconv idconvenio,acdecripcion,acfechaini,acfechafin,idasocconv	 
				FROM asocconvenio 
				NATURAL JOIN convenio 
				WHERE idasocconv = vasocarray[i]::integer AND acactivo
					AND (acfechafin >= current_date OR /*nullvalue*/(acfechafin) is null )
					AND (cfinvigencia >= current_date OR /*nullvalue*/(cfinvigencia) is null)
					ORDER BY idasocconv,idconvenio DESC LIMIT 1; 
					IF NOT FOUND THEN 
					  -- No existe la asociacion a la que se necesita vincular, marcamos el error pero procesamos las otras
					  UPDATE nomenclador_valorfijo_para_migrar SET nvfpmfechaproceso = now(),nvfpmerrordecarga = concat(nvfpmerrordecarga,'/','ValoresFijo_::No existe la Asociacion',vasocarray[i])  WHERE idnomencladorvalorfijoparamigrar = unvalor.idnomencladorvalorfijoparamigrar;
					  RAISE NOTICE 'No existe la Asociacion (%) ',vasocarray[i];
					ELSE
					 --Verifico si el valor ya esta cargado, no lo vuelvo a cargar.
                                            SELECT INTO rverifica * 
                                            FROM practconvval 
                                            WHERE tvvigente AND --Cuando se cargan valores viejos esto hay que comentarlo
                                                                 (idasocconv,idcapitulo,idnomenclador,idpractica,idsubcapitulo,h1,pcvfechainicio) IN (
                                                                  SELECT rasocconv.idasocconv,unvalor.idcapitulo,unvalor.idnomenclador,unvalor.idpractica,unvalor.idsubcapitulo,unvalor.valorfijo,unvalor.fechainiciovigencia);
                                           IF NOT FOUND THEN
                                                          INSERT INTO asistencial_practicavalores(idnomenclador,idcapitulo,idsubcapitulo,idpractica,apvpdescripcion,apviniciovigencia
								,apvidconvenio,apvvalorfijo,apidasocconv,apvcantunidades
								) VALUES(unvalor.idnomenclador,unvalor.idcapitulo,unvalor.idsubcapitulo,unvalor.idpractica,unvalor.pdescripcion,unvalor.fechainiciovigencia
								,rasocconv.idconvenio,unvalor.valorfijo,rasocconv.idasocconv,1 
								);
                                           ELSE --No lo cargo... el valor ya existe
                                                UPDATE nomenclador_valorfijo_para_migrar SET nvfpmfechaproceso = now(),nvfpmerrordecarga = concat(nvfpmerrordecarga,'/','ValoresFijo_::El valor ya esta cargado',vasocarray[i])  WHERE idnomencladorvalorfijoparamigrar = unvalor.idnomencladorvalorfijoparamigrar;
                                           END IF; --Verifico que el valor no existe
					
                                  END IF; --Verifica la asociacion
				RAISE NOTICE 'Listo con (%) , vasocarray ',vasocarray[i];
		  END LOOP; --Para cada Asociacion
                  ELSE 
                    RAISE NOTICE 'El valor fijo para es cero (%) ',rfiltros.asociaciones_siges;
		  END IF; 
		  UPDATE nomenclador_valorfijo_para_migrar SET nvfpmfechaproceso = now() WHERE idnomencladorvalorfijoparamigrar = unvalor.idnomencladorvalorfijoparamigrar;
                END IF; --nullvalue(unvalor.pdescripcion) 
		fetch cvalores into unvalor; --Para cada Practica
		END LOOP;
		CLOSE cvalores;
        
		RAISE NOTICE 'Mando a Congiruar la practica (%)-(%)-<%>',now(),rfiltros.fechainiciovigencia,rfiltros.asociaciones_siges;
		PERFORM ampractconvval_configura();
     return 'Listo';
END;
$function$
